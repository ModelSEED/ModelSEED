########################################################################
# ModelSEED::Test - Test fixtures for the ModelSEED
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location:
#   Mathematics and Computer Science Division, Argonne National Lab;
#   Computation Institute, University of Chicago
#
# Date of module creation: 2012-10-19
########################################################################

=head1 ModelSEED::Test

Test fixtures for the ModelSEED

=head2 SYNOPSIS

    my $test = ModelSEED::Test->new;
    my $conf  = $test->config;
    my $db    = $test->db;
    my $auth  = $test->auth;
    my $store = $test->store;

=head2 METHODS

=head3 new

Construct a new test instance. This object is designed
to not modify your working environment. It is configurable,
but the defaults should do what you want... give you an auth;
a database and store that contain test data. And not interact
with your main system.

=head3 config_file

Returns the path to the configuration file used. This can
be set to a custom config_file if you want.

=head3 config

Returns the L<ModelSEED::Configuration> instance in use.  If you
pass in a different instance, it will use that one.  If you pass
in a hash reference, it will construct a Configuration object based
on that and save it to a temporary location.

=head3 db_config

Returns the HashRef corresponding to the database configuration
in the config object. If you pass in a hash-ref, this will update
the database configuration and destroy the existing database.

=head3 db

Returns the L<ModelSEED::Database> object in use. If you pass
in a different database, it will use that one, deleting the existing
database.

=head3 auth

Returns a L<ModelSEED::Auth> object. By default, this is a basic
auth with username: "alice", password: "alice".

=head3 store

Returns a L<ModelSEED::Store> object (using the auth and database objects).

=head2 Update System

Each attribute of this object is ordered into a hierarchy. Changes
to the base settings (e.g. C<config_file>) will propagate up and
reset nearly every other attribute. This should make switching data
easy, but adds additional complexity.

    # x => y
    # Changes to x cause y to reset

    config_file  => config
    config       => auth db
    auth         => store ( and save config )
    db           => store ( and save config )
    
=cut

package ModelSEED::Test;
use Moose;
use Moose::Util::TypeConstraints;
use File::Temp qw(tempdir tempfile);
use Module::Load qw( load );
use Cwd qw( abs_path );
use LWP::Simple qw( getstore );
use ModelSEED::utilities qw( args );
use ModelSEED::Configuration;
use ModelSEED::Store;
use ModelSEED::Database::Composite;
use ModelSEED::Auth::Factory;
use ModelSEED::MS::Factories::TableFileFactory;

subtype 'Filename' => as 'Str' => where { -f $_ };
sub _config_from_hash {
    my $hash = shift;
    my ($fh, $filename) = tempfile;
    close($fh);
    return ModelSEED::Configuration->new(
        filename => $filename,
        config => $hash,
    );
}

coerce 'ModelSEED::Configuration',
    from 'HashRef',
    via { _config_from_hash($_) };
    
has config_file => (
    is => 'rw',
    isa => 'Filename',
    builder => '_build_config_file',
    lazy => 1,
    trigger => \&_trigger_config_file,
);
has config => (
    is      => 'rw',
    isa     => 'ModelSEED::Configuration',
    builder => '_build_config',
    trigger => \&_trigger_config,
    lazy    => 1
);
has auth => (
    is      => 'rw',
    isa     => 'ModelSEED::Auth',
    builder => '_build_auth',
    clearer => 'clear_auth',
    trigger => \&_trigger_auth,
    lazy    => 1
);
has store => (
    is      => 'rw',
    isa     => 'ModelSEED::Store',
    builder => '_build_store',
    clearer => 'clear_store',
    lazy    => 1
);
has db => (
    is      => 'rw',
    builder => '_build_db',
    clearer => 'clear_db',
    trigger => \&clear_store,
    lazy    => 1
);
has db_config => (
    is      => 'rw',
    isa     => 'HashRef',
    builder => '_build_db_config',
    trigger => \&_trigger_db_config,
    lazy    => 1
);

after 'clear_auth' => sub {
    my $self = shift;
    $self->clear_store;
};

after 'clear_db' => sub {
    my $self = shift;
    $self->clear_store;
};


before 'clear_db' => sub {
    my $self = shift;
    $self->db->delete_database;
    $self->clear_store;
};


sub _test_data_dir {
    my $self = shift;
    my $top_dir  = ModelSEED::utilities::MODELSEEDCORE();
    my $data_dir = "$top_dir/testdb";
    if ( !-e $data_dir ) { 
        my $tgz_file = "$top_dir/testdb.tgz";
        $tgz_file    = abs_path $tgz_file;
        getstore("http://bioseed.mcs.anl.gov/~chenry/ModelSEED/testdb.tgz", $tgz_file);
        `tar -xzf $tgz_file`;
    }
    return $data_dir;
}

sub _trigger_auth {
    my ($self, $new, $old) = @_;
    my $c = $self->config;
    if ( defined $new && $new->isa("ModelSEED::Auth::Basic")) {
        $c->config->{login}->{username} = $new->username;
        $c->config->{login}->{password} = $new->password;
    } elsif( !defined $new ) {
        $self->config->{login} = undef;
    }
    $c->save();
    $self->clear_store;
}

sub _trigger_config_file {
    my ($self, $new, $old) = @_;
    $self->config(ModelSEED::Configuration->new( filename => $new ));
}

sub _trigger_config {
    my $self = shift;
    $self->clear_auth;
    $self->clear_db;
}

sub _trigger_db_config {
    my ($self, $new) = @_;
    my $c = $self->config;
    $c->config->{stores} = [ $new ];
    $c->save();
    $self->config($c);
}

sub _build_config_file {
    my ($fh, $filename) = tempfile;
    close($fh);
    $ENV{MODELSEED_CONF} = abs_path($filename);
    return $filename;
}

sub _build_config {
    my $self = shift;
    return ModelSEED::Configuration->new( filename => $self->config_file );
}

sub _build_auth {
    return ModelSEED::Auth::Basic->new( username => "alice", password => "alice" );
}

sub _build_store {
    my $self = shift;
    my $store = ModelSEED::Store->new( auth => $self->auth, database => $self->db );
    $self->_load_test_data($store);
    return $store;
}

sub _build_db_config {
    my $self = shift;
    my $config = $self->config;
    my $stores = $config->config->{stores};
    if(defined $stores && @$stores > 0) {
        return $stores->[0];
    } else {
        my $conf = {
            class => 'ModelSEED::Database::FileDB',
            type => 'file',
            name => 'testdb',
            directory => tempdir(),
            filename => 'testdb',
        };
        $self->_trigger_db_config($conf);
        return $conf;
    }
}

sub _build_db {
    my $self = shift;
    # Use the composite database, but only return the main one
    $self->db_config;
    my $c  = ModelSEED::Database::Composite->new( use_config => 1 );
    my $db = $c->primary; 
    $db->init_database;
    return $db;
}

sub _load_test_data {
    my $self = shift;
    my $store = shift;
    my $data_dir = $self->_test_data_dir;
    my $factory = ModelSEED::MS::Factories::TableFileFactory->new(
        filepath => $data_dir, namespace => 'ModelSEED' 
    );
    my $user = $self->auth->username;
    my $bio = $factory->createBiochemistry;
    $store->save_object("biochemistry/$user/testdb", $bio);
    my $map = $factory->createMapping(biochemistry => $bio);
    $store->save_object("mapping/$user/testdb", $map);
    my $ann = $factory->createAnnotation(genome => "testgenome", mapping => $map);
    $store->save_object("annotation/$user/testdb", $ann);
    my $mod = $ann->createStandardFBAModel();
    $store->save_object("model/$user/testdb", $mod);
}

1;
