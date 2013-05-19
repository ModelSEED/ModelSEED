package ModelSEED::App::stores::Command::createws;
use strict;
use common::sense;
use base 'ModelSEED::App::StoresBaseCommand';
sub abstract { return "Creates a new workspace." }
sub usage_desc { return "stores createws [name of workspace] [default permissions]"; }
sub options {
    return ();
}

sub sub_execute {
    my ($self, $opts, $args) = @_;
	$self->usage_error("Must supply a name for new workspace") unless(defined($args->[0]));
	$self->usage_error("Must supply default permissions for new workspace") unless(defined($args->[1]));
	if ($self->store()->associatedStore()->type() ne "workspace") {
		$self->usage_error("Cannot create workspace with currently selected store!");
	}
	my $output;
	eval {
		$output = $self->store()->wsstore()->workspace()->create_workspace({
			workspace => $args->[0],
			default_permission => $args->[1],
			auth => $self->store()->wsauth()
		});
	};
	if (defined($output)) {
		print "Workspace successfullly created:\n";
		print $args->[0]."\n";
	} else {
		print "Command failed!\n";
	}
	return;
}

1;
