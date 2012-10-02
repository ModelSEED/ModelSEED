package ModelSEED::App::mseed::Command::genome; 
use strict;
use common::sense;
use ModelSEED::App::genome;
use base 'App::Cmd::Command';
sub abstract { "Alias to ms-genome command" }
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
        my $app = ModelSEED::App::genome->new;    
        $app->run;
    }
}
1;
