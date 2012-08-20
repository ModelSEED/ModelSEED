package ModelSEED::App::mseed::Command::import; 
use ModelSEED::App::stores;
use base 'App::Cmd::Command';
use Class::Autouse qw(
    ModelSEED::App::import
);
sub abstract { "Import genomes, models, etc. from external sources" }
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
        my $app = ModelSEED::App::import->new;    
        $app->run;
    }
}
1;
