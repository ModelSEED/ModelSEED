package ModelSEED::App::BaseCommand;
use strict;
use common::sense;
use base 'App::Cmd::Command';
use Class::Autouse qw(
    ModelSEED::Store
    ModelSEED::Auth::Factory
    ModelSEED::App::Helpers
    ModelSEED::utilities
);

sub opt_spec {
    my ( $class, $app ) = @_;
	return (
		[ 'help' => "Print usage for command" ],
		[ 'verbose|v' => "Print messages with command progress and results" ],
		$class->options($app),
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
    return $self->sub_execute($opts, $args);
}

1;
