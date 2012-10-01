########################################################################
# ModelSEED::MS::DB::GapfillingSolutionReaction - This is the moose object corresponding to the GapfillingSolutionReaction object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package ModelSEED::MS::DB::GapfillingSolutionReaction;
use ModelSEED::MS::BaseObject;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'ModelSEED::MS::GapfillingSolution', weak_ref => 1, type => 'parent', metaclass => 'Typed');


# ATTRIBUTES:
has reaction_uuid => (is => 'rw', isa => 'ModelSEED::uuid', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');
has compartment_uuid => (is => 'rw', isa => 'ModelSEED::uuid', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');
has direction => (is => 'rw', isa => 'Str', printOrder => '0', default => '1', type => 'attribute', metaclass => 'Typed');
has candidateFeature_uuids => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub{return [];}, type => 'attribute', metaclass => 'Typed');


# LINKS:
has reaction => (is => 'rw', isa => 'ModelSEED::MS::Reaction', type => 'link(Biochemistry,reactions,reaction_uuid)', metaclass => 'Typed', lazy => 1, builder => '_build_reaction', clearer => 'clear_reaction', weak_ref => 1);
has candidateFeatures => (is => 'rw', isa => 'ArrayRef[ModelSEED::MS::Feature]', type => 'link(Annotation,features,candidateFeature_uuids)', metaclass => 'Typed', lazy => 1, builder => '_build_candidateFeatures', clearer => 'clear_candidateFeatures');


# BUILDERS:
sub _build_reaction {
  my ($self) = @_;
  return $self->getLinkedObject('Biochemistry','reactions',$self->reaction_uuid());
}
sub _build_candidateFeatures {
  my ($self) = @_;
  return $self->getLinkedObjectArray('Annotation','features',$self->candidateFeature_uuids());
}


# CONSTANTS:
sub _type { return 'GapfillingSolutionReaction'; }

my $attributes = [
          {
            'req' => 1,
            'printOrder' => 0,
            'name' => 'reaction_uuid',
            'type' => 'ModelSEED::uuid',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => 0,
            'name' => 'compartment_uuid',
            'type' => 'ModelSEED::uuid',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'direction',
            'default' => '1',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'candidateFeature_uuids',
            'default' => 'sub{return [];}',
            'type' => 'ArrayRef',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {reaction_uuid => 0, compartment_uuid => 1, direction => 2, candidateFeature_uuids => 3};
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

<<<<<<< HEAD
my $subobjects = [];
=======
my $links = [
          {
            'attribute' => 'modelreaction_uuid',
            'parent' => 'Model',
            'clearer' => 'clear_modelreaction',
            'name' => 'modelreaction',
            'class' => 'modelreactions',
            'method' => 'modelreactions'
          }
        ];

my $link_map = {modelreaction => 0};
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
            'name' => 'gfSolutionReactionGeneCandidates',
            'type' => 'encompassed',
            'class' => 'GfSolutionReactionGeneCandidate'
          }
        ];
>>>>>>> linkupdate_mergecpd_command

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
