########################################################################
# ModelSEED::MS::DB::Configuration - This is the moose object corresponding to the Configuration object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package ModelSEED::MS::DB::Configuration;
use ModelSEED::MS::BaseObject;
use ModelSEED::MS::Store;
use ModelSEED::MS::User;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');


# ATTRIBUTES:
has username => (is => 'rw', isa => 'Str', printOrder => '0', default => 'Public', type => 'attribute', metaclass => 'Typed');
has password => (is => 'rw', isa => 'Str', printOrder => '1', default => '', type => 'attribute', metaclass => 'Typed');
has PRIMARY_STORE => (is => 'rw', isa => 'Str', printOrder => '0', default => '', type => 'attribute', metaclass => 'Typed');
has CPLEX_LICENCE => (is => 'rw', isa => 'Str', printOrder => '0', type => 'attribute', metaclass => 'Typed');
has ERROR_DIR => (is => 'rw', isa => 'Str', printOrder => '0', default => '', type => 'attribute', metaclass => 'Typed');
has MFATK_CACHE => (is => 'rw', isa => 'Str', printOrder => '0', default => '', type => 'attribute', metaclass => 'Typed');
has MFATK_BIN => (is => 'rw', isa => 'Str', printOrder => '0', default => '', type => 'attribute', metaclass => 'Typed');


# SUBOBJECTS:
has stores => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'encompassed(Store)', metaclass => 'Typed', reader => '_stores', printOrder => '-1');
has users => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'encompassed(User)', metaclass => 'Typed', reader => '_users', printOrder => '-1');


# LINKS:


# BUILDERS:


# CONSTANTS:
sub _type { return 'Configuration'; }

my $attributes = [
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'username',
            'default' => 'Public',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 1,
            'name' => 'password',
            'default' => '',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'PRIMARY_STORE',
            'default' => '',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'CPLEX_LICENCE',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'ERROR_DIR',
            'default' => '',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'MFATK_CACHE',
            'default' => '',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'MFATK_BIN',
            'default' => '',
            'type' => 'Str',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {username => 0, password => 1, PRIMARY_STORE => 2, CPLEX_LICENCE => 3, ERROR_DIR => 4, MFATK_CACHE => 5, MFATK_BIN => 6};
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

my $links = [];

my $link_map = {};
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
            'printOrder' => -1,
            'name' => 'stores',
            'type' => 'encompassed',
            'class' => 'Store'
          },
          {
            'printOrder' => -1,
            'name' => 'users',
            'type' => 'encompassed',
            'class' => 'User'
          }
        ];

my $subobject_map = {stores => 0, users => 1};
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
around 'stores' => sub {
  my ($orig, $self) = @_;
  return $self->_build_all_objects('stores');
};
around 'users' => sub {
  my ($orig, $self) = @_;
  return $self->_build_all_objects('users');
};


__PACKAGE__->meta->make_immutable;
1;
