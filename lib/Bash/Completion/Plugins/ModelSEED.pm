########################################################################
# Bash::Completion::Plugins::ModelSEED
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development locations:
#   Mathematics and Computer Science Division, Argonne National Lab;
#   Computation Institute, University of Chicago
#
# Date of module creation: 2012-09-13
########################################################################
package Bash::Completion::Plugins::ModelSEED;
use strict;
use common::sense;
use Bash::Completion::Utils qw( command_in_path prefix_match );
use ModelSEED::Bash::Completion::Rules;
use ModelSEED::Configuration;
use JSON::XS;
use File::stat;
use parent 'Bash::Completion::Plugin';

sub should_activate {
    if ( command_in_path('ms') )  {
        return [ qw( ms stores bio mapping genome model ) ];
    } else {
        return [];
    }
}

sub generate_bash_setup { 
    return [qw(nospace default)];
}

our $rules = $ModelSEED::Bash::Completion::Rules::rules;
our $conf  = ModelSEED::Configuration->instance;
our $MAX_CACHE_AGE = 60; # Age in seconds for a valid ~/.modelseed_bash_completion_cache file

sub complete {
    my ($self, $r) = @_;
    my @args = $r->args;
    # Process each arg until we get to the end of the array
    # where we will be in $state with available completions
    my ($stateName, $state);
    while (@args >= 0) {
        # First round, set state == first argument
        if(!defined $stateName) { 
            my $curr = shift @args;
            $stateName = $curr if defined $rules->{$curr};
            return unless defined $stateName;
        }
        $state = $rules->{$stateName};
        my $newStateName;
        # Try to follow an edge, if we do go to the top
        # of this while loop, consuming an arg off @args
        foreach my $edge (@{$state->{edges}}) {
            $newStateName = processEdge($edge, \@args);
            if(defined $newStateName) {
                $stateName = $newStateName;
                last;
            } 
        }
        next if $newStateName;
        # We didn't consume an edge, so produce
        # @candidates to return to the user
        my @candidates;
        foreach my $completionRule (@{$state->{completions}}) {
            my @completions = processCompletionRule($completionRule, $r);
            push(@candidates, @completions);

        }
        # pass candidates to request object and return
        $r->candidates(@candidates);
        return;
    }
}

sub processEdge {
    my ($edge, $args) = @_;
    # An edge can be one of two things:

    # 1. tuple where: the first element
    # is a string that must be matched exactly
    # and the second element is the new state name
    # e.g. [ 'login', 'ms_login' ]
    if (ref($edge) eq 'ARRAY') {
        my $first = $args->[0];
        if($first eq $edge->[0]) {
            # We matched, consume the arg and
            # return the new state name
            shift @$args;
            return $edge->[1];
        }
    # 2. A hash with keys 'regex' and 'state', where you
    #    must only do a regex match on that...
    } elsif (ref($edge) eq 'HASH') {
        die "TODO: bash_completion regex matching";
    } 
    return undef;
}

sub processCompletionRule {
    my ($rule, $r) = @_;
    # Rule may be:
    #     1. An array of strings, just return these strings as candidates
    #     2. A hash key "prefix". If the current option has the prefix,
    #     there are two cases depending on what other key is defined: 
    #       a. If "options" is defined, return that list of option strings + prefix
    #       b. If "cmd" is defined, run that command and return the candidates
    # 
    if (ref($rule) eq 'ARRAY') {
        return prefix_match($r->word, @$rule);
    }
    if(ref($rule) eq 'HASH' && defined $rule->{prefix}) {
        my $prefix = $rule->{prefix};
        my $match  = $r->word =~ m/^$prefix/;
        if ($match && defined $rule->{options}) {
            my @candidates = map { $rule->{prefix} . $_ } @{$rule->{options}}; 
            return prefix_match($r->word, @candidates);
        } elsif($match && defined($rule->{cmd})) {
            return processCmdRule($rule, $r);
        }
    }
    return ();
}

sub processCmdRule {
    my ($rule, $r) = @_;
    my $cmd = $rule->{cmd};
    my $tmp_file = $conf->filename . "_bash_completion_cache";
    my $data = _read_json_file($tmp_file);
    if(defined($data->{$cmd})) {
        return prefix_match($r->word, @{$data->{$cmd}});
    } else {
        my @candidates = split(/\n/, `$cmd`);
        $data->{$cmd} = \@candidates;
        _write_json_file($tmp_file, $data);
        return prefix_match($r->word, @candidates);
    }
}

sub _read_json_file {
    my ($filename) = @_;
    return {} unless -f $filename;
    open(my $fh, "<", $filename) || return {};
    my $cacheAge = time - stat($fh)->mtime;
    if ($cacheAge > $MAX_CACHE_AGE) {
        close($fh);
        return {};
    }
    local $\;
    my $str = <$fh>;
    close($fh);
    return decode_json $str;
}

sub _write_json_file {
    my ($filename, $data) = @_;
    my $str = encode_json $data;
    open(my $fh, ">", $filename) || return;
    print $fh $str;
    close($fh);
}

1;
