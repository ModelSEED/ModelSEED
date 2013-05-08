package ModelSEED::App::import::Command::mapping;
use strict;
use common::sense;
use ModelSEED::App::import;
use base 'ModelSEED::App::ImportBaseCommand';
use ModelSEED::utilities qw( config error args verbose set_verbose translateArrayOptions);
use File::Temp qw(tempfile);
use IO::Uncompress::Gunzip qw(gunzip $GunzipError);
use LWP::Simple;
use JSON::XS;
use Class::Autouse qw(
    ModelSEED::MS::Mapping
    ModelSEED::MS::Factories::PPOFactory
);
sub abstract { return "Import mapping from local or remote database"; }
sub usage_desc { return "ms import mapping [mapping id] [options]"; }
sub description { return <<END;
Import mapping data (roles, complexes, etc.)
Alias, required, is the name that you would like to save the mapping as.

You may supply a biochemistry with -b to use when importing the mapping
objct. If this is not supplied, the default biochemistry, i.e.
\$ ms defaults bichemistry
will be used.
    
The [--filepath path] argument indicates where you are importing
the mapping from. Current supported options are:
    
    --filepath path : path with flat files of mapping data 

END
}
sub options {
    return (
    	["biochemistry|b:s", "Reference to biochemistry to use for import"],
        ["filepath|f:s", "Directory with flatfiles of data you are importing"],
        ["namespace|n:s", "Name space of database (default is 'ModelSEED')"],
	);
}
sub sub_execute {
    my ($self, $opts, $args) = @_;
    my ($alias) = @$args;
    $self->usage_error("Must supply an alias") unless(defined($alias));
    my $biochemistry;
    if(defined($opts->{biochemistry})) {
    	$biochemistry = $self->get_object({
	    	type => "Biochemistry",
	    	reference => $opts->{biochemistry}
	    });
    } else {
   		$biochemistry = $self->store()->defaultBiochemistry();
   	}
    my $map;
    if (!defined($opts->{namespace})) {
    	$opts->{namespace} = "ModelSEED";
    }
	if($opts->{filepath}) {
        my $factory = ModelSEED::MS::Factories::TableFileFactory->new({
             filepath => $opts->{filepath},
             namespace => $opts->{namespace},
        });
		$map = $factory->createMapping({
			name => $alias,
			biochemistry => $biochemistry,
			verbose => $opts->{verbose},
        });
    } else {
        # Just fetch a pre-built mapping from the web
        my $url = "http://bioseed.mcs.anl.gov/~chenry/exampleObjects/defaultMap.json.gz";
        my $data;
        {
            my ($fh1, $compressed_filename) = tempfile();
            my ($fh2, $uncompressed_filename) = tempfile();
            close($fh1);
            close($fh2);
            verbose "Fetching mapping from web...\n";
            my $status = getstore($url, $compressed_filename);
            # This should probably be >= 200 <= 400? does getstore handle redirects?
            die "Unable to fetch from model_seed\n" unless($status == 200);
            verbose "Extracting...\n";
            gunzip $compressed_filename => $uncompressed_filename
                or die "Extract failed: $GunzipError\n";
            my $string;
            {
                local $/;
                open(my $fh, "<", $uncompressed_filename) || die "$!: $@";
                $string = <$fh>;
            }
            $data = JSON::XS->new->utf8->decode($string);
        }
        verbose "Validating fetched mapping...\n";
        $map = ModelSEED::MS::Mapping->new($data);
        $map->biochemistry_uuid($biochemistry->uuid);
        $map->biochemistry($biochemistry);
    }
    $self->save_object({
    	object => $map,
    	type => "Mapping",
    	reference => $alias
    });
}

1;
