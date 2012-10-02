package ModelSEED::App::mseed::Command::config;
use strict;
use common::sense;

use ModelSEED::Configuration;

use base 'App::Cmd::Command';

sub abstract { "Configure the ModelSEED environment" }
sub usage_desc { "ms config key=value" }

sub opt_spec {
    return (
        ["list|l", "List the values for the given variables"],
        ["remove|r", "Remove the given variables."],
        ["help|h|?", "Print this usage information"],
    );
}

sub execute {
    my ($self, $opts, $args) = @_;
    print($self->usage) && return if $opts->{help};
    my $config = ModelSEED::Configuration->new();
    my $pos_user_opts = $config->possible_user_options();
    my $user_opts = $config->user_options();

    if ($opts->{list} && $opts->{remove}) {
        print STDERR "Cannot specify both 'list' and 'remove' options.\n";
        return;
    } elsif ($opts->{list} || $opts->{remove}) {
        # make sure the variables exist in user_options
        foreach my $arg (@$args) {
            unless (exists($pos_user_opts->{$arg})) {
                print STDERR "Error, unknown option: '$arg'.\n";
                return;
            }
        }

        # now process
        if ($opts->{list}) {
            if (scalar @$args == 0) {
                # list all
                foreach my $opt (sort keys %$user_opts) {
                    my $val = $user_opts->{$opt};
                    print "$opt: '" . $val . "'";
                    if ($val eq $pos_user_opts->{$opt} && $val ne "") {
                        print " (default)";
                    }
                    print "\n";
                }
            } else {
                # list specific
                foreach my $arg (@$args) {
                    my $val = $user_opts->{$arg};
                    print "$arg: '" . $val . "'";
                    if ($val eq $pos_user_opts->{$arg} && $val ne "") {
                        print " (default)";
                    }
                    print "\n";
                }
            }
        } else {
            if (scalar @$args == 0) {
                print STDERR "Error, no options specified.\n";
                return;
            } else {
                foreach my $arg (@$args) {
                    if (defined($pos_user_opts->{$arg})) {
                        $user_opts->{$arg} = $pos_user_opts->{$arg};
                    } else {
                        delete $user_opts->{$arg};
                    }
                }
            }

            $config->save();
        }
    } else {
        # trying to set option(s)
        if (scalar @$args == 0) {
            # print usage
            print "Usage: ms config [-l|-r] OPTION[=value]\n";
            print "  e.g. ms config ERROR_DIR=/home/ms/errors\n";
            print "       ms config -r ERROR_DIR\n";
            return;
        }

        # make sure all options exist and are valid
        my $vars = [];
        foreach my $arg (@$args) {
            my ($var, $val) = split('=', $arg);
            unless (defined($var) && defined($val)) {
                print STDERR "Error, incorrect option usage (syntax: OPTION=value).\n";
                return;
            }

            unless (exists($pos_user_opts->{$var})) {
                print STDERR "Error, unknown option: '$var'.\n";
                return;
            }

            $val = $config->validate_user_option($var, $val);

            unless (defined($val)) {
                print STDERR "Error with option: $var=$val\n";
                return;
            }

            push(@$vars, [$var, $val]);
        }

        # set the options
        foreach my $var (@$vars) {
            $user_opts->{$var->[0]} = $var->[1];
        }

        $config->save();
    }
}

1;
