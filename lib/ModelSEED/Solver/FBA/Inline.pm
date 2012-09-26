package ModelSEED::Solver::FBA::Inline;
use strict;
use common::sense;
use Moose;

has 'store' => ( is => 'rw', isa => 'ModelSEED::Store' );

# Block on runFBA, returning only when done
sub start {
    my ($self, $fbaFormulation) = @_;
    my $results = $fbaFormulation->runFBA(); 
    my $token = "fBAFormulation/".$fbaFormulation->uuid;
    $self->store->save_data($token, $fbaFormulation);
    return $token;
}

sub stop { return; }

sub done {
    my ($self, $token) = @_;
    return $self->store->has_data($token);
}

sub getResults {
    my ($self, $token) = @_;
    return $self->store->get_object($token);
}

1;
