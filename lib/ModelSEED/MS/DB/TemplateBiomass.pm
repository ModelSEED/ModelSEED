########################################################################
# ModelSEED::MS::DB::TemplateBiomass - This is the moose object corresponding to the TemplateBiomass object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package ModelSEED::MS::DB::TemplateBiomass;
use ModelSEED::MS::BaseObject;
use ModelSEED::MS::TemplateBiomassComponent;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'ModelSEED::MS::ModelTemplate', weak_ref => 1, type => 'parent', metaclass => 'Typed');


# ATTRIBUTES:
has uuid => (is => 'rw', isa => 'ModelSEED::uuid', printOrder => '0', required => 1, lazy => 1, builder => '_build_uuid', type => 'attribute', metaclass => 'Typed');
has name => (is => 'rw', isa => 'Str', printOrder => '1', required => 1, type => 'attribute', metaclass => 'Typed');
has type => (is => 'rw', isa => 'Str', printOrder => '1', default => 'defaultGrowth', type => 'attribute', metaclass => 'Typed');
has other => (is => 'rw', isa => 'Num', printOrder => '2', default => '0', type => 'attribute', metaclass => 'Typed');
has dna => (is => 'rw', isa => 'Num', printOrder => '2', default => '0', type => 'attribute', metaclass => 'Typed');
has rna => (is => 'rw', isa => 'Num', printOrder => '3', default => '0', type => 'attribute', metaclass => 'Typed');
has protein => (is => 'rw', isa => 'Num', printOrder => '4', default => '0', type => 'attribute', metaclass => 'Typed');
has lipid => (is => 'rw', isa => 'Num', printOrder => '5', default => '0', type => 'attribute', metaclass => 'Typed');
has cellwall => (is => 'rw', isa => 'Num', printOrder => '6', default => '0', type => 'attribute', metaclass => 'Typed');
has cofactor => (is => 'rw', isa => 'Num', printOrder => '7', default => '0', type => 'attribute', metaclass => 'Typed');
has energy => (is => 'rw', isa => 'Num', printOrder => '8', default => '0', type => 'attribute', metaclass => 'Typed');


# ANCESTOR:
has ancestor_uuid => (is => 'rw', isa => 'uuid', type => 'ancestor', metaclass => 'Typed');


# SUBOBJECTS:
has templateBiomassComponents => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(TemplateBiomassComponent)', metaclass => 'Typed', reader => '_templateBiomassComponents', printOrder => '-1');


# LINKS:


# BUILDERS:
sub _build_uuid { return Data::UUID->new()->create_str(); }


# CONSTANTS:
sub _type { return 'TemplateBiomass'; }

my $attributes = [
          {
            'req' => 1,
            'printOrder' => 0,
            'name' => 'uuid',
            'type' => 'ModelSEED::uuid',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => 1,
            'name' => 'name',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 1,
            'name' => 'type',
            'default' => 'defaultGrowth',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 2,
            'name' => 'other',
            'default' => '0',
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 2,
            'name' => 'dna',
            'default' => '0',
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 3,
            'name' => 'rna',
            'default' => '0',
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 4,
            'name' => 'protein',
            'default' => '0',
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 5,
            'name' => 'lipid',
            'default' => '0',
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 6,
            'name' => 'cellwall',
            'default' => '0',
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 7,
            'name' => 'cofactor',
            'default' => '0',
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 8,
            'name' => 'energy',
            'default' => '0',
            'type' => 'Num',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {uuid => 0, name => 1, type => 2, other => 3, dna => 4, rna => 5, protein => 6, lipid => 7, cellwall => 8, cofactor => 9, energy => 10};
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
            'name' => 'templateBiomassComponents',
            'type' => 'child',
            'class' => 'TemplateBiomassComponent'
          }
        ];

my $subobject_map = {templateBiomassComponents => 0};
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
around 'templateBiomassComponents' => sub {
  my ($orig, $self) = @_;
  return $self->_build_all_objects('templateBiomassComponents');
};


__PACKAGE__->meta->make_immutable;
1;
