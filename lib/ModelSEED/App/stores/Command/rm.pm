package ModelSEED::App::stores::Command::rm;
use strict;
use common::sense;
use Class::Autouse qw(ModelSEED::Configuration);
use Module::Load qw(load);
use Try::Tiny;
use JSON::XS;
use ModelSEED::Exceptions;
use base 'App::Cmd::Command';


my $MS = ModelSEED::Configuration->new();
sub abstract { "Remove a storage interface" }
sub description { return <<HERDOC;
Remove a storage interface from the list of interfaces available.
By default, removing a storage interface will delete all the data
contained in that interface. If you would like to keep the data and
just remove the database configuration, supply the --keep_data argument

    \$ stores rm <name> --keep_data

HERDOC
}
sub usage_desc { "%c rm <name>" }
sub command_names { qw(rm remove) }
sub opt_spec { return (
        ["help|h|?", "Print this usage information"],
        ["keep_data", "Do not delete the data when removing the database"],
    );
}

sub validate_args {
    my ($self, $opt, $args) = @_;
    unless(@$args == 1) {
        $self->usage_error("Must supply a storage interface to remove");
    }
    my $name = $args->[0];
    unless(defined($MS->config->{stores})) {
        $self->usage_error("No storage interface $name found");
    }
    my $map = { map { $_->{name} => $_ } @{$MS->config->{stores}} };
    unless(defined($map->{$name})) {
        $self->usage_error("No storage interface $name found");
    }
}

sub execute {
    my ($self, $opts, $args) = @_;
    print($self->usage) && exit if $opts->{help};
    my $name = $args->[0];
    my $stores = $MS->config->{stores};
    my $remove;
    my $config;
    for(my $i=0; $i<@$stores; $i++) {
        $remove = $i if $stores->[$i]->{name} eq $name;
        $config = $stores->[$i];
        last if defined $remove; 
    }
    splice(@$stores, $remove, 1);
    my $db = $self->_get_database_instance($config);
    $db->delete_database( { keep_data => $opts->{keep_data} });
    $MS->config->{stores} = $stores;
    $MS->save;
}

sub _get_database_instance {
    my ($self, $config) = @_;
    my $class = $config->{class};
    my $instance;
    try {
        load $class;
        $instance = $class->new($config);
    } catch {
        ModelSEED::Exception::DatabaseConfigError->throw(
            dbName => $config->{name},
            configText => JSON::XS->new->pretty(1)->encode($config),
        );
    };
    return $instance;
}

1;
