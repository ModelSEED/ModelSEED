package ModelSEED::App::mseed::Command::login;
use strict;
use common::sense;
use Term::ReadKey;
use Class::Autouse qw(
    ModelSEED::Client::MSAccountManagement
);
use base 'ModelSEED::App::MSEEDBaseCommand';

sub abstract { return "Login as a user" }

sub usage_desc { return "ms login [username]"; }

sub options {
    return (
    	["password|p=s", "Provide password on command line"],
    );
}

sub sub_execute {
    my ($self, $opts, $args) = @_;
	my $username = shift @$args;
	unless (defined($username)) {
        $self->usage_error("Must provide username for Model SEED account!");
    } 
	my $password;
    if (!defined($opts->{password})) {
	    print "Enter password: ";
		if ($^O =~ m/^MSWin/) {
	        $password = <STDIN>;
	    } else {
	        ReadMode 2;
	        $password = ReadLine 0;
	        ReadMode 0;
	        chomp($password);
	    }
	    print "\n";
    } else {
    	$password = $opts->{password};
    }
	my $config = ModelSEED::utilities::config();
	$config->login({
		username => $username,
		password => $password
	});
	if (!defined($opts->{dryrun})) {
		$config->save_to_file();
	}
	print "Successfully logged in as '$username'\n";
	return;
}

1;
