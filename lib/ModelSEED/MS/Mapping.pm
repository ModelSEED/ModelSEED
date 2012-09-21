########################################################################
# ModelSEED::MS::Mapping - This is the moose object corresponding to the Mapping object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-03-26T23:22:35
########################################################################
use strict;
use ModelSEED::MS::DB::Mapping;
package ModelSEED::MS::Mapping;
use Class::Autouse qw(
    ModelSEED::Client::SAP
);
use ModelSEED::MS::RoleSet;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::DB::Mapping';
#***********************************************************************************************************
# ADDITIONAL ATTRIBUTES:
#***********************************************************************************************************
has roleReactionHash => ( is => 'rw', isa => 'HashRef',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildroleReactionHash' );

#***********************************************************************************************************
# BUILDERS:
#***********************************************************************************************************
sub _buildroleReactionHash {
	my ($self) = @_;
	my $roleReactionHash;
	my $complexes = $self->complexes();
	for (my $i=0; $i < @{$complexes}; $i++) {
		my $complex = $complexes->[$i];
		my $cpxroles = $complex->complexroles();
		my $cpxrxns = $complex->reactions();
		for (my $j=0; $j < @{$cpxroles}; $j++) {
			my $role = $cpxroles->[$j]->role();
			for (my $k=0; $k < @{$cpxrxns}; $k++) {
				$roleReactionHash->{$role->uuid()}->{$cpxrxns->[$k]->uuid()} = $cpxrxns->[$k];
			}
		}
	}
	return $roleReactionHash;
}

#***********************************************************************************************************
# CONSTANTS:
#***********************************************************************************************************

#***********************************************************************************************************
# FUNCTIONS:
#***********************************************************************************************************

=head3 buildSubsystemRoleSets

=cut

sub buildSubsystemRoleSets {
    my ($self) = @_;
    # get subsystems
    my $SAP = ModelSEED::Client::SAP->new();

}

=head3 buildSubsystemReactionSets

Definition:
	void ModelSEED::MS::Mapping->buildSubsystemReactionSets({});
Description:
	Uses the reaction->role mappings to place reactions into reactions sets based on subsystem

=cut

sub buildSubsystemReactionSets {
	my ($self,$args) = @_;
	$args = ModelSEED::utilities::ARGS($args,[],{});
	my $subsystemHash;
	my $subsystemRoles;
	#First, placing all roles in subsystems into a hash
	for (my $i=0; $i < @{$self->rolesets()}; $i++) {
		my $roleset = $self->rolesets()->[$i];
		if ($roleset->type() eq "Subsystem") {
			for (my $j=0; $j < @{$roleset->roles()}; $j++) {
				my $role = $roleset->roles()->[$j];
				$subsystemRoles->{$role->name()}->{$roleset->name()} = 1;
			}
		}
	}
	#Next, placing reactions in subsystems based on the roles they are mapped to
	for (my $i=0; $i < @{$self->complexes()}; $i++) {
		my $cpx = $self->complexes()->[$i];
		#Identifying all subsystems that each complex is involved in
		my $cpxsubsys;
		for (my $j=0; $j < @{$cpx->complexroles()}; $j++) {
			my $role = $cpx->complexroles()->[$j]->role();
			if (defined($subsystemRoles->{$role->name()})) {
				foreach my $ss (keys(%{$subsystemRoles->{$role->name()}})) {
					$cpxsubsys->{$ss} = 1;
				}
			}
		}
	}
}

sub __upgrade__ {
	my ($class,$version) = @_;
	if ($version == 1) {
		return sub {
			my ($hash) = @_;
			print "Upgrading mapping from v1 to v2!\n";
			if (defined($hash->{rolesets})) {
				foreach my $roleset (@{$hash->{rolesets}}) {
					if (defined($roleset->{rolesetroles})) {
						foreach my $rolesetrole (@{$roleset->{rolesetroles}}) {
							if (defined($rolesetrole->{role_uuid})) {
								push(@{$roleset->{role_uuids}},$rolesetrole->{role_uuid});
							}
						}
					}
				}
			}
			if (defined($hash->{complexes})) {
				foreach my $complex (@{$hash->{complexes}}) {
					if (defined($complex->{complexreactions})) {
						foreach my $complexreaction (@{$complex->{complexreactions}}) {
							if (defined($complexreaction->{reaction_uuid})) {
								push(@{$complex->{reaction_uuids}},$complexreaction->{reaction_uuid});
							}
						}
					}
				}
			}
			$hash->{__VERSION__} = 2;
			if (defined($hash->{parent}) && ref($hash->{parent}) eq "ModelSEED::Store") {
				my $parent = $hash->{parent};
				delete($hash->{parent});
				$parent->save_data("mapping/".$hash->{uuid},$hash,{schema_update => 1});
				$hash->{parent} = $parent;
			}
			return $hash;
		};
	}
	
}
__PACKAGE__->meta->make_immutable;
1;
