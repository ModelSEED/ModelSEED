########################################################################
# ModelSEED::MS::DB::UserStore - This is the moose object corresponding to the UserStore object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package ModelSEED::MS::DB::UserStore;
use ModelSEED::MS::IndexedObject;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::IndexedObject';


our $VERSION = 1;
# PARENT:
has parent => (is => 'rw', isa => 'ModelSEED::MS::User', weak_ref => 1, type => 'parent', metaclass => 'Typed');


# ATTRIBUTES:
has store_uuid => (is => 'rw', isa => 'Str', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');
has login => (is => 'rw', isa => 'Str', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');
has password => (is => 'rw', isa => 'Str', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');
has accountType => (is => 'rw', isa => 'Str', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');
has defaultMapping_ref => (is => 'rw', isa => 'Str', printOrder => '0', type => 'attribute', metaclass => 'Typed');
has defaultBiochemistry_ref => (is => 'rw', isa => 'Str', printOrder => '0', type => 'attribute', metaclass => 'Typed');


# LINKS:
has associatedStore => (is => 'rw', type => 'link(Configuration,stores,store_uuid)', metaclass => 'Typed', lazy => 1, builder => '_build_associatedStore', clearer => 'clear_associatedStore', isa => 'ModelSEED::MS::Store');


# BUILDERS:
sub _build_associatedStore {
  my ($self) = @_;
  return $self->getLinkedObject('Configuration','stores',$self->store_uuid());
}


# CONSTANTS:
sub __version__ { return $VERSION; }
sub _type { return 'UserStore'; }

my $attributes = [
          {
            'req' => 1,
            'printOrder' => 0,
            'name' => 'store_uuid',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => 0,
            'name' => 'login',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => 0,
            'name' => 'password',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => 0,
            'name' => 'accountType',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'defaultMapping_ref',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'defaultBiochemistry_ref',
            'type' => 'Str',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {store_uuid => 0, login => 1, password => 2, accountType => 3, defaultMapping_ref => 4, defaultBiochemistry_ref => 5};
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
            'attribute' => 'store_uuid',
            'weak' => 0,
            'parent' => 'Configuration',
            'clearer' => 'clear_associatedStore',
            'name' => 'associatedStore',
            'class' => 'stores',
            'method' => 'stores'
          }
        ];

my $link_map = {associatedStore => 0};
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
