use strict;
use warnings;
use Test::More;
# Tests for MS::Biomass object
use ModelSEED::MS::Biochemistry;
use ModelSEED::MS::Model;
use ModelSEED::MS::Biomass;
my $test_count = 0;

# Test index and id functions (this requires a model)
{
    my $biochemistry = ModelSEED::MS::Biochemistry->new;
    my $model = ModelSEED::MS::Model->new(
        id => "foo",
        biochemistry_uuid => $biochemistry->uuid,
    );
    ok defined $model;
    $test_count += 1;

    {
        my $biomass1 = ModelSEED::MS::Biomass->new;
        $model->add("biomasses", $biomass1);
        is scalar @{$model->biomasses}, 1;
        is $biomass1->index, 1;
        is $biomass1->id, "bio00001";

        $test_count += 3;
    }

    {
        my $biomass2 = ModelSEED::MS::Biomass->new;
        $model->add("biomasses", $biomass2);
        is scalar @{$model->biomasses}, 2;

        is $biomass2->index, 2;
        is $biomass2->id, "bio00002";
        $test_count += 3;

    }

    {
        my $biomass1 = $model->biomasses->[0];
        is $biomass1->index, 1;
        is $biomass1->id, "bio00001";
        $test_count += 2;
    }
}

# Test _parse_equation_string
{
    my $biomass = ModelSEED::MS::Biomass->new;
    my $three_parts = <<STRINGS;
(1) a + 2 b <= c
aas123 + 3.48 b <=> c
(1.23) a + (3.42) b => 32.101 c
(2.342) a + (343) b = (13) c
STRINGS
    $three_parts = [ split(/\n/, $three_parts) ];
    foreach my $part (@$three_parts) {
        my $reagents = $biomass->_parse_equation_string($part);
        is @$reagents, 3, "got three reagents from $part";
        $test_count += 1;

        foreach my $reagent (@$reagents) {
            is $reagent->{compartment}, "c0";
            $test_count += 1;
        }
    }
    # Test newline
    my $nl = "a[x] + \n(2.34) b\n\n <=> (22.1) c";
    my $reagent_nl = $biomass->_parse_equation_string($nl);
    is @$reagent_nl, 3, "got there parts from equation with newlines";

    $test_count += 1;
}
done_testing($test_count);

