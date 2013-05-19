package ModelSEED::App::mseed::Command::settings;
use strict;
use common::sense;
use Class::Autouse qw(
    ModelSEED::Client::MSAccountManagement
);
use base 'ModelSEED::App::MSEEDBaseCommand';
use ModelSEED::utilities;

sub abstract { return "Prints a list of current settings" }

sub usage_desc { return "ms settings"; }

sub options {
    return ();
}

sub sub_execute {
    my ($self, $opts, $args) = @_;
	my $config = ModelSEED::utilities::config();
	my $ws;
	if ($self->store->associatedStore->type() eq "filedb" || $self->store->associatedStore->type() eq "mongo") {
    	$ws = $config->login;
    } else {
    	$ws = $self->store->wsworkspace();
    }
	my $tbl = [
		["Current login",$config->username],
		["Primary store",$config->currentUser->primaryStoreName()],
		["Workspace",$ws],
		["Default biochemistry",$self->store->defaultBiochemistry_ref],
		["Default mapping",$self->store->defaultMapping_ref],
	];
    my $table = Text::Table->new(
		'Setting','Value'
	);
    $table->load(@$tbl);
    print $table;
	return;
}

1;
