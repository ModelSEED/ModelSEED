########################################################################
# ModelSEED::MS::DB::RegulonStimuli - This is the moose object corresponding to the RegulonStimuli object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package ModelSEED::MS::DB::RegulonStimuli;
use ModelSEED::MS::BaseObject;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'ModelSEED::MS::RegulatoryModelRegulon', weak_ref => 1, type => 'parent', metaclass => 'Typed');


# ATTRIBUTES:
has stimuli_uuid => (is => 'rw', isa => 'ModelSEED::uuid', printOrder => '-1', required => 1, type => 'attribute', metaclass => 'Typed');
has isInhibitor => (is => 'rw', isa => 'Bool', printOrder => '1', required => 1, type => 'attribute', metaclass => 'Typed');
has strength => (is => 'rw', isa => 'Num', printOrder => '2', default => '-1', type => 'attribute', metaclass => 'Typed');
has minConcentration => (is => 'rw', isa => 'Num', printOrder => '3', default => '-1', type => 'attribute', metaclass => 'Typed');
has maxConcentration => (is => 'rw', isa => 'Num', printOrder => '4', default => '-1', type => 'attribute', metaclass => 'Typed');
has regulator_uuids => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub{return [];}, type => 'attribute', metaclass => 'Typed');


# LINKS:
has stimuli => (is => 'rw', type => 'link(Mapping,stimuli,stimuli_uuid)', metaclass => 'Typed', lazy => 1, builder => '_build_stimuli', clearer => 'clear_stimuli', isa => 'ModelSEED::MS::stimuli', weak_ref => 1);
has regulators => (is => 'rw', type => 'link(Annotation,features,regulator_uuids)', metaclass => 'Typed', lazy => 1, builder => '_build_regulators', clearer => 'clear_regulators', isa => 'ArrayRef');


# BUILDERS:
sub _build_stimuli {
  my ($self) = @_;
  return $self->getLinkedObject('Mapping','stimuli',$self->stimuli_uuid());
}
sub _build_regulators {
  my ($self) = @_;
  return $self->getLinkedObjectArray('Annotation','features',$self->regulator_uuids());
}


# CONSTANTS:
sub _type { return 'RegulonStimuli'; }

my $attributes = [
          {
            'req' => 1,
            'printOrder' => -1,
            'name' => 'stimuli_uuid',
            'type' => 'ModelSEED::uuid',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => 1,
            'name' => 'isInhibitor',
            'type' => 'Bool',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 2,
            'name' => 'strength',
            'default' => '-1',
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 3,
            'name' => 'minConcentration',
            'default' => '-1',
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 4,
            'name' => 'maxConcentration',
            'default' => '-1',
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'regulator_uuids',
            'default' => 'sub{return [];}',
            'type' => 'ArrayRef',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {stimuli_uuid => 0, isInhibitor => 1, strength => 2, minConcentration => 3, maxConcentration => 4, regulator_uuids => 5};
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
            'attribute' => 'stimuli_uuid',
            'parent' => 'Mapping',
            'clearer' => 'clear_stimuli',
            'name' => 'stimuli',
            'class' => 'stimuli',
            'method' => 'stimuli'
          },
          {
            'array' => 1,
            'attribute' => 'regulator_uuids',
            'parent' => 'Annotation',
            'clearer' => 'clear_regulators',
            'name' => 'regulators',
            'class' => 'features',
            'method' => 'features'
          }
        ];

my $link_map = {stimuli => 0, regulators => 1};
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
