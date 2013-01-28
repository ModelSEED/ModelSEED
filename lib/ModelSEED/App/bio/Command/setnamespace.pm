package ModelSEED::App::bio::Command::setnamespace;
use strict;
use common::sense;
use base 'App::Cmd::Command';
use Class::Autouse qw(
    ModelSEED::Store
    ModelSEED::Auth::Factory
    ModelSEED::App::Helpers
);
sub abstract { return "Changes the default namespace of a biochemistry object for use when printing ids" };
sub usage_desc { return "bio setnamespace [biochemistry] [namespace]"; }
sub opt_spec {
    return (
    );
}

sub execute {
    my ($self, $opts, $args) = @_;
    my $auth  = ModelSEED::Auth::Factory->new->from_config;
    my $store = ModelSEED::Store->new(auth => $auth);
    my $helper = ModelSEED::App::Helpers->new();
    my ($biochemistry,my $ref) = $helper->get_object("biochemistry", $args, $store);
    $self->usage_error("Must specify an biochemistry to use") unless(defined($biochemistry));
    $self->usage_error("Must specify a namespace to use") unless(defined($args->[1]));

    $biochemistry->defaultNameSpace($args->[1]);
    $store->save_object($ref,$biochemistry);
}

1;
