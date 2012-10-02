package ModelSEED::App::bio::Command::readable;
use strict;
use common::sense;
use base 'App::Cmd::Command';
use Class::Autouse qw(
    ModelSEED::Store
    ModelSEED::Auth::Factory
    ModelSEED::App::Helpers
);
sub abstract { return "Prints a readable format for the object" }
sub usage_desc { return "bio readable [< name | name]" }
sub opt_spec { return (
        ["help|h|?", "Print this usage information"],
    );
};

sub execute {
    my ($self, $opts, $args) = @_;
    print($self->usage) && return if $opts->{help};
    my $auth  = ModelSEED::Auth::Factory->new->from_config;
    my $store = ModelSEED::Store->new(auth => $auth);
    my $helper = ModelSEED::App::Helpers->new();
    my ($biochemistry, $ref) = $helper->get_object("biochemistry", $args, $store);
    $self->usage_error("Must specify an biochemistry to use") unless(defined($biochemistry));
    print $biochemistry->toReadableString();
}
1;
