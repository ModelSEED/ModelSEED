########################################################################
# ModelSEED::MS::DB::Compound - This is the moose object corresponding to the Compound object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package ModelSEED::MS::DB::Compound;
use ModelSEED::MS::BaseObject;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'ModelSEED::MS::Biochemistry', weak_ref => 1, type => 'parent', metaclass => 'Typed');


# ATTRIBUTES:
has uuid => (is => 'rw', isa => 'ModelSEED::uuid', printOrder => '0', lazy => 1, builder => '_build_uuid', type => 'attribute', metaclass => 'Typed');
has isCofactor => (is => 'rw', isa => 'Bool', printOrder => '3', default => '0', type => 'attribute', metaclass => 'Typed');
has modDate => (is => 'rw', isa => 'Str', printOrder => '-1', lazy => 1, builder => '_build_modDate', type => 'attribute', metaclass => 'Typed');
has name => (is => 'rw', isa => 'ModelSEED::varchar', printOrder => '1', default => '', type => 'attribute', metaclass => 'Typed');
has abbreviation => (is => 'rw', isa => 'ModelSEED::varchar', printOrder => '2', default => '', type => 'attribute', metaclass => 'Typed');
has cksum => (is => 'rw', isa => 'ModelSEED::varchar', printOrder => '-1', default => '', type => 'attribute', metaclass => 'Typed');
has unchargedFormula => (is => 'rw', isa => 'ModelSEED::varchar', printOrder => '-1', default => '', type => 'attribute', metaclass => 'Typed');
has formula => (is => 'rw', isa => 'ModelSEED::varchar', printOrder => '3', default => '', type => 'attribute', metaclass => 'Typed');
has mass => (is => 'rw', isa => 'Num', printOrder => '4', type => 'attribute', metaclass => 'Typed');
has defaultCharge => (is => 'rw', isa => 'Num', printOrder => '5', default => '0', type => 'attribute', metaclass => 'Typed');
has deltaG => (is => 'rw', isa => 'Num', printOrder => '6', type => 'attribute', metaclass => 'Typed');
has deltaGErr => (is => 'rw', isa => 'Num', printOrder => '7', type => 'attribute', metaclass => 'Typed');
has abstractCompound_uuid => (is => 'rw', isa => 'ModelSEED::uuid', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has comprisedOfCompound_uuids => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has structure_uuids => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub{return [];}, type => 'attribute', metaclass => 'Typed');
has cue_uuids => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub{return [];}, type => 'attribute', metaclass => 'Typed');
has cueStoichiometry => (is => 'rw', isa => 'HashRef', printOrder => '-1', default => sub{return {};}, type => 'attribute', metaclass => 'Typed');
has pkas => (is => 'rw', isa => 'HashRef', printOrder => '-1', default => sub{return {};}, type => 'attribute', metaclass => 'Typed');
has pkbs => (is => 'rw', isa => 'HashRef', printOrder => '-1', default => sub{return {};}, type => 'attribute', metaclass => 'Typed');


# ANCESTOR:
has ancestor_uuid => (is => 'rw', isa => 'uuid', type => 'ancestor', metaclass => 'Typed');


# LINKS:
has abstractCompound => (is => 'rw', isa => 'ModelSEED::MS::Compound', type => 'link(Biochemistry,compounds,abstractCompound_uuid)', metaclass => 'Typed', lazy => 1, builder => '_build_abstractCompound', clearer => 'clear_abstractCompound', weak_ref => 1);
has comprisedOfCompounds => (is => 'rw', isa => 'ArrayRef[ModelSEED::MS::Compound]', type => 'link(Biochemistry,compounds,comprisedOfCompound_uuids)', metaclass => 'Typed', lazy => 1, builder => '_build_comprisedOfCompounds', clearer => 'clear_comprisedOfCompounds');
has cues => (is => 'rw', isa => 'ArrayRef[ModelSEED::MS::Cue]', type => 'link(Biochemistry,cues,cue_uuids)', metaclass => 'Typed', lazy => 1, builder => '_build_cues', clearer => 'clear_cues');
has structures => (is => 'rw', isa => 'ArrayRef[ModelSEED::MS::Structure]', type => 'link(BiochemistryStructures,structures,structure_uuids)', metaclass => 'Typed', lazy => 1, builder => '_build_structures', clearer => 'clear_structures');
has id => (is => 'rw', lazy => 1, builder => '_build_id', isa => 'Str', type => 'id', metaclass => 'Typed');


# BUILDERS:
sub _build_uuid { return Data::UUID->new()->create_str(); }
sub _build_modDate { return DateTime->now()->datetime(); }
sub _build_abstractCompound {
  my ($self) = @_;
  return $self->getLinkedObject('Biochemistry','compounds',$self->abstractCompound_uuid());
}
sub _build_comprisedOfCompounds {
  my ($self) = @_;
  return $self->getLinkedObjectArray('Biochemistry','compounds',$self->comprisedOfCompound_uuids());
}
sub _build_cues {
  my ($self) = @_;
  return $self->getLinkedObjectArray('Biochemistry','cues',$self->cue_uuids());
}
sub _build_structures {
  my ($self) = @_;
  return $self->getLinkedObjectArray('BiochemistryStructures','structures',$self->structure_uuids());
}


# CONSTANTS:
sub _type { return 'Compound'; }

my $attributes = [
          {
            'len' => 36,
            'req' => 0,
            'printOrder' => 0,
            'name' => 'uuid',
            'type' => 'ModelSEED::uuid',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 3,
            'name' => 'isCofactor',
            'default' => '0',
            'type' => 'Bool',
            'description' => 'A boolean indicating if this compound is a universal cofactor (e.g. water/H+).',
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
            'printOrder' => 2,
            'name' => 'abbreviation',
            'default' => '',
            'type' => 'ModelSEED::varchar',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'cksum',
            'default' => '',
            'type' => 'ModelSEED::varchar',
            'description' => 'A computed hash for the compound, not currently implemented',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'unchargedFormula',
            'default' => '',
            'type' => 'ModelSEED::varchar',
            'description' => 'Formula for compound if it does not have a ionic charge.',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 3,
            'name' => 'formula',
            'default' => '',
            'type' => 'ModelSEED::varchar',
            'description' => 'Formula for the compound at pH 7.',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 4,
            'name' => 'mass',
            'type' => 'Num',
            'description' => 'Atomic mass of the compound',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 5,
            'name' => 'defaultCharge',
            'default' => 0,
            'type' => 'Num',
            'description' => 'Computed charge for compound at pH 7.',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 6,
            'name' => 'deltaG',
            'type' => 'Num',
            'description' => 'Computed Gibbs free energy value for compound at pH 7.',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 7,
            'name' => 'deltaGErr',
            'type' => 'Num',
            'description' => 'Error bound on Gibbs free energy compoutation for compound.',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'abstractCompound_uuid',
            'type' => 'ModelSEED::uuid',
            'description' => 'Reference to abstract compound of which this compound is a specific class.',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'comprisedOfCompound_uuids',
            'type' => 'ArrayRef',
            'description' => 'Array of references to subcompounds that this compound is comprised of.',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'structure_uuids',
            'default' => 'sub{return [];}',
            'type' => 'ArrayRef',
            'description' => 'Array of associated molecular structures',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'cue_uuids',
            'default' => 'sub{return [];}',
            'type' => 'ArrayRef',
            'description' => 'Array of cue uuids',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'cueStoichiometry',
            'default' => 'sub{return {};}',
            'type' => 'HashRef',
            'description' => 'Hash of cue uuids with cue coefficients as values',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'pkas',
            'default' => 'sub{return {};}',
            'type' => 'HashRef',
            'description' => 'Hash of pKa values with atom numbers as values',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'pkbs',
            'default' => 'sub{return {};}',
            'type' => 'HashRef',
            'description' => 'Hash of pKb values with atom numbers as values',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {uuid => 0, isCofactor => 1, modDate => 2, name => 3, abbreviation => 4, cksum => 5, unchargedFormula => 6, formula => 7, mass => 8, defaultCharge => 9, deltaG => 10, deltaGErr => 11, abstractCompound_uuid => 12, comprisedOfCompound_uuids => 13, structure_uuids => 14, cue_uuids => 15, cueStoichiometry => 16, pkas => 17, pkbs => 18};
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
sub _aliasowner { return 'Biochemistry'; }


__PACKAGE__->meta->make_immutable;
1;
