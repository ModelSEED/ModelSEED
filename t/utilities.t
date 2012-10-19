# Tests for ModelSEED::utilities
use strict;
use warnings;
use Test::More;
use Test::Exception;
BEGIN {
    my @imports = qw( args error usage set_verbose verbose );
    use_ok('ModelSEED::utilities', @imports);
}
my $test_count = 1;

# Test args function
{
    # Test good cases with input as list and array
    is_deeply args(["a"], {}, "a", 1), { a => 1 };
    is_deeply args([], { a => 2 }, "a", 1), { a => 1 };
    is_deeply args([], { a => 2 }), { a => 2 };
    is_deeply args([], { a => 2 }, "b", 3), { a => 2, b => 3 };

    # Test good cases within a function
    sub foo { return args(["a"], { b => 3 },  @_); }
    is_deeply foo(a => 1), { a => 1, b => 3 };
    is_deeply foo({a => 1}), { a => 1, b => 3 };
    is_deeply foo(b => 2, a => 1), { a => 1, b => 2 };

    # Test bad cases
    dies_ok { args(["c"], {}, ()) };
    dies_ok { args(["c"], { c => 1 }, {}) };
    dies_ok { args(["c"], {}, { b => 1 }) };
    dies_ok { args(["c"], {}, { c => undef }) };
    dies_ok { args([], {}, "a") };

    $test_count += 12; 
}

# Test verbose function
{
    # Test caller and setter when not set
    is verbose("foo"), 0;     
    is verbose("bar", "bin"), 0;
    is set_verbose(), undef;
    is set_verbose({}), undef;
    is set_verbose([]), undef;
    is set_verbose(""), undef;
    is set_verbose(undef), undef; 
    $test_count += 7;

    # Test caller and setter when set
    {
        my $stderr;
        local *STDERR;
        open(STDERR, ">", \$stderr);
        is set_verbose(1), \*STDERR;
        is verbose("foo"), 1;
        is verbose("bar", "bin"), 1;
        is verbose(), 1;
        is $stderr, "foobarbin";
        $test_count += 5;
        close(STDERR);
    }
    # Now test unsetting
    is set_verbose(undef), undef;
    is verbose(), 0;
    $test_count += 2; 
}

done_testing($test_count);
