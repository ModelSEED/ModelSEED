########################################################################
# ModelSEED::MS::DB::RegulatoryModelRegulon - This is the moose object corresponding to the RegulatoryModelRegulon object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package ModelSEED::MS::DB::RegulatoryModelRegulon;
use ModelSEED::MS::BaseObject;
use ModelSEED::MS::RegulonStimuli;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'ModelSEED::MS::RegulatoryModel', weak_ref => 1, type => 'parent', metaclass => 'Typed');


# ATTRIBUTES:
has uuid => (is => 'rw', isa => 'ModelSEED::uuid', printOrder => '0', lazy => 1, builder => '_build_uuid', type => 'attribute', metaclass => 'Typed');
has notes => (is => 'rw', isa => 'Str', printOrder => '3', default => '', type => 'attribute', metaclass => 'Typed');
has name => (is => 'rw', isa => 'ModelSEED::varchar', printOrder => '2', required => 1, type => 'attribute', metaclass => 'Typed');
has abbreviation => (is => 'rw', isa => 'ModelSEED::varchar', printOrder => '2', type => 'attribute', metaclass => 'Typed');
has feature_uuids => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub{return [];}, type => 'attribute', metaclass => 'Typed');
has regulator_uuids => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub{return [];}, type => 'attribute', metaclass => 'Typed');


# ANCESTOR:
has ancestor_uuid => (is => 'rw', isa => 'uuid', type => 'ancestor', metaclass => 'Typed');


# SUBOBJECTS:
has regulonStimuli => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(RegulonStimuli)', metaclass => 'Typed', reader => '_regulonStimuli', printOrder => '0');


# LINKS:
has features => (is => 'rw', type => 'link(Annotation,features,feature_uuids)', metaclass => 'Typed', lazy => 1, builder => '_build_features', clearer => 'clear_features', isa => 'ArrayRef');
has regulators => (is => 'rw', type => 'link(Annotation,features,regulator_uuids)', metaclass => 'Typed', lazy => 1, builder => '_build_regulators', clearer => 'clear_regulators', isa => 'ArrayRef');


# BUILDERS:
sub _build_uuid { return Data::UUID->new()->create_str(); }
sub _build_features {
  my ($self) = @_;
  return $self->getLinkedObjectArray('Annotation','features',$self->feature_uuids());
}
sub _build_regulators {
  my ($self) = @_;
  return $self->getLinkedObjectArray('Annotation','features',$self->regulator_uuids());
}


# CONSTANTS:
sub _type { return 'RegulatoryModelRegulon'; }

my $attributes = [
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'uuid',
            'type' => 'ModelSEED::uuid',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 3,
            'name' => 'notes',
            'default' => '',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => 2,
            'name' => 'name',
            'type' => 'ModelSEED::varchar',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 2,
            'name' => 'abbreviation',
            'type' => 'ModelSEED::varchar',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'feature_uuids',
            'default' => 'sub{return [];}',
            'type' => 'ArrayRef',
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

my $attribute_map = {uuid => 0, notes => 1, name => 2, abbreviation => 3, feature_uuids => 4, regulator_uuids => 5};
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
            'array' => 1,
            'attribute' => 'feature_uuids',
            'parent' => 'Annotation',
            'clearer' => 'clear_features',
            'name' => 'features',
            'class' => 'features',
            'method' => 'features'
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

my $link_map = {features => 0, regulators => 1};
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
            'name' => 'regulonStimuli',
            'type' => 'child',
            'class' => 'RegulonStimuli'
          }
        ];

my $subobject_map = {regulonStimuli => 0};
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
around 'regulonStimuli' => sub {
  my ($orig, $self) = @_;
  return $self->_build_all_objects('regulonStimuli');
};


__PACKAGE__->meta->make_immutable;
1;
