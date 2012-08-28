package ModelSEED::App::mseed::Command::logout;
use strict;
use common::sense;
use base 'App::Cmd::Command';
use ModelSEED::Configuration;

sub abstract { return "Log out" }
sub opt_spec { return (
        ["help|h|?", "Print this usage information"],
    );
}

sub execute {
    my ($self, $opts, $args) = @_;
    print($self->usage) && exit if $opts->{help};
    my $conf = ModelSEED::Configuration->new();
    delete $conf->config->{login};
    $conf->save();
}

1;
