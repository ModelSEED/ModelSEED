########################################################################
# ModelSEED::MS::InstanceTransports - This is the moose object corresponding to the InstanceTransports object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-03-14T07:56:20
########################################################################
use strict;
use Moose;
use namespace::autoclean;
use ModelSEED::MS::BaseObject
use ModelSEED::MS::Compound
use ModelSEED::MS::Compartment
package ModelSEED::MS::InstanceTransports
extends ModelSEED::MS::BaseObject


# PARENT:
has parent => (is => 'rw',required => 1,isa => 'ModelSEED::MS::ReactionInstance',weak_ref => 1);


# ATTRIBUTES:
has reactioninstance_uuid => ( is => 'rw', isa => 'Str', required => 1 );
has compound_uuid => ( is => 'rw', isa => 'Str', required => 1 );
has compartment_uuid => ( is => 'rw', isa => 'Str', required => 1 );
has compartmentIndex => ( is => 'rw', isa => 'Int', required => 1 );
has coefficient => ( is => 'rw', isa => 'Int', required => 1 );


# LINKS:
has compound => (is => 'rw',lazy => 1,builder => '_buildcompound',isa => 'ModelSEED::MS::Compound',weak_ref => 1);
has compartment => (is => 'rw',lazy => 1,builder => '_buildcompartment',isa => 'ModelSEED::MS::Compartment',weak_ref => 1);


# BUILDERS:
sub _buildcompound {
	my ($self) = ;
	return $self->getLinkedObject('Biochemistry','Compound','uuid',$self->compound_uuid());
}
sub _buildcompartment {
	my ($self) = ;
	return $self->getLinkedObject('Biochemistry','Compartment','uuid',$self->compartment_uuid());
}


# CONSTANTS:
sub _type { return 'InstanceTransports'; }


# FUNCTIONS:
#TODO


__PACKAGE__->meta->make_immutable;
1;
