package ModelSEED::App::import::Command::modelfile;
use strict;
use common::sense;
use base 'App::Cmd::Command';
use Cwd;
use ModelSEED::utilities qw( args verbose set_verbose translateArrayOptions);
use Class::Autouse qw(
    ModelSEED::Store
    ModelSEED::Auth::Factory
    ModelSEED::MS::Factories::TableFileFactory
    ModelSEED::Database::Composite
    ModelSEED::Reference
    ModelSEED::App::Helpers
);

sub abstract { return "Import an existing model from file"; }

sub usage_desc { return "ms import model [id] [alias] [biochemistry] [options]"; }
sub description { return "Imports model from file"; }

sub opt_spec {
    return (
		["filepath|f:s", "Directory with flatfiles of data you are importing"],
        ["namespace|n:s", "Name space of database (default is 'ModelSEED')"],
        ["annotation|a:s", "Annotation to use when importing the model"],
        ["store|s:s", "Identify which store to save the model to"],
        ["verbose|v", "Print detailed output of import status"],
        ["dry|d", "Perform a dry run; that is, do everything but saving"],
        ["help|h|?", "Print this usage information"],
    );
}

sub execute {
    my ($self, $opts, $args) = @_;
    print($self->usage) && return if $opts->{help};
    my $auth = ModelSEED::Auth::Factory->new->from_config();
    my $helpers = ModelSEED::App::Helpers->new;
    $self->usage_error("Must specify ID of model to be imported") unless(defined($args->[0]));
    $self->usage_error("Must specify alias for imported model") unless(defined($args->[1]));
    $self->usage_error("Must specify biochemistry to be used for import") unless(defined($args->[2]));
    if (defined($opts->{verbose}) && $opts->{verbose} == 1) {
    	set_verbose(1);
    }
    # Initialize the store object
    my $store;
    if($opts->{store}) {
        my $store_name = $opts->{store};
        my $ms = ModelSEED::Configuration->new();
        my $config = $ms->config();
        my $store_config;
        foreach my $store (${$config->{stores}}) {
        	if ($store->{name} eq $store_name) {
        		$store_config = $store;
        	}
        }
        die "No such store: $store_name" unless(defined($store_config));
        my $db = ModelSEED::Database::Composite->new(databases => [ $store_config ]);
        $store = ModelSEED::Store->new(auth => $auth, database => $db);
    } else {
        $store = ModelSEED::Store->new(auth => $auth);
    }
    #Retrieving biochemistry object
    my $bioref = $helpers->process_ref_string($args->[2], "biochemistry", $auth->username);
    my $bio = $store->get_object($bioref);
    my $modelref = $helpers->process_ref_string($args->[1], "model", $auth->username);
    my $config = {
    	id => $args->[0],
    	biochemistry => $bio
    };
    #Retrieving annotation object
    if(defined($opts->{annotation})) {
    	my $annoref = $helpers->process_ref_string($opts->{annotation}, "annotation",$auth->username);
    	$config->{annotation} = $store->get_object($annoref);
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
    unless($opts->{dry}) {
        $store->save_object($modelref, $model);
        verbose("Saved model to $modelref!");
    }
}

1;
