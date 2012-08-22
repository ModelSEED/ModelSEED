use strict;
use warnings;

use FindBin qw($Bin);

# This script reads config variables from the command line
#  and writes them to lib/ModelSEED/PackageConfig.pm
#   * DIST_TYPE - distribution type ('user' or 'dev')
#   * INSTALL_DIR - installation directory (for user dist_type)
#   * BIN_SCRIPTS - list of binary scripts that were installed (used for uninstallation)

my $conf_file = "$Bin/../lib/ModelSEED/PackageConfig.pm";

my $args = {};
foreach my $arg (@ARGV) {
    my ($var, $val) = split('=', $arg);
    unless (defined($var) && defined($val)) {
        warn "Argument not in valid form (var=val): '$arg'";
        next;
    }

    $args->{$var} = $val;
}

my $file = [];
push (@$file, "package ModelSEED::PackageConfig;");
push (@$file, "");
map { push(@$file, '$' . $_ . "='" . $args->{$_} . "';") } sort keys %$args;
push (@$file, "");
push (@$file, "1;");
push (@$file, "");

open CONF, ">$conf_file" or die "Couldn't open config file ($conf_file): $!";
print CONF join("\n", @$file);
close CONF;
