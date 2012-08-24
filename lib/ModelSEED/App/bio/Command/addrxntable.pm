package ModelSEED::App::bio::Command::addrxntable;
use base 'App::Cmd::Command';
use Class::Autouse qw(
    ModelSEED::Store
    ModelSEED::Auth::Factory
    ModelSEED::App::Helpers
);
sub abstract { return "Reads in table of reaction data and adds them to the database" }
sub usage_desc { return "bio addrxntable [< biochemistry | biochemistry] [filename] [options]"; }
sub opt_spec {
    return (
        ["saveas|a:s", "New alias for altered biochemistry"],
        ["namespace|n:s", "Name space for aliases added"],
        ["autoadd|a","Automatically add any missing compounds to DB"]
    );
}

sub execute {
    my ($self, $opts, $args) = @_;
    my $auth  = ModelSEED::Auth::Factory->new->from_config;
    my $store = ModelSEED::Store->new(auth => $auth);
    my $helper = ModelSEED::App::Helpers->new();
    my ($biochemistry,my $ref) = $helper->get_object("biochemistry", $args, $store);
    $self->usage_error("Must specify an biochemistry to use") unless(defined($biochemistry));
    $self->usage_error("Must specify a valid filename for reaction table") unless(defined($args->[1]) && -e $args->[1]);
    my $tbl = ModelSEED::utilities::LOADTABLE($args->[1],"\\t");
    if (!defined($opts->{namespace})) {
    	$opts->{namespace} = $biochemistry->defaultNameSpace();
    } 
    for (my $i=0; $i < @{$tbl->{data}}; $i++) {
    	my $rxnData = {aliasType => $opts->{namespace}};
    	for (my $j=0; $j < @{$tbl->{headings}}; $j++) {
    		my $heading = $tbl->{headings}->[$j];
    		if ($heading eq "names" || $heading eq "enzymes") {
    			$rxnData->{$heading} = [split(/\|/,$tbl->{data}->[$i]->[$j])];
    		} else {
    			$rxnData->{$heading} = [$tbl->{data}->[$i]->[$j]];
    		}
    	}
    	my $rxn = $biochemistry->addReactionFromHash($rxnData);
    	if (defined($rxn)) {
    		push(@{$tbl->{data}->[$i]},$rxn->uuid());
    	}
    }
    push(@{$tbl->{headings}},"uuid");
    if (defined($opts->{saveas})) {
    	$ref = $helper->process_ref_string($opts->{save}, "biochemistry", $auth->username);
    	print STDERR "Saving biochemistry with new reactions as ".$ref."...\n" if($opts->{verbose});
		$store->save_object($ref,$biochemistry);
    } else {
    	print STDERR "Saving over original biochemistry with new reactions...\n" if($opts->{verbose});
    	$store->save_object($ref,$biochemistry);
    }
    ModelSEED::utilities::PRINTTABLE("STDOUT",$tbl);
}

1;
