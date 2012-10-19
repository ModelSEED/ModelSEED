# Tests for ModelSEED::Test - the test constructor framework
use strict;
use warnings;
use ModelSEED::Test;
use Data::Dumper;
use Test::More;
use Try::Tiny;
my $test_count = 0;

    my $t = ModelSEED::Test->new;
    ok defined $t;
    warn Dumper $t->db_config;
    ok $t->config->isa('ModelSEED::Configuration');
    ok $t->store->isa('ModelSEED::Store');
    ok $t->db->does('ModelSEED::Database');

$test_count += 4;

done_testing($test_count);
