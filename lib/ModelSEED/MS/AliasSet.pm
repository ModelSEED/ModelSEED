########################################################################
# ModelSEED::MS::AliasSet - This is the moose object corresponding to the AliasSet object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-06-01T07:31:01
########################################################################
use strict;
use ModelSEED::MS::DB::AliasSet;
package ModelSEED::MS::AliasSet;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::DB::AliasSet';
#***********************************************************************************************************
# ADDITIONAL ATTRIBUTES:
#***********************************************************************************************************
has aliasesByuuid => ( is => 'rw', isa => 'HashRef',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildaliasesByuuid' );


#***********************************************************************************************************
# BUILDERS:
#***********************************************************************************************************
sub _buildaliasesByuuid {
	my ($self) = @_;
	my $hash = {};
	my $aliases = $self->aliases();
	foreach my $alias (keys(%$aliases)) {
		foreach my $uuid (@{$aliases->{$alias}}) {
			push(@{$hash->{$uuid}},$alias);
		}	
	}
	return $hash;
}


#***********************************************************************************************************
# CONSTANTS:
#***********************************************************************************************************

#***********************************************************************************************************
# FUNCTIONS:
#***********************************************************************************************************
sub addAlias {
	my ($self,$alias,$uuid) = @_;
	my $aliases = $self->aliases();
	if (defined($aliases->{$alias})) {
		my $uuids = $aliases->{$alias};
		for (my $i=0; $i < @{$uuids}; $i++) {
			if ($uuids->[$i] eq $uuid) {
				return;	
			}
		}
	}
	push(@{$aliases->{$alias}},$uuid);
	my $aliasesByuuid = $self->aliasesByuuid();
	push(@{$aliasesByuuid->{$uuid}},$alias);
}

sub removeAlias {
	my ($self,$alias,$uuid) = @_;
	my $aliases = $self->aliases();
	if (defined($aliases->{$alias})) {
		my $uuids = $aliases->{$alias};
		for (my $i=0; $i < @{$uuids}; $i++) {
			if ($uuids->[$i] eq $uuid) {
				splice(@{$aliases->{$alias}}, $i, 1);
				$i--;
			}
		}
	}
	my $aliasesByuuid = $self->aliasesByuuid();
	for (my $i=0; $i < @{$aliasesByuuid->{$uuid}}; $i++) {
		if ($aliasesByuuid->{$uuid}->[$i] eq $alias) {
			splice(@{$aliasesByuuid->{$uuid}}, $i, 1);
			$i--;
		}
	}
}

__PACKAGE__->meta->make_immutable;
1;
