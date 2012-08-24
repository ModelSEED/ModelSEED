package ModelSEED::App::bio::Command::addrxn;
use base 'App::Cmd::Command';
use Class::Autouse qw(
    ModelSEED::Store
    ModelSEED::Auth::Factory
    ModelSEED::App::Helpers
);
sub abstract { return "Adds a single reaction to the database from input arguments" }
sub usage_desc { return "bio addrxn [< biochemistry | biochemistry] [id] [equation]"; }
sub opt_spec {
    return (
        ["names|n:s", "Abbreviation"],
        ["abbreviation|b:s", "Molecular formula"],
        ["enzymes|z:s", "Associated EC number"],
        ["direction|d:s", "Default directionality for reaction"],
        ["deltag|g:s", "Gibbs free energy (kcal/mol)"],
        ["deltagerr|e:s", "Uncertainty in Gibbs energy"],
        ["saveas|a:s", "New alias for altered biochemistry"],
        ["namespace|n:s", "Namespace under which IDs will be added"],
    );
}

sub execute {
    my ($self, $opts, $args) = @_;
    my $auth  = ModelSEED::Auth::Factory->new->from_config;
    my $store = ModelSEED::Store->new(auth => $auth);
    my $helper = ModelSEED::App::Helpers->new();
    my ($biochemistry,my $ref) = $helper->get_object("biochemistry", $args, $store);
    $self->usage_error("Must specify an biochemistry to use") unless(defined($biochemistry));
    $self->usage_error("Must specify an id for the reaction") unless(defined($args->[1]));
    $self->usage_error("Must specify an equation for the reaction") unless(defined($args->[2]));
    my $rxnData = {
    	id => [$args->[1]],
    	equation => [$args->[2]]
    };
   	if (defined($opts->{names})) {
    	$rxnData->{names} = [split(/\|/,$opts->{names})];
    }
    if (defined($opts->{enzymes})) {
    	$rxnData->{enzymes} = [split(/\|/,$opts->{enzymes})];
    }
    if (!defined($opts->{namespace})) {
    	$opts->{namespace} = $biochemistry->defaultNameSpace();
    }
    my $headings = ["abbreviation","direction","deltag","deltagerr"];
    foreach my $heading (@{$headings}) {
    	if (defined($opts->{$heading})) {
    		$rxnData->{$heading} = [$opts->{$heading}];
    	}
    }
    $rxnData->{aliasType} = $opts->{namespace};
    my $rxn = $biochemistry->addReactionFromHash($rxnData);
    if (defined($rxn)) {
    	print "Reaction added with UUID:".$rxn->uuid()."\n";
    }
    if (defined($opts->{saveas})) {
    	$ref = $helper->process_ref_string($opts->{saveas}, "biochemistry", $auth->username);
    	print STDERR "Saving biochemistry with new compounds as ".$ref."...\n" if($opts->{verbose});
		$store->save_object($ref,$biochemistry);
    } else {
    	print STDERR "Saving over original biochemistry with new compounds...\n" if($opts->{verbose});
    	$store->save_object($ref,$biochemistry);
    }
}

1;