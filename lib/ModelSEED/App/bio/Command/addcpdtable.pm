package ModelSEED::App::bio::Command::addcpdtable;
use base 'App::Cmd::Command';
use Class::Autouse qw(
    ModelSEED::Store
    ModelSEED::Auth::Factory
    ModelSEED::App::Helpers
);
sub abstract { return "Reads in table of compound data and adds them to the database" }
sub usage_desc { return "bio addcpdtable [< biochemistry | biochemistry] [filename] [options]"; }
sub opt_spec {
    return (
        ["saveas|a:s", "New alias for altered biochemistry"],
        ["namespace|n:s", "Name space for aliases added"],
    );
}

sub execute {
    my ($self, $opts, $args) = @_;
    my $auth  = ModelSEED::Auth::Factory->new->from_config;
    my $store = ModelSEED::Store->new(auth => $auth);
    my $helper = ModelSEED::App::Helpers->new();
    my ($biochemistry,my $ref) = $helper->get_object("biochemistry", $args, $store);
    $self->usage_error("Must specify an biochemistry to use") unless(defined($biochemistry));
    $self->usage_error("Must specify a valid filename for compound table") unless(defined($args->[1]) && -e $args->[1]);
    my $tbl = ModelSEED::utilities::LOADTABLE($args->[1],"\\t");
    if (!defined($opts->{namespace})) {
    	$opts->{namespace} = $biochemistry->defaultNameSpace();
    } 
    for (my $i=0; $i < @{$tbl->{data}}; $i++) {
    	my $cpdData = {aliasType => $opts->{namespace}};
    	for (my $j=0; $j < @{$tbl->{headings}}; $j++) {
    		my $heading = $tbl->{headings}->[$j];
    		if ($heading eq "names") {
    			$cpdData->{$heading} = [split(/\|/,$tbl->{data}->[$i]->[$j])];
    		} else {
    			$cpdData->{$heading} = [$tbl->{data}->[$i]->[$j]];
    		}
    	}
    	my $cpd = $biochemistry->addCompoundFromHash($cpdData);
    	if (defined($cpd)) {
    		push(@{$tbl->{data}->[$i]},$cpd->uuid());
    	}
    }
    push(@{$tbl->{headings}},"uuid");
    if (defined($opts->{saveas})) {
    	$ref = $helper->process_ref_string($opts->{saveas}, "biochemistry", $auth->username);
    	print STDERR "Saving biochemistry with new compounds as ".$ref."...\n" if($opts->{verbose});
		$store->save_object($ref,$biochemistry);
    } else {
    	print STDERR "Saving over original biochemistry with new compounds...\n" if($opts->{verbose});
    	$store->save_object($ref,$biochemistry);
    }
    ModelSEED::utilities::PRINTTABLE("STDOUT",$tbl);
}

1;
