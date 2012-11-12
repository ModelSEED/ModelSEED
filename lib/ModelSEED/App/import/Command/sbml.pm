package ModelSEED::App::import::Command::sbml;
use strict;
use common::sense;
use base 'App::Cmd::Command';
use ModelSEED::utilities qw( args verbose set_verbose );
use Class::Autouse qw(
    ModelSEED::Store
    ModelSEED::Auth::Factory
    ModelSEED::MS::Factories::SBMLFactory
    ModelSEED::Database::Composite
    ModelSEED::Reference
    ModelSEED::App::Helpers
);

sub abstract { return "Import model and biochemistry from SBML"; }

sub usage_desc { return "ms import sbml [filename] [alias]"; }
sub description { return <<END;
Imports a biochemistry and model from an SBML file
END
}

sub opt_spec {
    return (
        ["namespace|n:s", "Namespace for IDs in SBML file"],
        ["verbose|v", "Print detailed output of import status"],
        ["dry|d", "Perform a dry run; that is, do everything but saving"],
        ["help|h|?", "Print this usage information"],
    );
}

sub execute {
    my ($self, $opts, $args) = @_;
    my $auth  = ModelSEED::Auth::Factory->new->from_config;
    my $store = ModelSEED::Store->new(auth => $auth);
    my $helper = ModelSEED::App::Helpers->new();
    my $factory = ModelSEED::MS::Factories::SBMLFactory->new({
    	auth => $auth,
    	store => $store
    });
    if ($opts->{help}) {
    	print($self->usage);
    	return;
    }
    $self->usage_error("Filename of SBML file not specified!") unless(defined($args->[0]));
	$self->usage_error("SBML file not found!") unless (-e $args->[0]);
	$self->usage_error("Alias for new model and biochemistry not specified!") unless(defined($args->[1]));
    my $filename = $args->[0];
    my $alias = $args->[1];
	my $input = {
		filename => $filename,
		verbose => 0
	};
	if (defined($opts->{namespace})) {
		$input->{namespace} = $opts->{namespace};
	}
	(my $biochemistry,my $model,my $anno,my $mapping) = $factory->parseSBML($input);
	unless($opts->{dry}) {
        if (defined($model) && defined($anno) && defined($mapping) && defined($biochemistry)) {
        	my $ref = $helper->process_ref_string($alias, "model", $auth->username);
        	$store->save_object($ref, $model);
        	verbose("Saved model to ".$ref."!");
       		$ref = $helper->process_ref_string($alias, "annotation", $auth->username);
        	$store->save_object($ref, $anno);
        	verbose("Saved mapping to ".$ref."!");
        	$ref = $helper->process_ref_string($alias, "mapping", $auth->username);
        	$store->save_object($ref, $mapping);
        	verbose("Saved mapping to ".$ref."!");
        	$ref = $helper->process_ref_string($alias, "biochemistry", $auth->username);
        	$store->save_object($ref, $biochemistry);
        	verbose("Saved biochemistry to ".$ref."!");
        }
    }
}

1;
