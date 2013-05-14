package ModelSEED::App::mseed::Command::import; 
use strict;
use common::sense;
use ModelSEED::App::import;
use base 'ModelSEED::App::MSEEDBaseCommand';
use Class::Autouse qw(
    ModelSEED::App::import
);
sub abstract { "Import genomes, models, etc. from external sources" }
sub usage_desc { return "ms import"; }
sub options {
    return ();
}

sub sub_execute {
    my ($self, $opts, $args) = @_;
	{
       	local @ARGV = @ARGV;
        my $arg0 = shift @ARGV;
        my $app = ModelSEED::App::import->new;    
        $app->run;
    }
}

1;