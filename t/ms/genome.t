# Tests for Genome object
use strict;
use warnings;
use ModelSEED::Test;
use Test::More;
my $test_count = 0;
my $t = ModelSEED::Test->new;
my $anno = $t->store->get_object("annotation/alice/testdb");
ok defined $anno;
my $genome = $anno->genomes->[0];
ok defined $genome;
$test_count += 2;

# Test several functions
{
    my $cmps = $genome->compartments;
    ok @$cmps > 0;
    my $features = $genome->features;
    ok @$features > 0;
    my $ftr_by_role = $genome->featuresByRole;
    ok keys %$ftr_by_role > 0;
    $test_count += 3;
}

done_testing($test_count);
