use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'ModelSeedCore',
    dist_abstract       => "Core libraries for the Model SEED",
    license             => 'perl',
    dist_author         => q{Chris Henry <cshenry@mcs.anl.gov>},
    dist_version_from   => 'lib/ModelSEED/Version.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
        "App::Cmd" => 0,
        "autodie" => 0,
        "Class::Autouse" => 0,
        "Clone" => 0,
        "Config::Tiny" => 0,
        "Data::UUID" => 0,
        "DateTime" => 0,
        "Devel::Size" => 0,
        "Exception::Class" => 0,
        "File::Copy::Recursive" => 0,
        "HTTP::Message" => 0,
        "JSON::XS" => 0,
        "JSON::Any" => 0,
        "JSON::RPC::Client" => 0,
        "LWP" => 0,
        "Moose" => 0,
        "Term::ReadKey" => 0,
        "Test::Deep" => 0,
        "Test::More" => 0,
        "Tie::IxHash" => 0,
        "Try::Tiny" => 0,
        "URI" => 0,
        "XML::LibXML" => 0,
        "XML::SAX::Base" => 0,
        "YAML" => 0,
        "common::sense" => 0,
        "namespace::autoclean" => 0,
    },
    recommends => {},
    recursive_test_files => 1,
    add_to_cleanup      => [ 'ModelSeedCore-*' ],
    create_makefile_pl => 'traditional',
    script_files => [qw( bin/ms bin/mapping bin/genome bin/stores bin/model bin/bio )],
);

$builder->create_build_script();
