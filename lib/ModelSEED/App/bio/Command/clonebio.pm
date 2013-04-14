package ModelSEED::App::bio::Command::clonebio;
use strict;
use common::sense;
use base 'App::Cmd::Command';
use Class::Autouse qw(
    ModelSEED::Store
    ModelSEED::Auth::Factory
    ModelSEED::App::Helpers
);
use ModelSEED::utilities qw( verbose set_verbose translateArrayOptions );
sub abstract { return "Clone a biochemistry object, giving the copy a new name" }
sub usage_desc { return "bio clonebio [ < biochemistry | biochemistry ] name"; }
sub opt_spec {
    return (
    	["verbose|v", "Print messages with progress"],
        ["help|h|?", "Print this usage information"],
    );
}

sub execute {
    my ($self, $opts, $args) = @_;

    $self->usage_error("Must specify a biochemistry to use") unless(defined($args->[0]));
    $self->usage_error("Must specify the name of the new biochemistry") unless(defined($args->[1]));

    #verbosity
    set_verbose(1) if $opts->{verbose};

    my $auth  = ModelSEED::Auth::Factory->new->from_config;
    my $store = ModelSEED::Store->new(auth => $auth);

    my $helper = ModelSEED::App::Helpers->new();
    my ($biochemistry,$ref) = $helper->get_object("biochemistry", $args, $store);
    $self->usage_error("Biochemistry ".$args->[0]." not found") unless defined($biochemistry);

    verbose("Cloning: ".$biochemistry->name()." as ".$args->[1]."\n");

    my $new_ref = $helper->process_ref_string($args->[1], "biochemistry", $auth->username);
    $store->save_object($new_ref,$biochemistry);
}

1;
