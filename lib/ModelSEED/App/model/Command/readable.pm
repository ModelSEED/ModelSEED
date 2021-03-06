package ModelSEED::App::model::Command::readable;
use strict;
use common::sense;
use ModelSEED::App::model;
use base 'ModelSEED::App::ModelBaseCommand';
use ModelSEED::utilities;
sub abstract { return "Prints a readable format for the object" }
sub usage_desc { return "model readable [model id]" }
sub options {
    return ();
}
sub sub_execute {
    my ($self, $opts, $args,$model) = @_;
	my $format = shift @$args;
    ModelSEED::utilities::error("Must specify format for model export") unless(defined($format));
    print $model->toReadableString();
}

1;
