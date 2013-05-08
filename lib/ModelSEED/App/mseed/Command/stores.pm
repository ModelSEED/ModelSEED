package ModelSEED::App::mseed::Command::stores;
use strict;
use common::sense;
use ModelSEED::App::stores;
use base 'ModelSEED::App::MSEEDBaseCommand';
sub abstract { return "Alias to mseed-stores command" }
sub usage_desc { return "ms stores"; }
sub options {
    return ();
}

sub sub_execute {
    my ($self, $opts, $args) = @_;
	{
        local @ARGV = @ARGV;
        my $arg0 = shift @ARGV;
        my $app = ModelSEED::App::stores->new;    
        $app->run;
    }
}

1;
