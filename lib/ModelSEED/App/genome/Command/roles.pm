package ModelSEED::App::genome::Command::roles;
use strict;
use common::sense;
use base 'App::Cmd::Command';
use Class::Autouse qw(
    ModelSEED::Store
    ModelSEED::Auth::Factory
    ModelSEED::Reference
    ModelSEED::Configuration
    ModelSEED::App::Helpers
);
sub abstract { return "Get the list of roles for an annotated genome" }
sub usage_desc { return "genome roles [ genome || - ]"; }
sub description { return <<END;
Print the roles that this genome has annotated features for.
END
}
sub opt_spec { return (
        ["help|h|?", "Print this usage information"],
    );
}

sub execute {
    my ($self, $opts, $args) = @_;
    print($self->usage) && exit if $opts->{help};
    my $annotation = $self->_getAnnotation($args);
    $self->usage_error("Must specify an annotation to use") unless(defined($annotation));
    print map { $_->name ."\n" } @{$annotation->roles()};
}

sub _getAnnotation {
    my ($self, $args) = @_;
    my $helpers = ModelSEED::App::Helpers->new();
    my $ref = $helpers->get_base_ref("annotation", $args);
    if (defined($ref)) {
        my $auth  = ModelSEED::Auth::Factory->new->from_config;
        my $store = ModelSEED::Store->new(auth => $auth);
        return $store->get_object($ref);
    }
}

1;
