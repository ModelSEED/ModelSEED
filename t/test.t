# Tests for ModelSEED::Test - the test constructor framework
use strict;
use warnings;
use ModelSEED::Test;
use Data::Dumper;
use Test::More;
use Try::Tiny;
my $test_count = 0;

my $t = ModelSEED::Test->new;
# Test basic types are constructed
ok defined $t;
ok $t->config->isa('ModelSEED::Configuration');
ok $t->db->does('ModelSEED::Database');
ok $t->store->isa('ModelSEED::Store');
ok $t->auth->does("ModelSEED::Auth");
$test_count += 5;

# Test for data
my $store = $t->store;
print Dumper $store->get_aliases();

done_testing($test_count);
