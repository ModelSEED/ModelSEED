package ModelSEED::App::stores::Command::primary;
use strict;
use common::sense;
use ModelSEED::utilities;
use base 'ModelSEED::App::StoresBaseCommand';
sub abstract { return "Selects or prints the current primary store." }
sub usage_desc { return "stores primary [name of store]"; }
sub options {
    return ();
}

sub sub_execute {
    my ($self, $opts, $args) = @_;
	my $name = shift @$args;
	my $config = ModelSEED::utilities::config();
	if (!defined($name)) {
		$name = $config->currentUser()->primaryStoreName();
	} else {
		$config->select_store($name);
		if (!defined($opts->{dryrun})) {
			$config->save_to_file();
		}
	}
	print "Currently selected store:\n";
	print $name."\n";
	return;
}

1;
