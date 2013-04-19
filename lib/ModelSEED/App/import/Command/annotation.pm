package ModelSEED::App::import::Command::annotation;
use strict;
use common::sense;
use ModelSEED::App::import;
use base 'ModelSEED::App::ImportBaseCommand';
use ModelSEED::utilities qw( config error args verbose set_verbose translateArrayOptions);
use Class::Autouse qw(
    ModelSEED::MS::Factories::Annotation
);
sub abstract { return "Import annotation from the SEED or RAST" }
sub usage_desc { return "ms import annotation [SEED/RAST id] [genome id] [options]" }
sub description { return <<END;
An annotated genome may be imported from the SEED or RAST annotation
service.  To see a list of available models use the --list flag. 
For a tab-delimited list of genome ids and names add
the --verbose flag:

    \$ ms import annotation --list 
    \$ ms import annotation --list --verbose

You may restrict your search to a specific source with the --source flag.
This also works when importing by a given ID. The current available sources are:

    "PubSEED" (pubseed.theseed.org) - The Public SEED
    "RAST" (rast.nmpdr.org) - Note that listing is currently not available with this.
    "KBASE" (kbase.us) - Systems Biology Knowledgebase

To import an annotated genome, supply the genome's ID, the alias that
you would like to save it to and a mapping object to use:
    
    \$ ms import annotation 83333.1 ecoli -m main

If no mapping is supplied, the default mapping will be used:

    \$ ms defaults mapping
END
}
sub options {
    return (
    	["list|l",    "List available annotated genomes"],
        ["source:s", "Restrict search to a specific data source"],
        ["filepath|f:s", "Directory with flatfiles of data you are importing"],
        ["mapping|m:s", "Select the preferred mapping object to use when importing the annotation"],
	);
}
sub sub_execute {
    my ($self, $opts, $args) = @_;
    if(defined($opts->{list})) {
        $self->printList($opts);
        return;
    }
    my ($id, $alias) = @$args;
    $self->usage_error("Must supply an id") unless(defined($id));
    $self->usage_error("Must supply an alias") unless(defined($alias));
    my $sources = [ $opts->{source} ];
    $sources = [ qw(PubSEED RAST KBase) ] unless(@$sources);
    my $map;
    if(defined($opts->{mapping})) {
    	$map = $self->get_object({
	    	type => "Mapping",
	    	reference => $opts->{mapping}
	    });
    } else {
   		$map = $self->store()->defaultMapping();
   	}
   	# Importing annotation from table file
    my $anno;
    verbose("Getting annotation...");
    if (defined($opts->{filepath})) {
    	my $factory = ModelSEED::MS::Factories::TableFileFactory->new({
    		filepath => $opts->{filepath},
            namespace => "SEED",
    	});
    	$anno = $factory->createAnnotation({
    		mapping => $map,
    		genome => $id
    	})
    } else {
    	my $config = {
    		genome_id => $id,
    		mapping => $map
    	};
    	my $factory = ModelSEED::MS::Factories::Annotation->new(om => $self->store()->objectManager());
	    my $sources = [ $opts->{source} ];
	    $sources = [ qw(PubSEED RAST KBase) ] unless(@$sources);
	    $anno = $factory->build($config);
    }
    $map = $anno->mapping;
	$self->save_object({
    	type => "Mapping",
    	reference => "Mapping/".$map->uuid(),
    	object => $map
    });
	$anno->mapping_uuid($map->uuid());
    $self->save_object({
    	object => $anno,
    	type => "Annotation",
    	reference => $alias
    });
}

sub printList {
    my ($self, $opts) = @_;
    my $factory = ModelSEED::MS::Factories::Annotation->new(om => $self->store()->objectManager());
    my $sources = [ $opts->{source} ];
    $sources = [ qw(PUBSEED KBase) ] unless $sources->[0];
    foreach my $source (@$sources) {
        my $genomeHash = $factory->availableGenomes({source => $source});
        if($opts->{verbose}) {
            my @strings = map { "$_\t" . $genomeHash->{$_} } keys %$genomeHash;
            print join( "\n", @strings) . "\n";
        } else {
            print join("\n", keys %$genomeHash) . "\n";
        }
    }
}

1;
