package ModelSEED::App::bio::Command::create;
use base 'App::Cmd::Command';
use Class::Autouse qw(
    ModelSEED::Store
    ModelSEED::Auth::Factory
    ModelSEED::App::Helpers
);
sub abstract { return "Creates an empty biochemistry"; }
sub usage_desc { return "bio create [name]"; }
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
	my $object = ModelSEED::MS::Biochemistry->new({
		defaultNameSpace => $opts->{namespace},
		name => $args->[0]
	});
    $ref = $helper->process_ref_string($args->[0], "biochemistry", $auth->username);
    print STDERR "Created biochemistry with name ".$ref."...\n" if($opts->{verbose});
	$store->save_object($ref,$object);
}

1;
