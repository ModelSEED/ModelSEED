package ModelSEED::App::mseed::Command::mapping; 
use strict;
use common::sense;
use ModelSEED::App::mapping;
use base 'App::Cmd::Command';
sub abstract { "Alias to ms-mapping command" }
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
        my $app = ModelSEED::App::mapping->new;    
        $app->run;
    }
}
1;
