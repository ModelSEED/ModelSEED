package ModelSEED::App::mseed::Command::mapping; 
use strict;
use common::sense;
use ModelSEED::App::mapping;
use base 'ModelSEED::App::MSEEDBaseCommand';
use Class::Autouse qw(
    ModelSEED::App::import
);
sub abstract { "Alias to ms-mapping command" }
sub usage_desc { return "ms import"; }
sub options {
    return ();
}

sub sub_execute {
    my ($self, $opts, $args) = @_;
	{
       	local @ARGV = @ARGV;
        my $arg0 = shift @ARGV;
        my $app = ModelSEED::App::mapping->new;    
        $app->run;
    }
}

1;