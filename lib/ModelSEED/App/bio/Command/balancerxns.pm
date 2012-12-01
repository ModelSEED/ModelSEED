package ModelSEED::App::bio::Command::balancerxns;
use strict;
use common::sense;
use base 'App::Cmd::Command';
use Class::Autouse qw(
    ModelSEED::Store
    ModelSEED::Auth::Factory
    ModelSEED::App::Helpers
);
sub abstract { return "Balance all the reactions in a biochemistry"; }
sub usage_desc { return "bio balancerxns [name]"; }
sub opt_spec {
    return (
    	["namespace|n:s", "Default name space for biochemistry"],
    	["verbose|v", "Print comments on command actions"]
   	);
}

sub execute {
	my ($self, $opts, $args) = @_;
	my $auth  = ModelSEED::Auth::Factory->new->from_config;
	my $store = ModelSEED::Store->new(auth => $auth);
	my $helper = ModelSEED::App::Helpers->new();
	$self->usage_error("Must specify a name for the object to be created") unless(defined($args->[0]));
	if (!defined($opts->{namespace})) {
		$opts->{namespace} = "ModelSEED";
	}

	my ($biochemistry,$ref) = $helper->get_object("biochemistry", $args, $store);
	$self->usage_error("Biochemistry ".$args->[0]." not found") unless defined($biochemistry);
	print "Using: ",$biochemistry->name(),"\n";


	print $opts->{namespace}."\n";


	$biochemistry->defaultNameSpace($opts->{namespace});

	foreach my $rxn (@{$biochemistry->reactions()}){
#	    print $rxn->id()."\t".$rxn->equation()."\t".$rxn->equationFormula()."\n";
	    $rxn->checkReactionMassChargeBalance();
	}
	$store->save_object($ref,$biochemistry);
}

1;
