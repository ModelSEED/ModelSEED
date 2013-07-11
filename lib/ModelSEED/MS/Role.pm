########################################################################
# ModelSEED::MS::Role - This is the moose object corresponding to the Role object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-03-26T23:22:35
########################################################################
use strict;
use ModelSEED::MS::DB::Role;
package ModelSEED::MS::Role;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::DB::Role';
#***********************************************************************************************************
# ADDITIONAL ATTRIBUTES:
#***********************************************************************************************************
has searchname => ( is => 'rw', isa => 'Str',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildsearchname' );
has reactions => ( is => 'rw', isa => 'Str',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildreactions' );
has complexIDs => ( is => 'rw', isa => 'ArrayRef',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildcomplexIDs' );

#***********************************************************************************************************
# BUILDERS:
#***********************************************************************************************************
sub _buildsearchname {
	my ($self) = @_;
	return ModelSEED::MS::Utilities::GlobalFunctions::convertRoleToSearchRole($self->name());
}
sub _buildreactions {
	my ($self) = @_;
	my $hash = $self->parent()->roleReactionHash();
	my $rxnlist = "";
	if (defined($hash->{$self->uuid()})) {
		foreach my $rxn (keys(%{$hash->{$self->uuid()}})) {
			if (length($rxnlist) > 0) {
				$rxnlist .= ";";
			}
			$rxnlist .= $hash->{$self->uuid()}->{$rxn}->id();
		}
	}
	return $rxnlist;
}
sub _buildcomplexIDs {
	my ($self) = @_;
	my $hash = $self->parent()->roleComplexHash();
	my $complexes = [];
	if (defined($hash->{$self->uuid()})) {
		foreach my $cpxid (keys(%{$hash->{$self->uuid()}})) {
			push(@{$complexes},$hash->{$self->uuid()}->{$cpxid}->id());
		}
	}
	return $complexes;
}

#***********************************************************************************************************
# CONSTANTS:
#***********************************************************************************************************

#***********************************************************************************************************
# FUNCTIONS:
#***********************************************************************************************************


__PACKAGE__->meta->make_immutable;
1;
