package ModelSEED::App::mseed::Command::setconfig;
use strict;
use common::sense;
use Class::Autouse qw(
    ModelSEED::Client::MSAccountManagement
);
use base 'ModelSEED::App::MSEEDBaseCommand';

sub abstract { return "Change a configuration option" }

sub usage_desc { return "ms setconfig [variable] [new value]"; }

sub options {
    return ();
}

sub sub_execute {
    my ($self, $opts, $args) = @_;
	my $var = shift @$args;
	my $value = shift @$args;
	unless (defined($var)) {
        $self->usage_error("Must provide variable to be set!");
    }
    unless (defined($value)) {
        $self->usage_error("Must provide value to set");
    }
	my $config = ModelSEED::utilities::config();
	$config->$var($value);
	if (!defined($opts->{dryrun})) {
		$config->save_to_file();
	}
	print "Successfully set ".$var." to ".$value."\n";
	return;
}

1;
