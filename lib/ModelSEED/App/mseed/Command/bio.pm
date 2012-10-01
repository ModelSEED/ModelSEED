package ModelSEED::App::mseed::Command::bio; 
use strict;
use common::sense;
use ModelSEED::App::bio;
use base 'App::Cmd::Command';
sub abstract { "Alias to ms-bio command" }
sub opt_spec { return (
        ["help|h|?", "Print this usage information"],
    );
}
sub execute {
    my ($self, $opts, $args) = @_;
    print($self->usage) && return if $opts->{help};
    {
        local @ARGV = @ARGV;
        my $arg0 = shift @ARGV;
        my $app = ModelSEED::App::bio->new;    
        $app->run;
    }
}
1;
