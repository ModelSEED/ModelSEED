package ModelSEED::App::bio::Command::printdbfiles;
use strict;
use common::sense;
use base 'App::Cmd::Command';
use Class::Autouse qw(
    ModelSEED::Store
    ModelSEED::Auth::Factory
    ModelSEED::App::Helpers
);
sub abstract { return "Prints FBA database files used by the MFAToolkit" }
sub usage_desc { return "bio printdbfiles [< biochemistry | biochemistry] [options]"; }
sub opt_spec {
    return (
        ["help|h|?", "Print this usage information"],
        ["directory|d", "Print files into this directory"],
    );
}

sub execute {
    my ($self, $opts, $args) = @_;
    print($self->usage) && return if $opts->{help};
    my $auth    = ModelSEED::Auth::Factory->new->from_config;
    my $store   = ModelSEED::Store->new(auth => $auth);
    my $helper  = ModelSEED::App::Helpers->new();
    my ($biochemistry,$ref) = $helper->get_object("biochemistry", $args, $store);
    unless (defined $biochemistry) {
        $self->usage_error("Must specify an biochemistry to use");
    }
    my $dbfiles_args = { forceprint => 1 };
    if (defined $opts->{directory}) {
        $dbfiles_args->{directory} = $opts->{directory};
    }
    $biochemistry->printDBFiles($dbfiles_args);
}
1;
