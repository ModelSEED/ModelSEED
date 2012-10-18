#!/usr/bin/perl 

=head1 generateBashCompletion.pl

=cut

use strict;
use warnings;
use Module::Load;
use JSON::XS;
use Data::Dumper;
use Try::Tiny;
use Cwd 'abs_path';

# This is the mapping of command-name => App::Cmd package.
# We generate bash-completion rules for each package and associate
# the top-level entry with the command-name.
my %appCmds = qw(
    ms ModelSEED::App::mseed
    stores ModelSEED::App::stores
    bio ModelSEED::App::bio
    mapping ModelSEED::App::mapping
    genome ModelSEED::App::genome
    model ModelSEED::App::model
    import ModelSEED::App::import
);
# This establishes how top-level commands are tied to other
# top-level commands. In this case, ms links to each of these subcommands
my $linkedCommands = {
    ms => {
        map { $_ => 1 } qw( import stores bio mapping genome model )
    },
};

my $filename;
if (@ARGV) {
    $filename = shift @ARGV;
    run($filename);
} else {
    # Must include a file, probably want this as the filename:
    my $expected = abs_path($0);
    $expected    =~ s/\/[^\/]*$/\//;
    $expected   .= "/../lib/ModelSEED/Bash/Completion/Rules.pm";
    $expected    = abs_path($expected);
    warn "Usage: $0 output-file\nFile probably should be: $expected\n";

}

sub process_app {
    my ($states, $app, $app_pkg, $linked_app_cmds) = @_;
    load $app_pkg;
    # Get the "commands" for the app
    my @plugins = $app_pkg->command_plugins;
    my ($edges, $completions) = ( [], [] );
    my $basic_completion = [];
    my $state = { edges => $edges, completions => $completions };
    foreach my $cmd_pkg (@plugins) {
        # Take the first command out of the command names
        my @commands = $cmd_pkg->command_names;
        my $command = $commands[0];
        if(defined $linked_app_cmds->{$app}->{$command}) {
            # If we registered a "linked_app" e.g. 'ms import'
            # put a link to the top-level app name e.g. 'import'
            # and add the command to the basic completions
            push(@$edges, [ $command, "$command" ]);
            push(@$basic_completion, $command);
        } else {
            # Otherwise define a new state "app_command", e.g. "ms_login"
            # and push that state name onto the edges, the completion onto
            # the basic compeltions, then process that command (adding additional
            # states)
            my $command_state = "${app}_$command";
            push(@$edges, [ $command, $command_state] );
            push(@$basic_completion, $command);
            process_command($states, $app, $command, $app_pkg, $cmd_pkg);
        }
    }
    # Don't add completions unless we have some
    if(@$basic_completion) {
        push(@$completions, $basic_completion);
    }
    # Add this state to the states now...
    $states->{$app} = $state;
}

sub process_command {
    my ($states, $app, $cmd, $app_pkg, $cmd_pkg) = @_;
    # Our state name is app_cmd e.g. 'ms_login'
    my $state_name = "${app}_$cmd";
    my ($edges, $completions) = ( [], [] );
    my $state = { edges => $edges, completions => $completions };
    # produce completions and states for each option
    my @options = $cmd_pkg->opt_spec;
    my $option_completions = [];
    my $simple_completions = [];
    foreach my $option (@options) {
        my $str = $option->[0];
        if ($str =~ m/[:=]/) {
            # If we consume an additional arg
            my ($keys, $type) = split(/[:=]/, $str); 
            my @keys = split(/\|/, $keys);
            push(@$option_completions, $keys[0]);
            # TODO: bash completion: do command_option sub-states
        } else {
            # Put the option onto the completions
            my @keys = split(/\|/, $str);
            push(@$option_completions, $keys[0]);
        }
    }
    if(@$simple_completions != 0) {
        push(@$completions, $simple_completions);
    }
    # Option completions only happen if you add the "--" on the command
    if(@$option_completions != 0) {
        push(@$completions, { "prefix" => "--", "options" => $option_completions });
    }
    # Now process arguments, this requires an "arg_spec" function in the Command
    my @arg_states;
    try {
        @arg_states = $cmd_pkg->arg_spec();
    };
    for(my $i=0; $i<@arg_states; $i++) {
        # for now, just push completions onto this state's completions
        my $arg_state = $arg_states[$i];
        push(@$completions, @{$arg_state->{completions}});
    }
    $states->{$state_name} = $state;
}

sub run {
    my ($filename) = @_;
    my $states = {};
    foreach my $cmd ( keys %appCmds) {
        my $pkg = $appCmds{$cmd};
        process_app($states, $cmd, $pkg, $linkedCommands);
    }
    # Construct a package at filename
    my $str = Dumper $states;
    $str =~ s/\$VAR1/our \\\$RULES/;
    my $tmpl = <<HEREDOC;
=head1 ModelSEED::Bash::Completion::Rules

Rules for performing bash-completion steps. This
package is consumed by L<Bash::Completion::Plugin::ModelSEED>
THIS IS AN AUTOMATICALLY GENERATED PACKAGE. DO NOT EDIT. See
"Rebuilding" for instructions to regenerate this package.

=head2 rules

This function returns the bash completion rules.

=head2 Rebuilding

See scripts/generateBashCompletionRules for instructions
on rebuilding this module.

=cut

package ModelSEED::Bash::Completion::Rules;
use strict;
use warnings;

$str;
sub rules {
    return \\\$RULES;
}
1;
HEREDOC
    # Tidy it up a bit:
    $tmpl = `echo "$tmpl" | perltidy`;
    open(my $fh, ">", $filename) || die "Could not open $filename: $!";
    print $fh $tmpl;
    close($fh);
}
