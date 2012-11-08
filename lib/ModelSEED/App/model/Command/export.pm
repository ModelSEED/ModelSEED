package ModelSEED::App::model::Command::export;
use strict;
use common::sense;
use base 'App::Cmd::Command';
use Class::Autouse qw(
    ModelSEED::Store
    ModelSEED::Auth::Factory
    ModelSEED::App::Helpers
);
sub abstract { return "Exports metabolic model to various exchange formats" }
sub usage_desc { return "model export [model id] [format:readable/sbml/exchange/html/json]" }
sub opt_spec { return (
        ["help|h|?", "Print this usage information"],
    );
}
sub execute {
    my ($self, $opts, $args) = @_;
    my $auth  = ModelSEED::Auth::Factory->new->from_config;
    my $store = ModelSEED::Store->new(auth => $auth);
    my $helper = ModelSEED::App::Helpers->new();
    my ($model, $modelRef) = $helper->get_object("model", $args, $store);
    $self->usage_error("Must specify an model to use") unless(defined($model));
    $self->usage_error("Must specify format for model export") unless(defined($args->[1]));
    print $model->export({format => $args->[1]});
}
1;
