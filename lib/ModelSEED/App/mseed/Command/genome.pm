package ModelSEED::App::mseed::Command::genome; 
use strict;
use common::sense;
use ModelSEED::App::genome;
use base 'ModelSEED::App::MSEEDBaseCommand';
sub abstract { "Alias to ms-genome command" }
sub usage_desc { return "ms genome"; }
sub options {
    return ();
}

sub sub_execute {
    my ($self, $opts, $args) = @_;
	{
       	local @ARGV = @ARGV;
        my $arg0 = shift @ARGV;
        my $app = ModelSEED::App::genome->new;    
        $app->run;
    }
}

1;