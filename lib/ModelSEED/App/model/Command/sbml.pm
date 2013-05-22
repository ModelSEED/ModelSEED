package ModelSEED::App::model::Command::sbml;
use strict;
use common::sense;
use ModelSEED::App::model;
use base 'ModelSEED::App::ModelBaseCommand';
use ModelSEED::utilities;
sub abstract { return "Print SBML version of the model" }
sub usage_desc { return "model sbml [model id]" }
sub options {
    return ();
}
sub sub_execute {
    my ($self, $opts, $args,$model) = @_;
	my $format = shift @$args;
    ModelSEED::utilities::error("Must specify format for model export") unless(defined($format));
    print $model->printSBML();
}

1;
