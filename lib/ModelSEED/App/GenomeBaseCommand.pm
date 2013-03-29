package ModelSEED::App::GenomeBaseCommand;
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
    my $anno = shift @$args;
	unless (defined($name)) {
        $self->usage_error("Must provide ID of genome");
    }
   	my $annoObj = $self->get_object($anno)
    return $self->sub_execute($opts, $args,$annoObj);
}

1;
