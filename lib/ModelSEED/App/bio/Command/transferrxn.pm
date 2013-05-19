package ModelSEED::App::bio::Command::transferrxn;
use strict;
use common::sense;
use ModelSEED::App::bio;
use base 'ModelSEED::App::BioBaseCommand';
use Class::Autouse qw(
    ModelSEED::MS::Factories::ExchangeFormatFactory
    ModelSEED::MS::Model
);
use ModelSEED::utilities;
sub abstract { return "Transfer the reactions from the first specified compound to the second in the biochemistry database" }
sub usage_desc { return "bio transferrxn [ biochemistry id ] [starting compound] [receiving compound] [namespace]"; }
sub options {
    return ();
}
sub sub_execute {
    my ($self, $opts, $args,$bio) = @_;
    $self->usage_error("Must specify ID of first compound") unless(defined($args->[0]));
    my $cpdOne = $bio->getObjectByAlias("compounds",$args->[0],$args->[2]);
    $self->usage_error("Compound ".$args->[0]." not found in namespace ".$args->[2]."!") unless(defined($cpdOne));

    $self->usage_error("Must specify ID of second compound") unless(defined($args->[1]));
    my $cpdTwo = $bio->getObjectByAlias("compounds",$args->[1],$args->[2]);
    $self->usage_error("Compound ".$args->[1]." not found in namespace ".$args->[2]."!") unless(defined($cpdTwo));

    $self->usage_error("Must specific namespace of the IDs for the compounds/reactions") unless defined($args->[2]);
    $bio->defaultNameSpace($args->[2]);

    my $reactionsToTransfer = $bio->findReactionsWithReagent($cpdOne->uuid());
    verbose("Copying ".scalar(@$reactionsToTransfer)." reactions and switching ".$args->[0]." to ".$args->[1]."\n");

    foreach my $rxn (@$reactionsToTransfer){
	my $tmp_rxn=$rxn->cloneObject();
	$tmp_rxn->parent($bio);

	#replace reagent
	foreach my $rgt (@{$tmp_rxn->reagents()}){
	    $rgt->compound_uuid($cpdTwo->uuid()) if $rgt->compound_uuid() eq $cpdOne->uuid();
	}

	if($tmp_rxn->checkForDuplicateReagents()){
	    verbose("Reaction ".$rxn->id()." rejected because compound switch leads to duplicates in the same compartment\n");
	    next;
	}elsif($bio->checkForDuplicateReaction($tmp_rxn)){
	    verbose("Reaction ".$rxn->id()." rejected because new reaction already exists\n");
	    next;
	}

	verbose("Adding new version of ".$rxn->id()." with ".$args->[1]."\n");
	$bio->add('reactions',$tmp_rxn);
	foreach my $set ( grep { $_->attribute() eq 'reactions' } @{$bio->aliasSets()} ){
	    if($rxn->getAlias($set->name())){
		my $tmp_alias=$rxn->getAlias($set->name());
		if($set->name() eq $args->[2]){
		    $tmp_alias.="_".$cpdOne->getAlias($set->name())."x".$cpdTwo->getAlias($set->name());
		}
		$bio->addAlias({attribute=>'reactions',aliasName=>$set->name(),alias=>$tmp_alias,uuid=>$tmp_rxn->uuid()});
	    }
	}
    }
    $self->save_bio($bio);
}
1;
