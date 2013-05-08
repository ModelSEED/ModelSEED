package ModelSEED::App::mseed::Command::model; 
use strict;
use common::sense;
use ModelSEED::App::model;
use base 'ModelSEED::App::MSEEDBaseCommand';
use Class::Autouse qw(
    ModelSEED::App::import
);
sub abstract { "Alias to ms-model command" }
sub usage_desc { return "ms import"; }
sub options {
    return ();
}

sub sub_execute {
    my ($self, $opts, $args) = @_;
	{
       	local @ARGV = @ARGV;
        my $arg0 = shift @ARGV;
        my $app = ModelSEED::App::model->new;    
        $app->run;
    }
}

1;
