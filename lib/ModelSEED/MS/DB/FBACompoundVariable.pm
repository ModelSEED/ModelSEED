########################################################################
# ModelSEED::MS::DB::FBACompoundVariable - This is the moose object corresponding to the FBACompoundVariable object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package ModelSEED::MS::DB::FBACompoundVariable;
use ModelSEED::MS::BaseObject;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'ModelSEED::MS::FBAResult', weak_ref => 1, type => 'parent', metaclass => 'Typed');


# ATTRIBUTES:
has modelcompound_link => (is => 'rw', isa => 'ModelSEED::subobject_link', printOrder => '-1', required => 1, type => 'attribute', metaclass => 'Typed');
has variableType => (is => 'rw', isa => 'Str', printOrder => '3', type => 'attribute', metaclass => 'Typed');
has class => (is => 'rw', isa => 'Str', printOrder => '9', type => 'attribute', metaclass => 'Typed');
has lowerBound => (is => 'rw', isa => 'Num', printOrder => '4', type => 'attribute', metaclass => 'Typed');
has upperBound => (is => 'rw', isa => 'Num', printOrder => '5', type => 'attribute', metaclass => 'Typed');
has min => (is => 'rw', isa => 'Num', printOrder => '7', type => 'attribute', metaclass => 'Typed');
has max => (is => 'rw', isa => 'Num', printOrder => '8', type => 'attribute', metaclass => 'Typed');
has value => (is => 'rw', isa => 'Num', printOrder => '6', type => 'attribute', metaclass => 'Typed');


# LINKS:
has modelcompound => (is => 'rw', type => 'link(Model,modelcompounds,modelcompound_link)', metaclass => 'Typed', lazy => 1, builder => '_build_modelcompound', clearer => 'clear_modelcompound', isa => 'ModelSEED::MS::ModelCompound', weak_ref => 1);


# BUILDERS:
sub _build_modelcompound {
  my ($self) = @_;
  return $self->getLinkedObject('Model','modelcompounds',$self->modelcompound_link());
}


# CONSTANTS:
sub _type { return 'FBACompoundVariable'; }

my $attributes = [
          {
            'req' => 1,
            'printOrder' => -1,
            'name' => 'modelcompound_link',
            'type' => 'ModelSEED::subobject_link',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 3,
            'name' => 'variableType',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 9,
            'name' => 'class',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'len' => 1,
            'req' => 0,
            'printOrder' => 4,
            'name' => 'lowerBound',
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'len' => 1,
            'req' => 0,
            'printOrder' => 5,
            'name' => 'upperBound',
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'len' => 1,
            'req' => 0,
            'printOrder' => 7,
            'name' => 'min',
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'len' => 1,
            'req' => 0,
            'printOrder' => 8,
            'name' => 'max',
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'len' => 1,
            'req' => 0,
            'printOrder' => 6,
            'name' => 'value',
            'type' => 'Num',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {modelcompound_link => 0, variableType => 1, class => 2, lowerBound => 3, upperBound => 4, min => 5, max => 6, value => 7};
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
            'attribute' => 'modelcompound_link',
            'parent' => 'Model',
            'clearer' => 'clear_modelcompound',
            'name' => 'modelcompound',
            'class' => 'modelcompounds',
            'method' => 'modelcompounds'
          }
        ];

my $link_map = {modelcompound => 0};
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
