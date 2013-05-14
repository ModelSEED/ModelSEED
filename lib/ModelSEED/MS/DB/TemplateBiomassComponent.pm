########################################################################
# ModelSEED::MS::DB::TemplateBiomassComponent - This is the moose object corresponding to the TemplateBiomassComponent object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package ModelSEED::MS::DB::TemplateBiomassComponent;
use ModelSEED::MS::BaseObject;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'ModelSEED::MS::TemplateBiomass', weak_ref => 1, type => 'parent', metaclass => 'Typed');


# ATTRIBUTES:
has uuid => (is => 'rw', isa => 'ModelSEED::uuid', printOrder => '0', required => 1, lazy => 1, builder => '_build_uuid', type => 'attribute', metaclass => 'Typed');
has class => (is => 'rw', isa => 'Str', printOrder => '1', default => '0', type => 'attribute', metaclass => 'Typed');
has universal => (is => 'rw', isa => 'Bool', printOrder => '2', default => '0', type => 'attribute', metaclass => 'Typed');
has compound_uuid => (is => 'rw', isa => 'Str', printOrder => '-1', required => 1, type => 'attribute', metaclass => 'Typed');
has compartment_uuid => (is => 'rw', isa => 'Str', printOrder => '-1', required => 1, type => 'attribute', metaclass => 'Typed');
has linkedCompound_uuids => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub{return [];}, type => 'attribute', metaclass => 'Typed');
has coefficientType => (is => 'rw', isa => 'Str', printOrder => '3', default => '0', type => 'attribute', metaclass => 'Typed');
has coefficient => (is => 'rw', isa => 'Num', printOrder => '4', default => '1', type => 'attribute', metaclass => 'Typed');
has linkCoefficients => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub{return [];}, type => 'attribute', metaclass => 'Typed');
has classifierClassification_uuid => (is => 'rw', isa => 'Str', printOrder => '-1', default => '', type => 'attribute', metaclass => 'Typed');
has classifier_uuid => (is => 'rw', isa => 'Str', printOrder => '-1', default => '', type => 'attribute', metaclass => 'Typed');


# ANCESTOR:
has ancestor_uuid => (is => 'rw', isa => 'uuid', type => 'ancestor', metaclass => 'Typed');


# LINKS:
has compound => (is => 'rw', type => 'link(Biochemistry,compounds,compound_uuid)', metaclass => 'Typed', lazy => 1, builder => '_build_compound', clearer => 'clear_compound', isa => 'ModelSEED::MS::Compound', weak_ref => 1);
has compartment => (is => 'rw', type => 'link(Biochemistry,compartments,compartment_uuid)', metaclass => 'Typed', lazy => 1, builder => '_build_compartment', clearer => 'clear_compartment', isa => 'ModelSEED::MS::Compartment', weak_ref => 1);
has linkedCompounds => (is => 'rw', type => 'link(Biochemistry,compounds,linkedCompound_uuids)', metaclass => 'Typed', lazy => 1, builder => '_build_linkedCompounds', clearer => 'clear_linkedCompounds', isa => 'ArrayRef');
has classifierClassification => (is => 'rw', type => 'link(Classifier,classifierClassifications,classifierClassification_uuid)', metaclass => 'Typed', lazy => 1, builder => '_build_classifierClassification', clearer => 'clear_classifierClassification', isa => 'ArrayRef');
has classifier => (is => 'rw', type => 'link(ModelSEED::Store,Classifier,classifier_uuid)', metaclass => 'Typed', lazy => 1, builder => '_build_classifier', clearer => 'clear_classifier', isa => 'ModelSEED::MS::Classifier');


# BUILDERS:
sub _build_uuid { return Data::UUID->new()->create_str(); }
sub _build_compound {
  my ($self) = @_;
  return $self->getLinkedObject('Biochemistry','compounds',$self->compound_uuid());
}
sub _build_compartment {
  my ($self) = @_;
  return $self->getLinkedObject('Biochemistry','compartments',$self->compartment_uuid());
}
sub _build_linkedCompounds {
  my ($self) = @_;
  return $self->getLinkedObjectArray('Biochemistry','compounds',$self->linkedCompound_uuids());
}
sub _build_classifierClassification {
  my ($self) = @_;
  return $self->getLinkedObjectArray('Classifier','classifierClassifications',$self->classifierClassification_uuid());
}
sub _build_classifier {
  my ($self) = @_;
  return $self->getLinkedObject('ModelSEED::Store','Classifier',$self->classifier_uuid());
}


# CONSTANTS:
sub _type { return 'TemplateBiomassComponent'; }

my $attributes = [
          {
            'req' => 1,
            'printOrder' => 0,
            'name' => 'uuid',
            'type' => 'ModelSEED::uuid',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 1,
            'name' => 'class',
            'default' => '0',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'printOrder' => 2,
            'name' => 'universal',
            'default' => 0,
            'type' => 'Bool',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => -1,
            'name' => 'compound_uuid',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => -1,
            'name' => 'compartment_uuid',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'linkedCompound_uuids',
            'default' => 'sub{return [];}',
            'type' => 'ArrayRef',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 3,
            'name' => 'coefficientType',
            'default' => '0',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 4,
            'name' => 'coefficient',
            'default' => '1',
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'linkCoefficients',
            'default' => 'sub{return [];}',
            'type' => 'ArrayRef',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'classifierClassification_uuid',
            'default' => '',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'classifier_uuid',
            'default' => '',
            'type' => 'Str',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {uuid => 0, class => 1, universal => 2, compound_uuid => 3, compartment_uuid => 4, linkedCompound_uuids => 5, coefficientType => 6, coefficient => 7, linkCoefficients => 8, classifierClassification_uuid => 9, classifier_uuid => 10};
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
            'attribute' => 'compound_uuid',
            'parent' => 'Biochemistry',
            'clearer' => 'clear_compound',
            'name' => 'compound',
            'class' => 'compounds',
            'method' => 'compounds'
          },
          {
            'attribute' => 'compartment_uuid',
            'parent' => 'Biochemistry',
            'clearer' => 'clear_compartment',
            'name' => 'compartment',
            'class' => 'compartments',
            'method' => 'compartments'
          },
          {
            'array' => 1,
            'attribute' => 'linkedCompound_uuids',
            'parent' => 'Biochemistry',
            'clearer' => 'clear_linkedCompounds',
            'name' => 'linkedCompounds',
            'class' => 'compounds',
            'method' => 'compounds'
          },
          {
            'array' => 1,
            'attribute' => 'classifierClassification_uuid',
            'parent' => 'Classifier',
            'clearer' => 'clear_classifierClassification',
            'name' => 'classifierClassification',
            'class' => 'classifierClassifications',
            'method' => 'classifierClassifications'
          },
          {
            'attribute' => 'classifier_uuid',
            'weak' => 0,
            'parent' => 'ModelSEED::Store',
            'clearer' => 'clear_classifier',
            'name' => 'classifier',
            'class' => 'Classifier',
            'method' => 'Classifier'
          }
        ];

my $link_map = {compound => 0, compartment => 1, linkedCompounds => 2, classifierClassification => 3, classifier => 4};
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
