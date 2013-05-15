package ModelSEED::App::BaseCommand;
use strict;
use common::sense;
use ModelSEED::utilities qw( config args verbose set_verbose translateArrayOptions);
use base 'App::Cmd::Command';
use Class::Autouse qw(
    ModelSEED::App::Helpers
    ModelSEED::utilities
    ModelSEED::Reference
    ModelSEED::MS::Configuration
);

our $auth = undef;
our $store = undef;
our $gopts = undef;

sub opt_spec {
    my ( $class, $app ) = @_;
	return (
		[ 'store' => "Store from which data should be pulled and saved" ],
		[ 'help' => "Print usage for command" ],
		[ 'verbose|v' => "Print messages with command progress and results" ],
		[ 'dryrun' => "Don't permanently save any command results" ],
		$class->parent_options($app),
	)
}

sub execute {
    my ($self, $opts, $args) = @_;
    $gopts = $opts;
    if ($opts->{help}) {
    	my ($command) = $self->command_names;
    	$self->app->execute_command(
        	$self->app->prepare_command("help", $command)
      	);
    	print $self->usage;
    	return;
    }
    if ($opts->{verbose}) {
    	ModelSEED::utilities::set_verbose(1);
    	delete $opts->{verbose};
    }
    return $self->class_execute($opts, $args);
}

sub get_object {
	my ($self, $args) = @_;
	my $input = $self->store()->parseReference($args->{reference},$args->{type});
    return $self->store()->get_object($input);
}

sub get_data {
	my ($self, $args) = @_;
	my $input = $self->store()->parseReference($args->{reference},$args->{type});
    return $self->store()->get_data($input);
}

sub save_object {
	my ($self, $args) = @_;
	if (defined($self->opts()->{dryrun}) && $self->opts()->{dryrun} == 1) {
		verbose("Dry run selected. Results not saved!");
		return;
	}
	my $input = $self->store()->parseReference($args->{reference},$args->{type});
    $input->{object} = $args->{object};
    return $self->store()->save_object($input);
}

sub move {
	my ($self, $args) = @_;
	my $args = args(["object","newid"],{
        newstore => config()->currentUser()->primaryStore(),
        newworkspace => undef,
        cache => {}
    }, @_);
    my $store = config()->currentUser()->findStore($args->{newstore});
    if (defined($store)) {
    	$args->{cache}->{$args->{object}->uuid()} = 1;
    	my $dependencies = $args->{object}->dependencies();
    	for (my $i=0;$i<@{$dependencies};$i++) {
    		if (!defined($args->{cache}->{$dependencies->[$i]->uuid()})) {
    			$self->move({
    				object => $dependencies->[$i]->uuid(),
    				newid => $dependencies->[$i]->uuid(),
    				cache => $args->{cache}
    			})
    		}
    	}
    	$store->save_object({
    		object => $args->{object},
    		id => $args->{id},
    		workspace => $args->{workspace}
    	});
    }
}

sub save_data {
	my ($self, $args) = @_;
	if (defined($self->opts()->{dryrun}) && $self->opts()->{dryrun} == 1) {
		verbose("Dry run selected. Results not saved!");
		return;
	}
	my $input = $self->store()->parseReference($args->{reference},$args->{type});
	$input->{data} = $args->{data};
    return $self->store()->save_data($input);
}

sub opts {
	my ($self) = @_;
	return $gopts;
}

sub object_from_file {
    my ($self, $args) = @_;
    $args = args(["type","filename"], {
		store => undef
    }, $args);
    return $self->store()->object_from_file({
    	type => $args->{type},
    	filename => $args->{filename}
    });
}

sub store {
    my ($self) = @_;
    if (!defined($self->opts()->{store})) {
    	return config()->currentUser()->primaryStore();
    }
    return config()->currentUser()->findStore($self->opts()->{store});
}

sub kbfbaclient {
	
}

sub kbwsclient {
	
}

1;
