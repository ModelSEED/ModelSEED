package ModelSEED::App::import::Command::modelfile;
use strict;
use common::sense;
use ModelSEED::App::import;
use base 'ModelSEED::App::ImportBaseCommand';
use ModelSEED::utilities qw( config error args verbose set_verbose translateArrayOptions);
use Cwd qw(getcwd);
use Class::Autouse qw(
    ModelSEED::MS::Factories::TableFileFactory
);
sub abstract { return "Import an existing model from file"; }
sub usage_desc { return "ms import modelfile [file id] [model id] [biochemistry] [options]"; }
sub description { return "Imports model from file"; }
sub options {
    return (
    	["filepath|f:s", "Directory with flatfiles of data you are importing"],
        ["namespace|n:s", "Name space of database (default is 'ModelSEED')"],
        ["annotation|a:s", "Annotation to use when importing the model"],
	);
}
sub sub_execute {
    my ($self, $opts, $args) = @_;
    $self->usage_error("Must specify ID of model to be imported") unless(defined($args->[0]));
    $self->usage_error("Must specify alias for imported model") unless(defined($args->[1]));
    $self->usage_error("Must specify biochemistry to be used for import") unless(defined($args->[2]));
    my $bio = $self->get_object({
   		type => "Biochemistry",
   		reference => $args->[2]
   	});
    my $config = {
    	id => $args->[0],
    	biochemistry => $bio
    };
    #Retrieving annotation object
    my $annoref;
    if(defined($opts->{annotation})) {
    	my $anno = $self->get_object({
	   		type => "Annotation",
	   		reference => $args->[2]
	   	});
    	$config->{annotation} = $anno;
    }
	#Building model object from file
	if (!defined($opts->{namespace})) {
		$opts->{namespace} = "ModelSEED";
	}
	if (!defined($opts->{filepath})) {
		$opts->{filepath} = getcwd;
	}
	my $factory = ModelSEED::MS::Factories::TableFileFactory->new({
		filepath => $opts->{filepath},
		namespace => $opts->{namespace},
	});
	my $model = $factory->createModel($config);
	#Saving model in database
    $self->save_object({
    	object => $model,
    	type => "Model",
    	reference => $args->[1]
    });
}

1;