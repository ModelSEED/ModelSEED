package ModelSEED::App::mseed::Command::stores; 
use ModelSEED::App::stores;
use base 'App::Cmd::Command';
sub abstract { "Alias to mseed-stores command" }
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
        my $app = ModelSEED::App::stores->new;    
        $app->run;
    }
}
1;
