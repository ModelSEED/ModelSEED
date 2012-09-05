#!/usr/bin/perl 
use strict;
use warnings;
use lib 'lib';
use Test::More;
use Module::Pluggable search_path => ['ModelSEED'];
use Module::Util qw( :all );
# Test for common pod errors not caught by pod.t
# Errors tested for:
#  - =pod or =head with no newline before
#  - =cut with no newline before or after

sub test {
    my $module = shift;
    my $rtv = test_pod($module);
    if(defined $rtv) {
        ok 0, "$module : $rtv";
    } else {
        ok 1, "$module";
    }
}

sub test_pod {
    my $module = shift;
    my $filename = find_installed $module;
    open(my $fh, "<", $filename) || die "Error opening $filename: $!";
    my ($prev, $next);
    while ( <$fh> ) { 
        my $line = $_;
        if ($next && $_ !~ m/^\s*$/) {
            return "=cut should be followed by an empty line (Line $.)";
        } else {
            $next = 0;
        }
        if ($line =~ m/^=pod/ && $prev !~ m/^\s*$/ ) {
            return "=pod should be proceeded by a empty line (Line $.)";
        }
        if ($line =~ m/^=head/ && $prev !~ m/^\s*$/ ) {
            return "=head should be proceeded by a empty line (Line $.)";
        }
        if ($line =~ m/^=cut/ && $prev !~ m/^\s*$/ ) {
            return "=cut should be proceeded by empty line (Line $.)";
        }
        $next = 1 if ($line =~ m/^=cut/);
        $prev = $line;
    }
    close($fh);
    return undef;
}

my $testCount = 0;
test $_ for __PACKAGE__->plugins;
done_testing(scalar (__PACKAGE__->plugins) );
