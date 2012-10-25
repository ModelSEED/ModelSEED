package ModelSEED::App::bio::Command::transferrxn;
use strict;
use common::sense;
use base 'App::Cmd::Command';
use ModelSEED::utilities qw( verbose set_verbose );
use Class::Autouse qw(
    ModelSEED::Store
    ModelSEED::Auth::Factory
    ModelSEED::App::Helpers
);
sub abstract { return "Transfer the reactions from the first specified compound to the second in the biochemistry database" }
sub usage_desc { return "bio transferrxn [< biochemistry | biochemistry] [starting compound] [receiving compound] [namespace]"; }
sub opt_spec {
    return (
    	["verbose|v", "Print messages with progress"],
        ["saveas|a:s", "Save results as new biochemistry"],
        ["saveover|s", "Save results as original biochemistry"],
    );
}

sub execute {
    my ($self, $opts, $args) = @_;

    #verbosity
    set_verbose(1) if $opts->{verbose};

    if (!defined($opts->{saveas}) && !defined($opts->{saveover})){
	verbose("Neither the saveas or saveover options were used\nThis run will therefore be a dry run and the biochemistry will not be saved\n");
    }

    my $auth  = ModelSEED::Auth::Factory->new->from_config;
    my $store = ModelSEED::Store->new(auth => $auth);
    my $helper = ModelSEED::App::Helpers->new();

    my ($biochemistry, $ref) = $helper->get_object("biochemistry", $args, $store);
    $self->usage_error("Must specify biochemistry to use") unless(defined($biochemistry));
    my ($tmp_bio, $tmp_ref) = $helper->get_object("biochemistry", $args, $store);

    $self->usage_error("Must specify ID of first compound") unless(defined($args->[1]));
    my $cpdOne = $biochemistry->getObjectByAlias("compounds",$args->[1],$args->[3]);
    $self->usage_error("Compound ".$args->[1]." not found in namespace ".$args->[3]."!") unless(defined($cpdOne));

    $self->usage_error("Must specify ID of second compound") unless(defined($args->[2]));
    my $cpdTwo = $biochemistry->getObjectByAlias("compounds",$args->[2],$args->[3]);
    $self->usage_error("Compound ".$args->[2]." not found in namespace ".$args->[3]."!") unless(defined($cpdTwo));

    $self->usage_error("Must specific namespace of the IDs for the compounds/reactions") unless defined($args->[3]);
    $biochemistry->defaultNameSpace($args->[3]);
    $tmp_bio->defaultNameSpace($args->[3]);

    my $reactionsToTransfer = $biochemistry->findReactionsWithReagent($cpdOne->uuid());
    verbose("Copying ".scalar(@$reactionsToTransfer)." reactions and switching ".$args->[1]." to ".$args->[2]."\n");

    foreach my $rxn (@$reactionsToTransfer){
	my $tmp_rxn=$rxn->cloneObject();
	$tmp_rxn->parent($tmp_bio);

	#replace reagent
	foreach my $rgt (@{$tmp_rxn->reagents()}){
	    $rgt->compound_uuid($cpdTwo->uuid()) if $rgt->compound_uuid() eq $cpdOne->uuid();
	}

	if($tmp_rxn->checkForDuplicateReagents()){
	    verbose("Reaction ".$rxn->id()." rejected because compound switch leads to duplicates in the same compartment\n");
	    next;
	}elsif($biochemistry->checkForDuplicateReaction($tmp_rxn)){
	    verbose("Reaction ".$rxn->id()." rejected because new reaction already exists\n");
	    next;
	}

	verbose("Adding new version of ".$rxn->id()." with ".$args->[2]."\n");
	$biochemistry->add('reactions',$tmp_rxn);
	foreach my $set ( grep { $_->attribute() eq 'reactions' } @{$biochemistry->aliasSets()} ){
	    if($rxn->getAlias($set->name())){
		my $tmp_alias=$rxn->getAlias($set->name());
		if($set->name() eq $args->[3]){
		    $tmp_alias.="_".$cpdOne->getAlias($set->name());
		}
		$biochemistry->addAlias({attribute=>'reactions',aliasName=>$set->name(),alias=>$tmp_alias,uuid=>$tmp_rxn->uuid()});
	    }
	}
    }

    if (defined($opts->{saveas})) {
    	my $new_ref = $helper->process_ref_string($opts->{saveas}, "biochemistry", $auth->username);
    	verbose("Saving biochemistry with transferred reactions as ".$new_ref."...\n");
	$store->save_object($new_ref,$biochemistry);
    }elsif (defined($opts->{saveover})) {
    	verbose("Saving over original biochemistry with transferred reactions...\n");
	$store->save_object($ref,$biochemistry);
    }
}
1;
