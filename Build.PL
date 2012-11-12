use 5.006;
use strict;
use warnings;
use Module::Build;

my $subclass = Module::Build->subclass(
    class => 'Module::Build::ModelSEED',
    code => <<'END_OF_CODE',
# kbase action : Equivilent to ./Build ; ./Build install
# but does not install KBase client code.
sub ACTION_kbase {
    my ($self) = @_;
    my $el = $self->build_elements;
    $el = [ grep { $_ ne 'kbase' } @$el ];
    $self->build_elements($el);
    return $self->dispatch('install');
}

sub ACTION_test {
    my ($self) = @_;

    if ( $ENV{ RELEASE_TESTING } or $ENV{ AUTOMATED_TESTING } ) {
        $self->test_files( 't', 'xt/release' )
            unless $self->{ properties }->{ test_files };
    }
    $self->recursive_test_files( 1 );
    return $self->SUPER::ACTION_test();

}

sub ACTION_testauthor {
    my ($self) = @_;

    $self->depends_on('build');
    local $ENV{ RELEASE_TESTING } = 1;
    $self->test_files( qw( xt/author ) );
    $self->recursive_test_files( 1 );
    $self->depends_on('test');

}

sub ACTION_testslow {
    my ($self) = @_;

    $self->depends_on('build');
    local $ENV{ RELEASE_TESTING } = 1;
    $self->test_files( qw( xt/slow ) );
    $self->recursive_test_files( 1 );
    $self->depends_on('test');

}

sub ACTION_testall {
    my ($self) = @_;

    $self->depends_on('build');
    local $ENV{ RELEASE_TESTING } = 1;
    $self->test_files( qw( t xt ) );
    $self->recursive_test_files( 1 );
    $self->depends_on('test');

}

sub ACTION_distdir {
    my ($self) = @_;

    $self->depends_on('testrelease');

    return $self->SUPER::ACTION_distdir();

}

END_OF_CODE
);
my $builder = $subclass->new(
    module_name         => 'ModelSEED',
    dist_abstract       => "Core libraries for the ModelSEED",
    license             => 'perl',
    dist_author         => q{Chris Henry <cshenry@mcs.anl.gov>},
    dist_version_from   => 'lib/ModelSEED/Version.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        "Graph" => 0,
        "App::Cmd" => 0,
        "autodie" => 0,
        "Bash::Completion" => 0,
        "Bash::Completion::Plugin::Test" => 0,
        "Class::Autouse" => 0,
        "Clone" => 0,
        "Config::Tiny" => 0,
        "Data::UUID" => 0,
        "DateTime" => 0,
        "Devel::Size" => 0,
        "Exception::Class" => 0,
        "File::Copy::Recursive" => 0,
        "File::Path" => "2.08",
        "HTTP::Message" => 0,
        "IO::Interactive::Tiny" => 0,
        "IO::Compress::Gzip" => 0,
        "IO::Uncompress::Gunzip" => 0,
        "JSON::XS" => 0,
        "JSON::RPC::Client" => 0,
        "LWP" => 0,
        "Module::Load" => 0,
        "Module::Util" => 0,
        "Moose" => 0,
        "Term::ReadKey" => 0,
        "Test::Deep" => 0,
        "Test::More" => 0,
        "Tie::IxHash" => 0,
        "Try::Tiny" => 0,
        "URI" => 0,
        "URI::Split" => 0,
        "XML::LibXML" => 0,
        "XML::SAX::Base" => 0,
        "YAML" => 0,
        "common::sense" => 0,
        "namespace::autoclean" => 0,
        "XML::DOM" => 0,
    },
    recommends => {
        MongoDB => 0,
    },
    recursive_test_files => 1,
    add_to_cleanup      => [ 'ModelSEED-*' ],
    create_makefile_pl => 'traditional',
    script_files => [qw( bin/ms bin/mapping bin/genome bin/stores bin/model bin/bio )],
    kbase_files => {qw(
        kbase/Bio/KBase/CDMI/Client.pm      lib/Bio/KBase/CDMI/Client.pm
        kbase/Bio/KBase/fbaModel/Data.pm    lib/Bio/KBase/fbaModel/Data.pm
        kbase/Bio/KBase/workspaceService.pm lib/Bio/KBase/workspaceService.pm
    )},
);
$builder->add_build_element('kbase');
$builder->create_build_script();
