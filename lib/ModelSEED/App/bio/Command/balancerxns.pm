package ModelSEED::App::bio::Command::balancerxns;
use strict;
use common::sense;
use ModelSEED::App::bio;
use base 'ModelSEED::App::BioBaseCommand';
use Class::Autouse qw(
    ModelSEED::MS::Factories::ExchangeFormatFactory
);
use ModelSEED::utilities qw( config error args verbose set_verbose translateArrayOptions);
sub abstract { return "Balance all the reactions in a biochemistry"; }
sub usage_desc { return "bio balancerxns [ biochemistry id ]"; }
sub options {
    return (
    	["namespace|n:s", "Default name space for biochemistry"],
    	["water|w", "Balance with water if possible"],
		["protons|p", "Do not balance protons (default is to balance protons)"]
   	);
}
sub sub_execute {
    my ($self, $opts, $args,$bio) = @_;
    if (!defined($opts->{namespace})) {
	$opts->{namespace} = "ModelSEED";
    }
    $bio->defaultNameSpace($opts->{namespace});

    #default is to balance protons, so switch is used to turn this off
    if($opts->{proton}){
	$opts->{proton}=0;
    }else{
	$opts->{protons}=1;
    }

    foreach my $rxn (@{$bio->reactions()}){
	my $results=$rxn->checkReactionMassChargeBalance({rebalanceProtons=>$opts->{protons},rebalanceWater=>$opts->{water}});
    }
    $self->save_bio($bio);
}

1;
