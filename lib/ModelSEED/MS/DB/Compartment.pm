########################################################################
# ModelSEED::MS::DB::Compartment - This is the moose object corresponding to the Compartment object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package ModelSEED::MS::DB::Compartment;
use ModelSEED::MS::BaseObject;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'ModelSEED::MS::Biochemistry', weak_ref => 1, type => 'parent', metaclass => 'Typed');


# ATTRIBUTES:
has uid => (is => 'rw', isa => 'ModelSEED::uid', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');
has modDate => (is => 'rw', isa => 'Str', printOrder => '-1', lazy => 1, builder => '_build_modDate', type => 'attribute', metaclass => 'Typed');
has id => (is => 'rw', isa => 'Str', printOrder => '1', required => 1, type => 'attribute', metaclass => 'Typed');
has name => (is => 'rw', isa => 'ModelSEED::varchar', printOrder => '2', default => '', type => 'attribute', metaclass => 'Typed');
has hierarchy => (is => 'rw', isa => 'Int', printOrder => '3', default => '', type => 'attribute', metaclass => 'Typed');


# LINKS:


# BUILDERS:
sub _build_modDate { return DateTime->now()->datetime(); }


# CONSTANTS:
sub _type { return 'Compartment'; }

my $attributes = [
          {
            'len' => 36,
            'req' => 1,
            'printOrder' => 0,
            'name' => 'uid',
            'type' => 'ModelSEED::uid',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'modDate',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'len' => 2,
            'req' => 1,
            'printOrder' => 1,
            'name' => 'id',
            'type' => 'Str',
            'description' => 'Single charachter identifer for the compartment, e.g. "e" or "c".',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 2,
            'name' => 'name',
            'default' => '',
            'type' => 'ModelSEED::varchar',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 3,
            'name' => 'hierarchy',
            'default' => '',
            'type' => 'Int',
            'description' => 'Index indicating the position of a compartment relative to other compartments. Extracellular is 0. A compartment contained within another compartment has an index that is +1 over the outer comaprtment.',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {uid => 0, modDate => 1, id => 2, name => 3, hierarchy => 4};
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
