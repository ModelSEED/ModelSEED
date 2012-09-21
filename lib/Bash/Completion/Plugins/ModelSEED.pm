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
use parent 'Bash::Completion::Plugin';

sub should_activate {
    if ( command_in_path('ms') )  {
        return [ qw( ms stores bio mapping genome model ) ];
    } else {
        return [];
    }
}

our $rules = $ModelSEED::Bash::Completion::Rules::rules;
sub complete {
    my ($self, $r) = @_;
    my @args = $r->args;
    my ($stateName, $state);
    while (@args >= 0) {
        if(!defined $stateName) { 
            my $curr = shift @args;
            $stateName = $curr if defined $rules->{$curr};
            return unless defined $stateName;
        }
        $state = $rules->{$stateName};
        my $newStateName;
        foreach my $edge (@{$state->{edges}}) {
            $newStateName = processEdge($edge, \@args);
            if(defined $newStateName) {
                $stateName = $newStateName;
                last;
            } 
        }
        next if $newStateName;
        my @candidates;
        #warn "doing completions for $stateName\n";
        foreach my $completionRule (@{$state->{completions}}) {
            my @completions = processCompletionRule($completionRule, $r);
            push(@candidates, @completions);

        }
        $r->candidates(@candidates);
        return;
    }
}

sub processEdge {
    my ($edge, $args) = @_;
    # Array : [ 'exact_match', 'new-state' ]
    if (ref($edge) eq 'ARRAY') {
        my $first = $args->[0];
        if($first eq $edge->[0]) {
            shift @$args; # consume this arg
            return $edge->[1];
        }
    # Hash : { 'regex' => qr{}, 
    } elsif (ref($edge) eq 'HASH') {
        die "TODO";
    } 
    return undef;
}

sub processCompletionRule {
    my ($rule, $r) = @_;
    # Rule may be:
    #     An array, just return these candidates
    #     A hash, with key "prefix"
    # 
    if (ref($rule) eq 'ARRAY') {
        return prefix_match($r->word, @$rule);
    }
    if(ref($rule) eq 'HASH' && defined $rule->{prefix}) {
        if (defined $rule->{options}) {
            my $prefix = $rule->{prefix};
            if($r->word =~ m/^$prefix/) {
                my @candidates = map { $rule->{prefix} . $_ } @{$rule->{options}}; 
                return prefix_match($r->word, @candidates);
            }
        } elsif(defined($rule->{cmd})) {
            die "TODO";
        }
    }
    return ();
}

1;
