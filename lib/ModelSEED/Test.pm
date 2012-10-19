########################################################################
# ModelSEED::Configuration - This moose object stores data on user env
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
    # Set the configuration from a filename
    $test->configFromFile( $filename );

    # Create a new test database
    $test->newTestDatabase();

    $test->store;
    $test->auth;

=head3 Trigger Setup

When the config_file is updated, config is cleard and
set to the new config location. When config is changed,
auth and db are updated with the corresponding config info.

    config_file => config =>
        auth
        db  => data update
            => store

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
has config_file => (
    is => 'rw',
    isa => 'Filename',
    builder => '_build_config_file',
    lazy => 1,
    trigger => \&trigger_config_file,
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

around 'clear_db' => sub {
    my $orig = shift;
    my $self = shift;
    $self->db->delete_database;
    $self->clear_store;
    $self->$orig();
    $self->db($self->_build_db());
    $self->db->init_database;
    $self->_load_test_data();
};

sub _load_test_data {
    my $self = shift;
    my $store = $self->store;
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
    return ModelSEED::Store->new( auth => $self->auth, database => $self->db );
}

sub _build_db_config {
    my $self = shift;
    my $config = $self->config;
    my $stores = $config->config->{stores};
    if(defined $stores && @$stores) {
        return $stores->[0];
    } else {
        $self->_trigger_db_config({
            class => 'ModelSEED::Database::FileDB',
            type => 'file',
            name => 'testdb',
            directory => tempdir(),
            filename => 'testdb',
        });
    }
}

sub _build_db {
    # Use the composite database, but only return the main one
    my $c =  ModelSEED::Database::Composite->new( use_config => 1 );
    return $c->primary;
}

1;
