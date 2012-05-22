########################################################################
# ModelSEED::MS::DB::FBAReactionVariable - This is the moose object corresponding to the FBAReactionVariable object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
use strict;
use ModelSEED::MS::BaseObject;
package ModelSEED::MS::DB::FBAReactionVariable;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::BaseObject';


# PARENT:
has parent => (is => 'rw',isa => 'ModelSEED::MS::FBAResults', type => 'parent', metaclass => 'Typed',weak_ref => 1);


# ATTRIBUTES:
has modelreaction_uuid => ( is => 'rw', isa => 'ModelSEED::uuid', type => 'attribute', metaclass => 'Typed', required => 1 );
has variableType => ( is => 'rw', isa => 'Str', type => 'attribute', metaclass => 'Typed' );
has lowerBound => ( is => 'rw', isa => 'Str', type => 'attribute', metaclass => 'Typed' );
has upperBound => ( is => 'rw', isa => 'Str', type => 'attribute', metaclass => 'Typed' );
has min => ( is => 'rw', isa => 'Str', type => 'attribute', metaclass => 'Typed' );
has max => ( is => 'rw', isa => 'Str', type => 'attribute', metaclass => 'Typed' );
has value => ( is => 'rw', isa => 'Str', type => 'attribute', metaclass => 'Typed' );




# LINKS:
has modelreaction => (is => 'rw',lazy => 1,builder => '_buildmodelreaction',isa => 'ModelSEED::MS::ModelReaction', type => 'link(Model,ModelReaction,uuid,modelreaction_uuid)', metaclass => 'Typed',weak_ref => 1);


# BUILDERS:
sub _buildmodelreaction {
	my ($self) = @_;
	return $self->getLinkedObject('Model','ModelReaction','uuid',$self->modelreaction_uuid());
}


# CONSTANTS:
sub _type { return 'FBAReactionVariable'; }

my $attributes = ['modelreaction_uuid', 'variableType', 'lowerBound', 'upperBound', 'min', 'max', 'value'];
sub _attributes {
	return $attributes;
}

my $subobjects = [];
sub _subobjects {
	return $subobjects;
}


__PACKAGE__->meta->make_immutable;
1;
