package ModelSEED::App::stores::Command::workspace;
use strict;
use common::sense;
use ModelSEED::utilities;
use base 'ModelSEED::App::StoresBaseCommand';
sub abstract { return "Selects or prints the current primary workspace." }
sub usage_desc { return "stores workspace [name of workspace]"; }
sub options {
    return ();
}

sub sub_execute {
    my ($self, $opts, $args) = @_;
	my $name = shift @$args;
	my $config = ModelSEED::utilities::config();
	if (!defined($name)) {
		if ($self->store()->associatedStore()->type() ne "workspace") {
			$name = $config->currentUser()->login();
		} else {
			$name = $self->store()->wsworkspace();
		}
	} elsif ($self->store()->associatedStore()->type() ne "workspace") {
		print "Cannot change workspace with selected store type!\n";
		$name = $config->currentUser()->login();
	} else {
		my $wsmeta;
    	eval {
	    	$wsmeta = $self->store()->wsstore()->workspace()->get_workspacemeta({
				workspace => $name,
				auth => $self->store()->wsauth()
	    	});
    	};
    	if (!defined($wsmeta)) {
    		$self->usage_error("Must create workspace before selecting it!");
    	}
    	$self->store()->wsstore()->workspace()->set_user_settings({
	    	setting => "workspace",
			value => $name,
			auth => $self->store()->wsauth()
	    });
	}
	print "Currently selected workspace:\n";
	print $name."\n";
	return;
}

1;
