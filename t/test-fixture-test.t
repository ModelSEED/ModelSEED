# Tests for ModelSEED::Test - the test constructor framework
use strict;
use warnings;
use ModelSEED::Test;
use ModelSEED::Auth::Basic;
use File::Path qw(rmtree);
use Data::Dumper;
use Test::More;
use Try::Tiny;
use File::Temp qw( tempfile );
my $test_count = 0;

# Remove the data-dir to test fetching at least once
{
    my $t  = ModelSEED::Test->new;
    my $dir = $t->_test_data_dir;
    rmtree $dir if ( -d $dir );
}
# Test case of stores containing an empty list:
{
    my $t = ModelSEED::Test->new;
    $t->config->config->{stores} = [];
    ok defined $t->db;
    $test_count += 1;
}

# Two helper functions ( shuffle an array, get a tempfile )
sub shuffle {
    my @keys = @_;
    my %map  = map { rand() => $_ } @keys;
    return map { $map{$_} } sort keys %map;
}

sub tempfilename {
    my ($fh, $tempfile) = tempfile();
    close($fh);
    return $tempfile;
}

# Randomize the order of accessing on a default object
# to test that each trigger initializes properly.
# Not the best way to do it, but easier than enumerating
# all possible combinations.

my $expect = {
    config => { isa  => 'ModelSEED::Configuration' },
    db     => { does => 'ModelSEED::Database' },
    store  => { isa  => 'ModelSEED::Store' },
    auth   => { does => 'ModelSEED::Auth' },
    config => { isa  => 'ModelSEED::Configuration' },

};

# basic_tests currently consumes the above $expect and
# calls things like $t->auth->does("ModelSEED::Auth");
sub basic_tests {
    my $t      = shift;
    my $expect = shift;
    foreach my $key (shuffle keys %$expect) {
        my $rule   = $expect->{$key};
        my ($type)  = keys %$rule;
        my ($class) = values %$rule;
        ok $t->$key->$type($class);
    }
    $test_count += scalar ( keys %$expect ) ;
}

# Call basic tests in random orders
# Need this because of trigger / builder complexity
foreach my $i (0..0) {
    my $t = ModelSEED::Test->new;
    ok defined $t;
    $test_count += 1;
    basic_tests($t, $expect);
}

# $ops is like $expect, except we do:
# $t->config_file($tempfilename);
# $t->clear_auth();
sub test_clears {
    my ($t, $old_data, $msg) = @_;
    foreach my $key (keys %$old_data) {
        isnt $t->$key, $old_data->{$key}, $msg;
    }
    $test_count += scalar( keys %$old_data );
}

sub mk_auth {
    return ModelSEED::Auth::Basic->new(username => "bob", password => "bob");
}

my $ops = {
    config_file => { args => [ \&tempfilename ] },
    clear_auth => { data => [ 'auth', 'store' ], test => \&test_clears },
    clear_store => { data => [ 'store' ], test => \&test_clears },
    clear_db => { data => [ qw(auth store db) ], test => \&test_clears },
    auth => { args => [ \&mk_auth ], data => [ qw(auth store) ], test => \&test_clears },
};

# Do each operation then call the getters in
# random orders.
foreach my $i (0..0) {
    foreach my $op (shuffle keys %$ops) {
        my $t = ModelSEED::Test->new;
        my $args = $ops->{$op}->{args};
        my $test = $ops->{$op}->{test};
        my $data = $ops->{$op}->{data};
        my $old_data = {};
        my $msg = "After doing $op\n";
        if (defined $data && @$data) {
            foreach my $f (@$data) {
                $old_data->{$f} = $t->$f();
            }
        }
        if (defined $args) {
            my @args = map { $_->() } @$args;
            $t->$op(@args);
            basic_tests($t, $expect);
        } else {
            $t->$op;
            basic_tests($t, $expect);
        }
        if (defined $test) {
            $test->($t, $old_data, $msg);
        }
    }
}

done_testing($test_count);
