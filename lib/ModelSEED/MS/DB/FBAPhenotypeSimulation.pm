########################################################################
# ModelSEED::MS::DB::FBAPhenotypeSimulation - This is the moose object corresponding to the FBAPhenotypeSimulation object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package ModelSEED::MS::DB::FBAPhenotypeSimulation;
use ModelSEED::MS::BaseObject;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'ModelSEED::MS::FBAFormulation', weak_ref => 1, type => 'parent', metaclass => 'Typed');


# ATTRIBUTES:
has uuid => (is => 'rw', isa => 'ModelSEED::uuid', printOrder => '0', lazy => 1, builder => '_build_uuid', type => 'attribute', metaclass => 'Typed');
has label => (is => 'rw', isa => 'Str', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');
has pH => (is => 'rw', isa => 'Num', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');
has temperature => (is => 'rw', isa => 'Num', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');
has additionalCpd_uuids => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', required => 1, default => sub{return [];}, type => 'attribute', metaclass => 'Typed');
has geneKO_uuids => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', required => 1, default => sub{return [];}, type => 'attribute', metaclass => 'Typed');
has reactionKO_uuids => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', required => 1, default => sub{return [];}, type => 'attribute', metaclass => 'Typed');
has media_uuid => (is => 'rw', isa => 'ModelSEED::uuid', printOrder => '-1', required => 1, type => 'attribute', metaclass => 'Typed');
has observedGrowthFraction => (is => 'rw', isa => 'Num', printOrder => '2', type => 'attribute', metaclass => 'Typed');


# ANCESTOR:
has ancestor_uuid => (is => 'rw', isa => 'uuid', type => 'ancestor', metaclass => 'Typed');


# LINKS:
has media => (is => 'rw', isa => 'ModelSEED::MS::Media', type => 'link(Biochemistry,media,media_uuid)', metaclass => 'Typed', lazy => 1, builder => '_build_media', weak_ref => 1);
has geneKOs => (is => 'rw', isa => 'ArrayRef[ModelSEED::MS::Feature]', type => 'link(Annotation,features,geneKO_uuids)', metaclass => 'Typed', lazy => 1, builder => '_build_geneKOs');
has reactionKOs => (is => 'rw', isa => 'ArrayRef[ModelSEED::MS::Reaction]', type => 'link(Biochemistry,reactions,reactionKO_uuids)', metaclass => 'Typed', lazy => 1, builder => '_build_reactionKOs');
has additionalCpds => (is => 'rw', isa => 'ArrayRef[ModelSEED::MS::Compound]', type => 'link(Biochemistry,compounds,additionalCpd_uuids)', metaclass => 'Typed', lazy => 1, builder => '_build_additionalCpds');


# BUILDERS:
sub _build_uuid { return Data::UUID->new()->create_str(); }
sub _build_media {
  my ($self) = @_;
  return $self->getLinkedObject('Biochemistry','media',$self->media_uuid());
}
sub _build_geneKOs {
  my ($self) = @_;
  return $self->getLinkedObjectArray('Annotation','features',$self->geneKO_uuids());
}
sub _build_reactionKOs {
  my ($self) = @_;
  return $self->getLinkedObjectArray('Biochemistry','reactions',$self->reactionKO_uuids());
}
sub _build_additionalCpds {
  my ($self) = @_;
  return $self->getLinkedObjectArray('Biochemistry','compounds',$self->additionalCpd_uuids());
}


# CONSTANTS:
sub _type { return 'FBAPhenotypeSimulation'; }

my $attributes = [
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'uuid',
            'type' => 'ModelSEED::uuid',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => 0,
            'name' => 'label',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => 0,
            'name' => 'pH',
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => 0,
            'name' => 'temperature',
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => -1,
            'name' => 'additionalCpd_uuids',
            'default' => 'sub{return [];}',
            'type' => 'ArrayRef',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => -1,
            'name' => 'geneKO_uuids',
            'default' => 'sub{return [];}',
            'type' => 'ArrayRef',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => -1,
            'name' => 'reactionKO_uuids',
            'default' => 'sub{return [];}',
            'type' => 'ArrayRef',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => -1,
            'name' => 'media_uuid',
            'type' => 'ModelSEED::uuid',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 2,
            'name' => 'observedGrowthFraction',
            'type' => 'Num',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {uuid => 0, label => 1, pH => 2, temperature => 3, additionalCpd_uuids => 4, geneKO_uuids => 5, reactionKO_uuids => 6, media_uuid => 7, observedGrowthFraction => 8};
sub _attributes {
  my ($self, $key) = @_;
  if (defined($key)) {
    my $ind = $attribute_map->{$key};
    if (defined($ind)) {
      return $attributes->[$ind];
    } else {
      return undef;
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
      return undef;
    }
  } else {
    return $subobjects;
  }
}


__PACKAGE__->meta->make_immutable;
1;
