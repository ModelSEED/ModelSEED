package ModelSEED::App::mseed::Command::model; 
use strict;
use common::sense;
use ModelSEED::App::model;
use base 'App::Cmd::Command';
sub abstract { "Alias to ms-model command" }
sub opt_spec { return (
        ["help|h|?", "Print this usage information"],
    );
}
sub execute {
    my ($self, $opts, $args) = @_;
    print($self->usage) && exit if $opts->{help};
    {
        local @ARGV = @ARGV;
        my $arg0 = shift @ARGV;
        my $app = ModelSEED::App::model->new;    
        $app->run;
    }
}
1;
