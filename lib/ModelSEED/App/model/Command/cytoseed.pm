package ModelSEED::App::model::Command::cytoseed;
use strict;
use common::sense;
use base 'App::Cmd::Command';
use Try::Tiny;
use Class::Autouse qw(
    ModelSEED::Store
    ModelSEED::Auth::Factory
    ModelSEED::App::Helpers
);
sub abstract { return "Print CytoSEED version of the model" }
sub usage_desc { return <<END;
model cytoseed [ reference || - ]
END
}
sub opt_spec { return (
        ["help|h|?", "Print this usage information"],
    );
}

sub execute {
    my ($self, $opts, $args) = @_;
    print($self->usage) && return if $opts->{help};
    my $auth  = ModelSEED::Auth::Factory->new->from_config;
    my $store = ModelSEED::Store->new(auth => $auth);
    my $helper = ModelSEED::App::Helpers->new();
    my ($model, $ref) = $helper->get_object("model", $args, $store);
    $self->usage_error("Must specify a model to use") unless(defined($model));
    print join("\n", @{$model->printCytoSEED()});
}

1;
