package ModelSEED::App::import::Command::model;
use strict;
use common::sense;
use ModelSEED::App::import;
use base 'ModelSEED::App::ImportBaseCommand';
use ModelSEED::utilities;
use File::Temp qw(tempfile);
use IO::Uncompress::Gunzip qw(gunzip $GunzipError);
use LWP::Simple;
use JSON::XS;
use Class::Autouse qw(
    ModelSEED::MS::Factories::FBAMODELFactory
    ModelSEED::MS::Factories::PPOFactory
);
sub abstract { return "Import an existing model"; }
sub usage_desc { return "ms import model [import id] [model id] [genome id] [options]"; }
sub description { return <<END;
Models may be imported from the local database or from an existing
model on the ModelSeed website. To see a list of available models
for the given source use the --list flag:

    \$ ms import model --list model-seed
    \$ ms import model --list local

To import a model, supply the model's ID, the alias that you
would like to save it to and an annotation object to use:

    \$ ms import model 83333.1 sdevoid/ecoli -a sdevoid/ecoli

If you would like to import a model from the local source, set
[ --source local ].

    \$ ms import model 83333.1 sdevoid/ecoli --source local -a sdevoid/ecoli

END
}
sub options {
    return (
    	["list|l", "List models that are available to import from a source"], 
        ["source:s", "Source to import from, default is 'model-seed'"]
	);
}
sub sub_execute {
    my ($self, $opts, $args) = @_;
    my ($id,$modelid,$genome) = @$args;
    $self->usage_error("Must supply an ID of model to import") unless(defined($id));
    $self->usage_error("Must supply an ID for model to be saved") unless(defined($modelid));
    $self->usage_error("Must supply an ID of genome to be associated") unless(defined($genome));
    # Set source to 'model-seed' if it isn't defined
    $opts->{source} = 'model-seed' unless defined $opts->{source};
    my ($factory);
    if($opts->{source} eq 'model-seed') {
        $factory = ModelSEED::MS::Factories::FBAMODELFactory->new(
            store => $self->store()
        );
    } else {
        die "Unknown source: " . $opts->{source} . "\n" .
        "Available sources: 'model-seed'\n";
    }
    # If we just want the list, print and exit
    if($opts->{list} && $opts->{source} eq 'model-seed') {
        my $ids = $factory->listAvailableModels();
        print join("\n", @$ids);
        print "\n" if(@$ids);
        return;
    }
    my $anno = $self->get_object({
   		type => "Annotation",
   		reference => $genome
   	});
    my $model = $factory->createModel({ 
    	id => $id,
    	annotation => $anno,
    });
    $self->save_object({
    	object => $model,
    	type => "Model",
    	reference => $modelid
    });
}

1;
