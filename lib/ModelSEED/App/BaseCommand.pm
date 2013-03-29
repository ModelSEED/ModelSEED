package ModelSEED::App::BaseCommand;
use strict;
use common::sense;
use ModelSEED::utilities qw( config args verbose set_verbose translateArrayOptions);
use base 'App::Cmd::Command';
use Class::Autouse qw(
    ModelSEED::Store
    ModelSEED::Auth::Factory
    ModelSEED::App::Helpers
    ModelSEED::utilities
);

our $auth = undef;
our $store = undef;

sub opt_spec {
    my ( $class, $app ) = @_;
	return (
		[ 'help' => "Print usage for command" ],
		[ 'verbose|v' => "Print messages with command progress and results" ],
		[ 'dryrun' => "Don't permanently save any command results" ],
		$class->parent_options($app),
	)
}

sub execute {
    my ($self, $opts, $args) = @_;
    if ($opts->{help}) {
    	my ($command) = $self->command_names;
    	$self->app->execute_command(
        	$self->app->prepare_command("help", $command)
      	);
    	#print $self->usage;
    	return;
    }
    if ($opts->{verbose}) {
    	ModelSEED::utilities::SETVERBOSE(1);
    	delete $opts->{verbose};
    }
    return $self->class_execute($opts, $args);
}

sub get_object {
	my ($self, $id) = @_;
	my $auth = ModelSEED::Auth::Factory->new->from_config;
    my $store = ModelSEED::Store->new(auth => $auth);	
}

sub get_data {
	my ($self, $id) = @_;
	my $auth = ModelSEED::Auth::Factory->new->from_config;
    my $store = ModelSEED::Store->new(auth => $auth);
}

sub save_object {
	my ($self, $obj) = @_;
	my $auth = ModelSEED::Auth::Factory->new->from_config;
    my $store = ModelSEED::Store->new(auth => $auth);
	
}

sub auth {
	my ($self) = @_;
	my $config = config();
	if (!defined($auth)) {
		if ($config->username() eq "Public") {
			$auth = ModelSEED::Auth::Public->new();
		} else {
			$auth = ModelSEED::Auth::Basic->new(
                username => $config->username(),
                password => $config->password()
            );
		}
	}
	return $auth;
}

sub store {
	my ($self) = @_;
	my $config = config();
	if (!defined($store)) {
		$store = ModelSEED::Store->new(auth => $self->auth());
	}
	return $store;
}

sub kbworkspace {
	my $kbwsclient = $self->kbwsclient();
	my $settings = $kbwsclient->get_user_settings({
			auth => $self->kbauth();
		});
		 = $settings->{workspace};
}

sub kbauth {
	
}

sub kbfbaclient {
	
}

sub kbwsclient {
	
}

1;