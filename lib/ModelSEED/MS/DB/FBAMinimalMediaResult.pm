########################################################################
# ModelSEED::MS::DB::FBAMinimalMediaResult - This is the moose object corresponding to the FBAMinimalMediaResult object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package ModelSEED::MS::DB::FBAMinimalMediaResult;
use ModelSEED::MS::BaseObject;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'ModelSEED::MS::FBAResult', weak_ref => 1, type => 'parent', metaclass => 'Typed');


# ATTRIBUTES:
has minimalMedia_uuid => (is => 'rw', isa => 'ModelSEED::uuid', printOrder => '-1', required => 1, trigger => &_trigger_minimalMedia_uuid, type => 'attribute', metaclass => 'Typed');
has essentialNutrient_uuids => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', required => 1, trigger => &_trigger_essentialNutrient_uuids, type => 'attribute', metaclass => 'Typed');
has optionalNutrient_uuids => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', required => 1, trigger => &_trigger_optionalNutrient_uuids, type => 'attribute', metaclass => 'Typed');


# LINKS:
has minimalMedia => (is => 'rw', type => 'link(Biochemistry,media,minimalMedia_uuid)', metaclass => 'Typed', lazy => 1, builder => '_build_minimalMedia', clearer => 'clear_minimalMedia', trigger => &_trigger_minimalMedia, isa => 'ModelSEED::MS::Media', weak_ref => 1);
has essentialNutrients => (is => 'rw', type => 'link(Biochemistry,compounds,essentialNutrient_uuids)', metaclass => 'Typed', lazy => 1, builder => '_build_essentialNutrients', clearer => 'clear_essentialNutrients', trigger => &_trigger_essentialNutrients, isa => 'ArrayRef');
has optionalNutrients => (is => 'rw', type => 'link(Biochemistry,compounds,optionalNutrient_uuids)', metaclass => 'Typed', lazy => 1, builder => '_build_optionalNutrients', clearer => 'clear_optionalNutrients', trigger => &_trigger_optionalNutrients, isa => 'ArrayRef');


# BUILDERS:
sub _build_minimalMedia {
  my ($self) = @_;
  return $self->getLinkedObject('Biochemistry','media',$self->minimalMedia_uuid());
}
sub _trigger_minimalMedia {
   my ($self, $new, $old) = @_;
   $self->minimalMedia_uuid( $new->uuid );
}
sub _trigger_minimalMedia_uuid {
    my ($self, $new, $old) = @_;
    $self->clear_minimalMedia if( $self->minimalMedia->uuid ne $new );
}
sub _build_essentialNutrients {
  my ($self) = @_;
  return $self->getLinkedObjectArray('Biochemistry','compounds',$self->essentialNutrient_uuids());
}
sub _trigger_essentialNutrients {
   my ($self, $new, $old) = @_;
   $self->essentialNutrient_uuids( $new->uuid );
}
sub _trigger_essentialNutrient_uuids {
    my ($self, $new, $old) = @_;
    $self->clear_essentialNutrients if( $self->essentialNutrients->uuid ne $new );
}
sub _build_optionalNutrients {
  my ($self) = @_;
  return $self->getLinkedObjectArray('Biochemistry','compounds',$self->optionalNutrient_uuids());
}
sub _trigger_optionalNutrients {
   my ($self, $new, $old) = @_;
   $self->optionalNutrient_uuids( $new->uuid );
}
sub _trigger_optionalNutrient_uuids {
    my ($self, $new, $old) = @_;
    $self->clear_optionalNutrients if( $self->optionalNutrients->uuid ne $new );
}


# CONSTANTS:
sub _type { return 'FBAMinimalMediaResult'; }

my $attributes = [
          {
            'req' => 1,
            'printOrder' => -1,
            'name' => 'minimalMedia_uuid',
            'type' => 'ModelSEED::uuid',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => -1,
            'name' => 'essentialNutrient_uuids',
            'type' => 'ArrayRef',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => -1,
            'name' => 'optionalNutrient_uuids',
            'type' => 'ArrayRef',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {minimalMedia_uuid => 0, essentialNutrient_uuids => 1, optionalNutrient_uuids => 2};
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
            'attribute' => 'minimalMedia_uuid',
            'parent' => 'Biochemistry',
            'clearer' => 'clear_minimalMedia',
            'name' => 'minimalMedia',
            'class' => 'media',
            'method' => 'media'
          },
          {
            'array' => 1,
            'attribute' => 'essentialNutrient_uuids',
            'parent' => 'Biochemistry',
            'clearer' => 'clear_essentialNutrients',
            'name' => 'essentialNutrients',
            'class' => 'compounds',
            'method' => 'compounds'
          },
          {
            'array' => 1,
            'attribute' => 'optionalNutrient_uuids',
            'parent' => 'Biochemistry',
            'clearer' => 'clear_optionalNutrients',
            'name' => 'optionalNutrients',
            'class' => 'compounds',
            'method' => 'compounds'
          }
        ];

my $link_map = {minimalMedia => 0, essentialNutrients => 1, optionalNutrients => 2};
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
