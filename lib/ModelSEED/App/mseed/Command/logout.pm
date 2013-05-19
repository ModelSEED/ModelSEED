package ModelSEED::App::mseed::Command::logout;
use strict;
use common::sense;
use ModelSEED::utilities;
use base 'ModelSEED::App::MSEEDBaseCommand';
sub abstract { return "Log out the currently logged user." }
sub usage_desc { return "ms logout"; }
sub options {
    return ();
}

sub sub_execute {
    my ($self, $opts, $args) = @_;
	my $config = ModelSEED::utilities::config();
	$config->logout();
	if (!defined($opts->{dryrun})) {
		$config->save_to_file();
	}
	print "Successfully logged out to public!\n";
	return;
}

1;
