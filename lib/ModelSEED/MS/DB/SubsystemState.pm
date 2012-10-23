########################################################################
# ModelSEED::MS::DB::SubsystemState - This is the moose object corresponding to the SubsystemState object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package ModelSEED::MS::DB::SubsystemState;
use ModelSEED::MS::BaseObject;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'ModelSEED::MS::Annotation', weak_ref => 1, type => 'parent', metaclass => 'Typed');


# ATTRIBUTES:
has roleset_link => (is => 'rw', isa => 'ModelSEED::subobject_link', printOrder => '0', type => 'attribute', metaclass => 'Typed');
has name => (is => 'rw', isa => 'Str', printOrder => '0', type => 'attribute', metaclass => 'Typed');
has variant => (is => 'rw', isa => 'Str', printOrder => '0', default => '', type => 'attribute', metaclass => 'Typed');


# LINKS:
has roleset => (is => 'rw', type => 'link(Mapping,rolesets,roleset_link)', metaclass => 'Typed', lazy => 1, builder => '_build_roleset', clearer => 'clear_roleset', isa => 'ModelSEED::MS::RoleSet', weak_ref => 1);


# BUILDERS:
sub _build_roleset {
  my ($self) = @_;
  return $self->getLinkedObject('Mapping','rolesets',$self->roleset_link());
}


# CONSTANTS:
sub _type { return 'SubsystemState'; }

my $attributes = [
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'roleset_link',
            'type' => 'ModelSEED::subobject_link',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'name',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'variant',
            'default' => '',
            'type' => 'Str',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {roleset_link => 0, name => 1, variant => 2};
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
            'attribute' => 'roleset_link',
            'parent' => 'Mapping',
            'clearer' => 'clear_roleset',
            'name' => 'roleset',
            'class' => 'rolesets',
            'method' => 'rolesets'
          }
        ];

my $link_map = {roleset => 0};
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
