########################################################################
# ModelSEED::MS::DB::Biomass - This is the moose object corresponding to the Biomass object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package ModelSEED::MS::DB::Biomass;
use ModelSEED::MS::BaseObject;
use ModelSEED::MS::BiomassCompound;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'ModelSEED::MS::Model', weak_ref => 1, type => 'parent', metaclass => 'Typed');


# ATTRIBUTES:
has uid => (is => 'rw', isa => 'ModelSEED::uid', printOrder => '0', type => 'attribute', metaclass => 'Typed');
has modDate => (is => 'rw', isa => 'Str', printOrder => '-1', lazy => 1, builder => '_build_modDate', type => 'attribute', metaclass => 'Typed');
has name => (is => 'rw', isa => 'ModelSEED::varchar', printOrder => '1', default => '', type => 'attribute', metaclass => 'Typed');
has dna => (is => 'rw', isa => 'Num', printOrder => '3', default => '0.05', type => 'attribute', metaclass => 'Typed');
has rna => (is => 'rw', isa => 'Num', printOrder => '4', default => '0.1', type => 'attribute', metaclass => 'Typed');
has protein => (is => 'rw', isa => 'Num', printOrder => '5', default => '0.5', type => 'attribute', metaclass => 'Typed');
has cellwall => (is => 'rw', isa => 'Num', printOrder => '6', default => '0.15', type => 'attribute', metaclass => 'Typed');
has lipid => (is => 'rw', isa => 'Num', printOrder => '7', default => '0.05', type => 'attribute', metaclass => 'Typed');
has cofactor => (is => 'rw', isa => 'Num', printOrder => '8', default => '0.15', type => 'attribute', metaclass => 'Typed');
has energy => (is => 'rw', isa => 'Num', printOrder => '9', default => '40', type => 'attribute', metaclass => 'Typed');


# SUBOBJECTS:
has biomasscompounds => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'encompassed(BiomassCompound)', metaclass => 'Typed', reader => '_biomasscompounds', printOrder => '-1');


# LINKS:
has id => (is => 'rw', lazy => 1, builder => '_build_id', isa => 'Str', type => 'id', metaclass => 'Typed');


# BUILDERS:
sub _build_modDate { return DateTime->now()->datetime(); }


# CONSTANTS:
sub _type { return 'Biomass'; }

my $attributes = [
          {
            'req' => 0,
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
            'req' => 0,
            'printOrder' => 1,
            'name' => 'name',
            'default' => '',
            'type' => 'ModelSEED::varchar',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 3,
            'name' => 'dna',
            'default' => '0.05',
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 4,
            'name' => 'rna',
            'default' => '0.1',
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 5,
            'name' => 'protein',
            'default' => '0.5',
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 6,
            'name' => 'cellwall',
            'default' => '0.15',
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 7,
            'name' => 'lipid',
            'default' => '0.05',
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 8,
            'name' => 'cofactor',
            'default' => '0.15',
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 9,
            'name' => 'energy',
            'default' => '40',
            'type' => 'Num',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {uid => 0, modDate => 1, name => 2, dna => 3, rna => 4, protein => 5, cellwall => 6, lipid => 7, cofactor => 8, energy => 9};
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
            'name' => 'biomasscompounds',
            'type' => 'encompassed',
            'class' => 'BiomassCompound'
          }
        ];

my $subobject_map = {biomasscompounds => 0};
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
sub _aliasowner { return 'Model'; }


# SUBOBJECT READERS:
around 'biomasscompounds' => sub {
  my ($orig, $self) = @_;
  return $self->_build_all_objects('biomasscompounds');
};


__PACKAGE__->meta->make_immutable;
1;
