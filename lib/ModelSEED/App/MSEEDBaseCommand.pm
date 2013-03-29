package ModelSEED::App::MSEEDBaseCommand;
use strict;
use common::sense;
use base 'ModelSEED::App::BaseCommand';
sub parent_options {
    my ( $class, $app ) = @_;
    return (
        $class->options($app),
    );
}

sub class_execute {
    my ($self, $opts, $args) = @_;
    return $self->sub_execute($opts, $args);
}

1;
