########################################################################
# ModelSEED::MS::DB::MappingClassifier - This is the moose object corresponding to the MappingClassifier object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package ModelSEED::MS::DB::MappingClassifier;
use ModelSEED::MS::BaseObject;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'ModelSEED::MS::Mapping', weak_ref => 1, type => 'parent', metaclass => 'Typed');


# ATTRIBUTES:
has name => (is => 'rw', isa => 'Str', printOrder => '4', required => 1, type => 'attribute', metaclass => 'Typed');
has type => (is => 'rw', isa => 'Str', printOrder => '4', required => 1, type => 'attribute', metaclass => 'Typed');
has classifer_uuid => (is => 'rw', isa => 'Str', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');


# LINKS:
has classifier => (is => 'rw', type => 'link(ModelSEED::Store,Classifer,classifer_uuid)', metaclass => 'Typed', lazy => 1, builder => '_build_classifier', clearer => 'clear_classifier', isa => 'ModelSEED::MS::Classifer');


# BUILDERS:
sub _build_classifier {
  my ($self) = @_;
  return $self->getLinkedObject('ModelSEED::Store','Classifer',$self->classifer_uuid());
}


# CONSTANTS:
sub _type { return 'MappingClassifier'; }

my $attributes = [
          {
            'req' => 1,
            'printOrder' => 4,
            'name' => 'name',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => 4,
            'name' => 'type',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => 0,
            'name' => 'classifer_uuid',
            'type' => 'Str',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {name => 0, type => 1, classifer_uuid => 2};
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
            'attribute' => 'classifer_uuid',
            'weak' => 0,
            'parent' => 'ModelSEED::Store',
            'clearer' => 'clear_classifier',
            'name' => 'classifier',
            'class' => 'Classifer',
            'method' => 'Classifer'
          }
        ];

my $link_map = {classifier => 0};
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
