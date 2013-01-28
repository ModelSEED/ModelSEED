########################################################################
# ModelSEED::MS::DB::Classifier - This is the moose object corresponding to the Classifier object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package ModelSEED::MS::DB::Classifier;
use ModelSEED::MS::IndexedObject;
use ModelSEED::MS::ClassifierRole;
use ModelSEED::MS::ClassifierClassification;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::IndexedObject';


our $VERSION = 1;
# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');


# ATTRIBUTES:
has uuid => (is => 'rw', isa => 'ModelSEED::uuid', printOrder => '4', required => 1, lazy => 1, builder => '_build_uuid', type => 'attribute', metaclass => 'Typed');
has name => (is => 'rw', isa => 'Str', printOrder => '4', required => 1, type => 'attribute', metaclass => 'Typed');
has type => (is => 'rw', isa => 'Str', printOrder => '4', required => 1, type => 'attribute', metaclass => 'Typed');
has mapping_uuid => (is => 'rw', isa => 'Str', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');


# ANCESTOR:
has ancestor_uuid => (is => 'rw', isa => 'uuid', type => 'ancestor', metaclass => 'Typed');


# SUBOBJECTS:
has classifierRoles => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(ClassifierRole)', metaclass => 'Typed', reader => '_classifierRoles', printOrder => '0');
has classifierClassifications => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(ClassifierClassification)', metaclass => 'Typed', reader => '_classifierClassifications', printOrder => '0');


# LINKS:
has Mapping => (is => 'rw', type => 'link(ModelSEED::Store,Mapping,mapping_uuid)', metaclass => 'Typed', lazy => 1, builder => '_build_Mapping', clearer => 'clear_Mapping', isa => 'ModelSEED::MS::Mapping');


# BUILDERS:
sub _build_uuid { return Data::UUID->new()->create_str(); }
sub _build_Mapping {
  my ($self) = @_;
  return $self->getLinkedObject('ModelSEED::Store','Mapping',$self->mapping_uuid());
}


# CONSTANTS:
sub __version__ { return $VERSION; }
sub _type { return 'Classifier'; }

my $attributes = [
          {
            'req' => 1,
            'printOrder' => 4,
            'name' => 'uuid',
            'type' => 'ModelSEED::uuid',
            'perm' => 'rw'
          },
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
            'name' => 'mapping_uuid',
            'type' => 'Str',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {uuid => 0, name => 1, type => 2, mapping_uuid => 3};
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
            'attribute' => 'mapping_uuid',
            'weak' => 0,
            'parent' => 'ModelSEED::Store',
            'clearer' => 'clear_Mapping',
            'name' => 'Mapping',
            'class' => 'Mapping',
            'method' => 'Mapping'
          }
        ];

my $link_map = {Mapping => 0};
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

my $subobjects = [
          {
            'printOrder' => 0,
            'name' => 'classifierRoles',
            'type' => 'child',
            'class' => 'ClassifierRole'
          },
          {
            'printOrder' => 0,
            'name' => 'classifierClassifications',
            'type' => 'child',
            'class' => 'ClassifierClassification'
          }
        ];

my $subobject_map = {classifierRoles => 0, classifierClassifications => 1};
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


# SUBOBJECT READERS:
around 'classifierRoles' => sub {
  my ($orig, $self) = @_;
  return $self->_build_all_objects('classifierRoles');
};
around 'classifierClassifications' => sub {
  my ($orig, $self) = @_;
  return $self->_build_all_objects('classifierClassifications');
};


__PACKAGE__->meta->make_immutable;
1;
