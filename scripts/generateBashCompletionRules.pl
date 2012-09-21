#!/usr/bin/perl 
use strict;
use warnings;
use Module::Load;
use Test::More tests => 4;
use Test::Deep;
use JSON::XS;
use Data::Dumper;
use Try::Tiny;

my %topLevelCommands = qw(
    ms ModelSEED::App::mseed
    stores ModelSEED::App::stores
    bio ModelSEED::App::bio
    mapping ModelSEED::App::mapping
    genome ModelSEED::App::genome
    model ModelSEED::App::model
);
my %innerCommands = qw(
    import ModelSEED::App::import
);

my %linkedCommands = qw(
    ms import
    ms stores
    ms bio
    ms mapping
    ms genome
    ms model
);
my $linkedCommands = {
    ms => {
        map { $_ => 1 } qw( import stores bio mapping genome model )
    },
};


sub process_app {
    my ($states, $app, $app_pkg, $linked_app_cmds) = @_;
    load $app_pkg;
    my @plugins = $app_pkg->command_plugins;
    my ($edges, $completions) = ( [], [] );
    my $basic_completion = [];
    my $state = { edges => $edges, completions => $completions };
    foreach my $cmd_pkg (@plugins) {
        my @commands = $cmd_pkg->command_names;
        my $command = $commands[0];
        if(defined $linked_app_cmds->{$app}->{$command}) {
            push(@$edges, [ $command, "$command" ]);
            push(@$basic_completion, $command);
        } else {
            my $command_state = "${app}_$command";
            push(@$edges, [ $command, $command_state] );
            push(@$basic_completion, $command);
            process_command($states, $app, $command, $app_pkg, $cmd_pkg);
        }
    }
    if(@$basic_completion) {
        push(@$completions, $basic_completion);
    }
    $states->{$app} = $state;
}

sub process_command {
    my ($states, $app, $cmd, $app_pkg, $cmd_pkg) = @_;
    my $state_name = "${app}_$cmd";
    my ($edges, $completions) = ( [], [] );
    my $state = { edges => $edges, completions => $completions };
    # do options
    my @options = $cmd_pkg->opt_spec;
    my $option_completions = [];
    my $simple_completions = [];
    foreach my $option (@options) {
        my $str = $option->[0];
        # If we consume an additional arg
        if ($str =~ m/[:=]/) {
            my ($keys, $type) = split(/[:=]/, $str); 
            my @keys = split(/\|/, $keys);
            push(@$option_completions, $keys[0]);
            # do command_option sub-state 
        } else {
            my @keys = split(/\|/, $str);
            push(@$option_completions, $keys[0]);
        }
    }
    if(@$simple_completions != 0) {
        push(@$completions, $simple_completions);
    }
    if(@$option_completions != 0) {
        push(@$completions, { "prefix" => "--", "options" => $option_completions });
    }
    # do arguments
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

my $states = {};
foreach my $cmd ( keys %topLevelCommands) {
    my $pkg = $topLevelCommands{$cmd};
    process_app($states, $cmd, $pkg, $linkedCommands);
}
foreach my $cmd ( keys %innerCommands) {
    my $pkg = $innerCommands{$cmd};
    process_app($states, $cmd, $pkg, $linkedCommands);
}

print Dumper $states;

=head3 fsm

    [
        "ms" : {
            "edges" : [
                [ "stores", "stores" ],
                [ "bio", "bio" ]
                [ "list", "ms_list" ],
             ],
             "completions" : [
                [ "stores" , "bio", "foo", "biochemistry" ],
                { "prefix" : "biochemistry", "cmd" : 'ms list biochemistry' },
        },
        "ms_list" : {
            "edges" : [
                [ "-w", "ms_list--with" ],
            ],
            "completions" : [
                [ "--with", "--help", "--no_ref" ],
                { "prefix" : "", "options" : [ "biochemistry/", "mapping/", "model/", "annotation/" ] },
                { "prefix" : "biochemistry/", "cmd" : 'ms list biochemistry' }
            ],
        },
        "ms_list--with" : {
            "edges" : [
                { "regex" : "m/.+\s/", "to" : "ms_list", "c" : 1 }
            ],
            "completions" : []
        }
}

# edges : an array of edge, iterate through all until match one
#     edge may be :
#         an array where 0 is an exeact string to match, 1 is the state to jump to, consume 1.
#         a hash :
#             "has key regex" : match on regex, go to "to" node, consuming "c" args
#   
# completions : an array of completion generators, return the subset of all that prefix-match:
#      a completion generator may be :
#          an array, just return that shit
#          a hash :
#              "has key prefix" : if we match on prefix, then...
#                   "has key options" : add the array of options to the set to match against (useful?)
#                   "has key cmd" : run this command and include the results in the match set

# doing top-level :
#     state name is cmd
#     edges : subcommands "cmd_subcommand"
#           if subcommand simply "redirects" to top-level command... edge is cmd
#     completions : top-level options, subcommands

# doing subcommands:
#     state name is cmd_subcommand
#     edges : option with string
#     completions : options, argument generators
