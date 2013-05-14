package ModelSEED::App::mseed::Command::bio;
use strict;
use common::sense;
use ModelSEED::App::bio;
use base 'ModelSEED::App::MSEEDBaseCommand';
sub abstract { "Alias to ms-bio command" }
sub usage_desc { return "ms bio"; }
sub options {
    return ();
}

sub sub_execute {
    my ($self, $opts, $args) = @_;
	{
       	local @ARGV = @ARGV;
        my $arg0 = shift @ARGV;
        my $app = ModelSEED::App::bio->new;    
        $app->run;
    }
}

1;
