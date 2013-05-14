package ModelSEED::App::mseed::Command::whoami;
use strict;
use common::sense;
use base 'ModelSEED::App::MSEEDBaseCommand';
use ModelSEED::utilities qw( config args verbose set_verbose translateArrayOptions);
sub abstract { return "Return the currently logged in user" }
sub usage_desc { return "ms whoami"; }
sub options {
    return ();
}

sub sub_execute {
    my ($self, $opts, $args) = @_;
	my $config = config();
	print $config->username()."\n";
	return;
}

1;
