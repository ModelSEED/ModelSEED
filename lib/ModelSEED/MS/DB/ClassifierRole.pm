########################################################################
# ModelSEED::MS::DB::ClassifierRole - This is the moose object corresponding to the ClassifierRole object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package ModelSEED::MS::DB::ClassifierRole;
use ModelSEED::MS::BaseObject;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'ModelSEED::MS::Classifier', weak_ref => 1, type => 'parent', metaclass => 'Typed');


# ATTRIBUTES:
has classification_uuids => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub{return [];}, type => 'attribute', metaclass => 'Typed');
has classificationProbabilities => (is => 'rw', isa => 'HashRef', printOrder => '-1', default => sub{return {};}, type => 'attribute', metaclass => 'Typed');
has role_uuid => (is => 'rw', isa => 'ModelSEED::uuid', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');


# LINKS:
has role => (is => 'rw', type => 'link(Mapping,roles,role_uuid)', metaclass => 'Typed', lazy => 1, builder => '_build_role', clearer => 'clear_role', isa => 'ModelSEED::MS::Role', weak_ref => 1);
has classifications => (is => 'rw', type => 'link(Classifier,classifierClassifications,classification_uuids)', metaclass => 'Typed', lazy => 1, builder => '_build_classifications', clearer => 'clear_classifications', isa => 'ArrayRef');


# BUILDERS:
sub _build_role {
  my ($self) = @_;
  return $self->getLinkedObject('Mapping','roles',$self->role_uuid());
}
sub _build_classifications {
  my ($self) = @_;
  return $self->getLinkedObjectArray('Classifier','classifierClassifications',$self->classification_uuids());
}


# CONSTANTS:
sub _type { return 'ClassifierRole'; }

my $attributes = [
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'classification_uuids',
            'default' => 'sub{return [];}',
            'type' => 'ArrayRef',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'classificationProbabilities',
            'default' => 'sub{return {};}',
            'type' => 'HashRef',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => 0,
            'name' => 'role_uuid',
            'type' => 'ModelSEED::uuid',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {classification_uuids => 0, classificationProbabilities => 1, role_uuid => 2};
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
            'attribute' => 'role_uuid',
            'parent' => 'Mapping',
            'clearer' => 'clear_role',
            'name' => 'role',
            'class' => 'roles',
            'method' => 'roles'
          },
          {
            'array' => 1,
            'attribute' => 'classification_uuids',
            'parent' => 'Classifier',
            'clearer' => 'clear_classifications',
            'name' => 'classifications',
            'class' => 'classifierClassifications',
            'method' => 'classifierClassifications'
          }
        ];

my $link_map = {role => 0, classifications => 1};
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
