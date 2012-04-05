########################################################################
# ModelSEED::MS::DB::RolesetAlias - This is the moose object corresponding to the RolesetAlias object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-04-03T07:07:13
########################################################################
use strict;
use ModelSEED::MS::BaseObject;
package ModelSEED::MS::DB::RolesetAlias;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::BaseObject';


# PARENT:
has parent => (is => 'rw',isa => 'ModelSEED::MS::RolesetAliasSet', type => 'parent', metaclass => 'Typed',weak_ref => 1);


# ATTRIBUTES:
has roleset_uuid => ( is => 'rw', isa => 'ModelSEED::uuid', type => 'attribute', metaclass => 'Typed', required => 1 );
has alias => ( is => 'rw', isa => 'Str', type => 'attribute', metaclass => 'Typed', required => 1 );




# LINKS:
has roleset => (is => 'rw',lazy => 1,builder => '_buildroleset',isa => 'ModelSEED::MS::Roleset', type => 'link(Mapping,Roleset,uuid,roleset_uuid)', metaclass => 'Typed',weak_ref => 1);


# BUILDERS:
sub _buildroleset {
	my ($self) = @_;
	return $self->getLinkedObject('Mapping','Roleset','uuid',$self->roleset_uuid());
}


# CONSTANTS:
sub _type { return 'RolesetAlias'; }


__PACKAGE__->meta->make_immutable;
1;
