use strict;
use warnings;
use Test::More;
# Tests for MS::BaseObject
use ModelSEED::MS::Compound;
my $test_count = 0;

# Testing constructor,serializeToDB,cloneObject function
{
    my $compound = ModelSEED::MS::Compound->new({
    	isCofactor => 0,
    	modDate => DateTime->now()->datetime(),
    	name => "test",
    	abbreviation => "test",
    	formula => "H2O",
    	mass => 18,
    	deltaG => 0,
    	deltaGErr => 0
    });
    my $data = $compound->serializeToDB();
    ok defined($data);
    $test_count++;
    my $cloneCpd = $compound->cloneObject();
    ok defined($cloneCpd);
    $test_count++;
    ok $cloneCpd->uuid() ne $compound->uuid();
    $test_count++;
}

done_testing($test_count);

