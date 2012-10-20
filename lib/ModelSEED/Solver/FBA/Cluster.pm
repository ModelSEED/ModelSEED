package ModelSEED::Solver::FBA::Cluster;
use strict;
use common::sense;
use Module::Load qw(load);
use Moose;

has 'store' => ( is => 'rw', isa => 'ModelSEED::Store', required => 1 );
has 'cluster' => ( is => 'rw', isa => 'KBase::ClusterService', builder => '_build_cluster' );

sub start {
    my ($self, $fbaFormulation) = @_;
    my $args = {
        application => "fba",
        fbaFormulation => $fbaFormulation->toJSON,
    };
    my $job = $self->cluster->Submit($args);
    my $token = $job->{ID};
    return $token;
}

sub stop {
    my ($self, $token) = @_;
    my $job = $self->cluster->Job($token, $self->cluster);
    return $self->cluster->Cancel($job);
}

sub done {
    my ($self, $token) = @_;
    my $job = $self->cluster->Job($token, $self->cluster);
    return $self->cluster->Done($job);
}

sub getResults {
    my ($self, $token) = @_;
    my $job = $self->cluster->Job($token, $self->cluster);
    my $fbaFormulation = $self->cluster->GetParam($job, "fbaFormulation");
    my $uuid = $fbaFormulation->uuid;
    return $self->store->get_object("fBAFormulation/$uuid");
}

sub _build_cluster {
    my $class = 'KBase::ClusterService';
    load $class;
    return $class->new;
}

1;
