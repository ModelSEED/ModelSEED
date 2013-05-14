package ModelSEED::App::model::Command::export;
use strict;
use common::sense;
use ModelSEED::App::model;
use base 'ModelSEED::App::ModelBaseCommand';
use ModelSEED::utilities qw( config error args verbose set_verbose translateArrayOptions);
sub abstract { return "Exports metabolic model to various exchange formats" }
sub usage_desc { return "model export [model id] [format:readable/sbml/exchange/html/json]" }
sub options {
    return ();
}
sub sub_execute {
    my ($self, $opts, $args,$model) = @_;
	my $format = shift @$args;
    error("Must specify format for model export") unless(defined($format));
    print $model->export({format => $format});
}

1;