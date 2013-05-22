package ModelSEED::App::model::Command::cytoseed;
use strict;
use common::sense;
use ModelSEED::App::model;
use base 'ModelSEED::App::ModelBaseCommand';
use Try::Tiny;
use Class::Autouse qw(
    ModelSEED::Store
    ModelSEED::Auth::Factory
    ModelSEED::App::Helpers
);
sub abstract { "Print CytoSEED version of the model" }
sub usage_desc { return "ms model cytoseed [model] [options]"; }
sub options {
    return ();
}

sub sub_execute {
    my ($self, $opts, $args,$model) = @_;
    print $model->printCytoSEED();
}

1;
