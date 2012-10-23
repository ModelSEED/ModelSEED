########################################################################
# ModelSEED::MS::DB::FBAReactionBound - This is the moose object corresponding to the FBAReactionBound object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package ModelSEED::MS::DB::FBAReactionBound;
use ModelSEED::MS::BaseObject;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'ModelSEED::MS::FBAFormulation', weak_ref => 1, type => 'parent', metaclass => 'Typed');


# ATTRIBUTES:
has modelreaction_link => (is => 'rw', isa => 'ModelSEED::subobject_link', printOrder => '-1', required => 1, type => 'attribute', metaclass => 'Typed');
has variableType => (is => 'rw', isa => 'Str', printOrder => '-1', required => 1, type => 'attribute', metaclass => 'Typed');
has upperBound => (is => 'rw', isa => 'Num', printOrder => '-1', required => 1, type => 'attribute', metaclass => 'Typed');
has lowerBound => (is => 'rw', isa => 'Num', printOrder => '-1', required => 1, type => 'attribute', metaclass => 'Typed');


# LINKS:
has modelReaction => (is => 'rw', type => 'link(Model,modelreactions,modelreaction_link)', metaclass => 'Typed', lazy => 1, builder => '_build_modelReaction', clearer => 'clear_modelReaction', isa => 'ModelSEED::MS::ModelReaction', weak_ref => 1);


# BUILDERS:
sub _build_modelReaction {
  my ($self) = @_;
  return $self->getLinkedObject('Model','modelreactions',$self->modelreaction_link());
}


# CONSTANTS:
sub _type { return 'FBAReactionBound'; }

my $attributes = [
          {
            'req' => 1,
            'printOrder' => -1,
            'name' => 'modelreaction_link',
            'type' => 'ModelSEED::subobject_link',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => -1,
            'name' => 'variableType',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => -1,
            'name' => 'upperBound',
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => -1,
            'name' => 'lowerBound',
            'type' => 'Num',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {modelreaction_link => 0, variableType => 1, upperBound => 2, lowerBound => 3};
sub _attributes {
  my ($self, $key) = @_;
  if (defined($key)) {
    my $ind = $attribute_map->{$key};
    if (defined($ind)) {
      return $attributes->[$ind];
    } else {
      return;
    }
  } else {
    return $attributes;
  }
}

my $links = [
          {
            'attribute' => 'modelreaction_link',
            'parent' => 'Model',
            'clearer' => 'clear_modelReaction',
            'name' => 'modelReaction',
            'class' => 'modelreactions',
            'method' => 'modelreactions'
          }
        ];

my $link_map = {modelReaction => 0};
sub _links {
  my ($self, $key) = @_;
  if (defined($key)) {
    my $ind = $link_map->{$key};
    if (defined($ind)) {
      return $links->[$ind];
    } else {
      return;
    }
  } else {
    return $links;
  }
}

my $subobjects = [];

my $subobject_map = {};
sub _subobjects {
  my ($self, $key) = @_;
  if (defined($key)) {
    my $ind = $subobject_map->{$key};
    if (defined($ind)) {
      return $subobjects->[$ind];
    } else {
      return;
    }
  } else {
    return $subobjects;
  }
}


__PACKAGE__->meta->make_immutable;
1;
