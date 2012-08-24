package ModelSEED::App::mseed::Command::whoami;
use base 'App::Cmd::Command';
use Class::Autouse qw(
    ModelSEED::Auth::Factory
);
sub opt_spec { return (
        ["help|h|?", "Print this usage information"],
    );
}

sub abstract { return "Return the currently logged in user" }
sub execute {
    my ($self, $opts, $args) = @_;
    print($self->usage) && exit if $opts->{help};
    my $auth = ModelSEED::Auth::Factory->new->from_config;
    print $auth->username . "\n"
}


1;
