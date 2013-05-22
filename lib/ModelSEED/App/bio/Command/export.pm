package ModelSEED::App::bio::Command::export;
use strict;
use common::sense;
use ModelSEED::App::bio;
use base 'ModelSEED::App::BioBaseCommand';
use Class::Autouse qw(
    ModelSEED::MS::Factories::ExchangeFormatFactory
    ModelSEED::MS::Model
);
use ModelSEED::utilities;
sub abstract { return "Exports biochemistry data to various formats" }
sub usage_desc { return "bio export [ biochemistry id ] [format:readable/html/json] [options]"; }
sub options {
    return ();
}
sub sub_execute {
    my ($self, $opts, $args,$bio) = @_;
    $self->usage_error("Must specify format for biochemistry export") unless(defined($args->[0]));
    print $bio->export({format => $args->[0]});
}

1;
