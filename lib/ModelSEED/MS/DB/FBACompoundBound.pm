########################################################################
# ModelSEED::MS::DB::FBACompoundBound - This is the moose object corresponding to the FBACompoundBound object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package ModelSEED::MS::DB::FBACompoundBound;
use ModelSEED::MS::BaseObject;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'ModelSEED::MS::FBAFormulation', weak_ref => 1, type => 'parent', metaclass => 'Typed');


# ATTRIBUTES:
has modelcompound_uuid => (is => 'rw', isa => 'ModelSEED::uuid', printOrder => '-1', required => 1, type => 'attribute', metaclass => 'Typed');
has variableType => (is => 'rw', isa => 'Str', printOrder => '-1', required => 1, type => 'attribute', metaclass => 'Typed');
has upperBound => (is => 'rw', isa => 'Num', printOrder => '-1', required => 1, type => 'attribute', metaclass => 'Typed');
has lowerBound => (is => 'rw', isa => 'Num', printOrder => '-1', required => 1, type => 'attribute', metaclass => 'Typed');


# LINKS:
has modelCompound => (is => 'rw', type => 'link(Model,modelcompounds,modelcompound_uuid)', metaclass => 'Typed', lazy => 1, builder => '_build_modelCompound', clearer => 'clear_modelCompound', isa => 'ModelSEED::MS::ModelCompound', weak_ref => 1);


# BUILDERS:
sub _build_modelCompound {
  my ($self) = @_;
  return $self->getLinkedObject('Model','modelcompounds',$self->modelcompound_uuid());
}


# CONSTANTS:
sub _type { return 'FBACompoundBound'; }

my $attributes = [
          {
            'req' => 1,
            'printOrder' => -1,
            'name' => 'modelcompound_uuid',
            'type' => 'ModelSEED::uuid',
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

my $attribute_map = {modelcompound_uuid => 0, variableType => 1, upperBound => 2, lowerBound => 3};
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
            'attribute' => 'modelcompound_uuid',
            'parent' => 'Model',
            'clearer' => 'clear_modelCompound',
            'name' => 'modelCompound',
            'class' => 'modelcompounds',
            'method' => 'modelcompounds'
          }
        ];

my $link_map = {modelCompound => 0};
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
