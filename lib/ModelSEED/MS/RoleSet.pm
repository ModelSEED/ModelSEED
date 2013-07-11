########################################################################
# ModelSEED::MS::RoleSet - This is the moose object corresponding to the RoleSet object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-03-26T23:22:35
########################################################################
use strict;
use ModelSEED::MS::DB::RoleSet;
package ModelSEED::MS::RoleSet;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::DB::RoleSet';
#***********************************************************************************************************
# ADDITIONAL ATTRIBUTES:
#***********************************************************************************************************
has roleList => ( is => 'rw', isa => 'Str',printOrder => '5', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildroleList' );
has roleIDs => ( is => 'rw', isa => 'ArrayRef',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildroleIDs' );

#***********************************************************************************************************
# BUILDERS:
#***********************************************************************************************************
sub _buildroleList {
	my ($self) = @_;
	my $roleList = "";
	for (my $i=0; $i < @{$self->roles()}; $i++) {
		if (length($roleList) > 0) {
			$roleList .= ";";
		}
		$roleList .= $self->roles()->[$i]->name();		
	}
	return $roleList;
}
sub _buildroleIDs {
	my ($self) = @_;
	my $roleIDs = [];
	my $roles = $self->roles();
	for (my $i=0; $i < @{$roles}; $i++) {
		push(@{$roleIDs},$roles->[$i]->id());		
	}
	return $roleIDs;
}

#***********************************************************************************************************
# CONSTANTS:
#***********************************************************************************************************

#***********************************************************************************************************
# FUNCTIONS:
#***********************************************************************************************************

=head3 addRole

Definition:
	void addRole();
Description:
	Adds role to roleset
	
=cut

sub addRole {
	my ($self,$role) = @_;
	for (my $i=0; $i < @{$self->role_uuids()}; $i++) {
		if ($self->role_uuids()->[$i] eq $role->uuid()) {
			return;
		}
	}
	push(@{$self->role_uuids()},$role->uuid());
	$self->clear_roles();
}

__PACKAGE__->meta->make_immutable;
1;
