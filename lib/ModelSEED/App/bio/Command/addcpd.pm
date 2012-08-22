package ModelSEED::App::bio::Command::addcpd;
use base 'App::Cmd::Command';
use Class::Autouse qw(
    ModelSEED::Store
    ModelSEED::Auth::Factory
    ModelSEED::App::Helpers
);
sub abstract { return "Adds a single compound to the database from input arguments" }
sub usage_desc { return "bio addcpd [< biochemistry | biochemistry] [id] [name]"; }
sub opt_spec {
    return (
        ["abbreviation|a:s", "Abbreviation"],
        ["formula|f:s", "Molecular formula"],
        ["mass|m:s", "Molecular weight"],
        ["charge|c:s", "Molecular charge"],
        ["deltag|g:s", "Gibbs free energy (kcal/mol)"],
        ["deltagerr|e:s", "Uncertainty in Gibbs energy"],
        ["altnames:s", "Alternative names"],
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
    $self->usage_error("Must specify an id for the compound") unless(defined($args->[1]));
    $self->usage_error("Must specify a primary name for the compound") unless(defined($args->[2]));
    my $cpdData = {
    	id => [$args->[1]],
    	names => [$args->[2]]
    };
    if (defined($opts->{altnames})) {
    	push(@{$cpdData->{names}},split(/\|/,$opts->{altnames}));
    }
    if (!defined($opts->{namespace})) {
    	$opts->{namespace} = $biochemistry->defaultNameSpace();
    }
    my $headings = ["formula","mass","deltaG","deltaGErr","abbreviation","charge"];
    foreach my $heading (@{$headings}) {
    	if (defined($opts->{$heading})) {
    		$cpdData->{$heading} = [$opts->{$heading}];
    	}
    }
    $cpdData->{aliasType} = $opts->{namespace};
    my $cpd = $biochemistry->addCompoundFromHash($cpdData);
    if (defined($opts->{saveas})) {
    	$ref = $helper->process_ref_string($opts->{save}, "biochemistry", $auth->username);
    	print STDERR "Saving biochemistry with new compounds as ".$ref."...\n" if($opts->{verbose});
		$store->save_object($ref,$biochemistry);
    } else {
    	print STDERR "Saving over original biochemistry with new compounds...\n" if($opts->{verbose});
    	$store->save_object($ref,$biochemistry);
    }
    ModelSEED::utilities::PRINTTABLE("STDOUT",$tbl);
}

1;
