package ModelSEED::App::bio::Command::validate;
use base 'App::Cmd::Command';
use Class::Autouse qw(
    ModelSEED::Store
    ModelSEED::Auth::Factory
    ModelSEED::App::Helpers
);
sub abstract { return "Validates the biochemistry data searching for inconsistencies" }
sub usage_desc { return "bio validate [< biochemistry | biochemistry] [options]"; }
sub opt_spec {
    return (
        ["help|h|?", "Print this usage information"],
    );
}

sub execute {
    my ($self, $opts, $args) = @_;
    print($self->usage) && exit if $opts->{help};
    my $auth  = ModelSEED::Auth::Factory->new->from_config;
    my $store = ModelSEED::Store->new(auth => $auth);
    my $helper = ModelSEED::App::Helpers->new();
    my ($biochemistry,my $ref) = $helper->get_object("biochemistry", $args, $store);
    $self->usage_error("Must specify an biochemistry to use") unless(defined($biochemistry));
    my $errors = $biochemistry->validate();
    if (@{$errors} == 0) {
    	print "Biochemistry validation complete. No errors found!";
    } else {
    	print "Biochemistry validation complete. ".@{$errors}." errors found:\n".join("\n",@{$errors});
    }
}

1;
