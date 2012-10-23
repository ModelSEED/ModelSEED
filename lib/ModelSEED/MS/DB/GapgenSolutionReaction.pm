########################################################################
# ModelSEED::MS::DB::GapgenSolutionReaction - This is the moose object corresponding to the GapgenSolutionReaction object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package ModelSEED::MS::DB::GapgenSolutionReaction;
use ModelSEED::MS::BaseObject;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'ModelSEED::MS::GapgenSolution', weak_ref => 1, type => 'parent', metaclass => 'Typed');


# ATTRIBUTES:
has modelreaction_link => (is => 'rw', isa => 'ModelSEED::subobject_link', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');
has direction => (is => 'rw', isa => 'Str', printOrder => '0', default => '1', type => 'attribute', metaclass => 'Typed');


# LINKS:
has modelreaction => (is => 'rw', type => 'link(Model,modelreactions,modelreaction_link)', metaclass => 'Typed', lazy => 1, builder => '_build_modelreaction', clearer => 'clear_modelreaction', isa => 'ModelSEED::MS::ModelReaction', weak_ref => 1);


# BUILDERS:
sub _build_modelreaction {
  my ($self) = @_;
  return $self->getLinkedObject('Model','modelreactions',$self->modelreaction_link());
}


# CONSTANTS:
sub _type { return 'GapgenSolutionReaction'; }

my $attributes = [
          {
            'req' => 1,
            'printOrder' => 0,
            'name' => 'modelreaction_link',
            'type' => 'ModelSEED::subobject_link',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'direction',
            'default' => '1',
            'type' => 'Str',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {modelreaction_link => 0, direction => 1};
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
            'clearer' => 'clear_modelreaction',
            'name' => 'modelreaction',
            'class' => 'modelreactions',
            'method' => 'modelreactions'
          }
        ];

my $link_map = {modelreaction => 0};
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
