package ModelSEED::App::bio::Command::computethermo;
use strict;
use common::sense;
use ModelSEED::App::bio;
use base 'ModelSEED::App::BioBaseCommand';
use ModelSEED::utilities;
sub abstract { return "Balance all the reactions in a biochemistry"; }
sub usage_desc { return "bio balancerxns [name]"; }
sub opt_spec {
    return (
	["direction|d", "Update directionality to match computed thermoReversibility (default value: 1)",]
   	);
}

sub sub_execute {
    my ($self, $opts, $args, $bio) = @_;

    ModelSEED::utilities::set_verbose(1) if $opts->{verbose};
    
    my $args={direction=>1};
    if(defined($opts->{direction})){
	$args->{direction}=$opts->{direction};
    }

    foreach my $rxn (@{$bio->reactions()}){
	$rxn->checkReactionCueBalance();
	$rxn->calculateEnergyofReaction();
	$rxn->estimateThermoReversibility($args);
    }
    $self->save_bio($bio);
}

1;
