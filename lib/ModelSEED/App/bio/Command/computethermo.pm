package ModelSEED::App::bio::Command::computethermo;
use strict;
use common::sense;
use base 'App::Cmd::Command';
use ModelSEED::utilities;
use Class::Autouse qw(
    ModelSEED::Store
    ModelSEED::Auth::Factory
    ModelSEED::App::Helpers
);
sub abstract { return "Balance all the reactions in a biochemistry"; }
sub usage_desc { return "bio balancerxns [name]"; }
sub opt_spec {
    return (
    	["verbose|v", "Print comments on command actions"],
	["direction|d", "Update directionality to match computed thermoReversibility (default value: 1)",]
   	);
}

sub execute {
    my ($self, $opts, $args) = @_;

    ModelSEED::utilities::set_verbose(1) if $opts->{verbose};
    
    my $auth  = ModelSEED::Auth::Factory->new->from_config;
    my $store = ModelSEED::Store->new(auth => $auth);
    my $helper = ModelSEED::App::Helpers->new();
    $self->usage_error("Must specify a name for the object to be created") unless(defined($args->[0]));
    my ($biochemistry,$ref) = $helper->get_object("biochemistry", $args, $store);
    $self->usage_error("Biochemistry ".$args->[0]." not found") unless defined($biochemistry);
    
    my $args={direction=>1};

    if(defined($opts->{direction})){
	$args->{direction}=$opts->{direction};
    }

    foreach my $rxn (@{$biochemistry->reactions()}){
	$rxn->checkReactionCueBalance();
	$rxn->calculateEnergyofReaction();
	$rxn->estimateThermoReversibility($args);
    }
    $store->save_object($ref,$biochemistry);
}

1;
