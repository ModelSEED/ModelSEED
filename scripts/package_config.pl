use strict;
use warnings;

# this script reads config variables from the command line and writes them to 
# lib/ModelSEED/PackageConfig.pm

my $pkg_conf_file = "../lib/ModelSEED/PackageConfig.pm";

my $args = {};
foreach my $arg (@ARGV) {
    my ($var, $val) = split('=', $arg);
    unless (defined($var) && defined($val)) {
        warn "Argument not in valid form (var=val): '$arg'";
        next;
    }

    $args->{$var} = $val;
}

my $skip = 0;
my $new_conf = [];
open CONF, "<$pkg_conf_file" or die "Couldn't open config file: $!";
while (<CONF>) {
    chomp;
    if ($_ =~ m/### BEGIN ###/) {
        $skip = 1;
        push(@$new_conf, "### BEGIN ###");
        push(@$new_conf, "");

        # now add the config variables
        foreach my $val (sort keys %$args) {
            push(@$new_conf, '$' . $val . "='" . $args->{$val} . "';");
        }
    } elsif ($_ =~ m/### END ###/) {
        $skip = 0;
        push(@$new_conf, "");
        push(@$new_conf, "### END ###");
    } elsif ($skip == 0) {
        push(@$new_conf, $_);
    }
}
close CONF;

push(@$new_conf, "");

open CONF2, ">$pkg_conf_file" . "2" or die "Couldn't open config file 2: $!";
print CONF2 join("\n", @$new_conf);
close CONF2;

rename $pkg_conf_file, $pkg_conf_file . ".bk" or die "Couldn't move old config file: $!";
rename $pkg_conf_file . "2", $pkg_conf_file or die "Couldn't move new config file: $!";
