########################################################################
# ModelSEED::MS::DB::GapfillingFormulation - This is the moose object corresponding to the GapfillingFormulation object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package ModelSEED::MS::DB::GapfillingFormulation;
use ModelSEED::MS::BaseObject;
use ModelSEED::MS::GapfillingGeneCandidate;
use ModelSEED::MS::ReactionSetMultiplier;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'ModelSEED::Store', type => 'parent', metaclass => 'Typed');


# ATTRIBUTES:
has uuid => (is => 'rw', isa => 'ModelSEED::uuid', printOrder => '0', lazy => 1, builder => '_build_uuid', type => 'attribute', metaclass => 'Typed');
has fbaFormulation_uuid => (is => 'rw', isa => 'ModelSEED::uuid', printOrder => '0', type => 'attribute', metaclass => 'Typed');
has mediaHypothesis => (is => 'rw', isa => 'Bool', printOrder => '0', default => '0', type => 'attribute', metaclass => 'Typed');
has biomassHypothesis => (is => 'rw', isa => 'Bool', printOrder => '0', default => '0', type => 'attribute', metaclass => 'Typed');
has gprHypothesis => (is => 'rw', isa => 'Bool', printOrder => '0', default => '0', type => 'attribute', metaclass => 'Typed');
has reactionAdditionHypothesis => (is => 'rw', isa => 'Bool', printOrder => '0', default => '1', type => 'attribute', metaclass => 'Typed');
has balancedReactionsOnly => (is => 'rw', isa => 'Bool', printOrder => '0', default => '1', type => 'attribute', metaclass => 'Typed');
has guaranteedReaction_uuids => (is => 'rw', isa => 'ArrayRef', printOrder => '0', default => sub{return [];}, type => 'attribute', metaclass => 'Typed');
has blacklistedReaction_uuids => (is => 'rw', isa => 'ArrayRef', printOrder => '0', default => sub{return [];}, type => 'attribute', metaclass => 'Typed');
has allowableCompartment_uuids => (is => 'rw', isa => 'ArrayRef', printOrder => '0', default => sub{return [];}, type => 'attribute', metaclass => 'Typed');
has reactionActivationBonus => (is => 'rw', isa => 'Num', printOrder => '0', default => '0', type => 'attribute', metaclass => 'Typed');
has drainFluxMultiplier => (is => 'rw', isa => 'Num', printOrder => '0', default => '1', type => 'attribute', metaclass => 'Typed');
has directionalityMultiplier => (is => 'rw', isa => 'Num', printOrder => '0', default => '1', type => 'attribute', metaclass => 'Typed');
has deltaGMultiplier => (is => 'rw', isa => 'Num', printOrder => '0', default => '1', type => 'attribute', metaclass => 'Typed');
has noStructureMultiplier => (is => 'rw', isa => 'Num', printOrder => '0', default => '1', type => 'attribute', metaclass => 'Typed');
has noDeltaGMultiplier => (is => 'rw', isa => 'Num', printOrder => '0', default => '1', type => 'attribute', metaclass => 'Typed');
has biomassTransporterMultiplier => (is => 'rw', isa => 'Num', printOrder => '0', default => '1', type => 'attribute', metaclass => 'Typed');
has singleTransporterMultiplier => (is => 'rw', isa => 'Num', printOrder => '0', default => '1', type => 'attribute', metaclass => 'Typed');
has transporterMultiplier => (is => 'rw', isa => 'Num', printOrder => '0', default => '1', type => 'attribute', metaclass => 'Typed');
has modDate => (is => 'rw', isa => 'Str', printOrder => '-1', lazy => 1, builder => '_build_modDate', type => 'attribute', metaclass => 'Typed');


# ANCESTOR:
has ancestor_uuid => (is => 'rw', isa => 'uuid', type => 'ancestor', metaclass => 'Typed');


# SUBOBJECTS:
has gapfillingGeneCandidates => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'encompassed(GapfillingGeneCandidate)', metaclass => 'Typed', reader => '_gapfillingGeneCandidates', printOrder => '-1');
has reactionSetMultipliers => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'encompassed(ReactionSetMultiplier)', metaclass => 'Typed', reader => '_reactionSetMultipliers', printOrder => '-1');


# LINKS:
has fbaFormulation => (is => 'rw', isa => 'ModelSEED::MS::FBAFormulation', type => 'link(Model,fbaFormulations,fbaFormulation_uuid)', metaclass => 'Typed', lazy => 1, builder => '_build_fbaFormulation', weak_ref => 1);
has guaranteedReactions => (is => 'rw', isa => 'ArrayRef[ModelSEED::MS::Reaction]', type => 'link(Biochemistry,reactions,guaranteedReaction_uuids)', metaclass => 'Typed', lazy => 1, builder => '_build_guaranteedReactions');
has blacklistedReactions => (is => 'rw', isa => 'ArrayRef[ModelSEED::MS::Reaction]', type => 'link(Biochemistry,reactions,blacklistedReaction_uuids)', metaclass => 'Typed', lazy => 1, builder => '_build_blacklistedReactions');
has allowableCompartments => (is => 'rw', isa => 'ArrayRef[ModelSEED::MS::Compartment]', type => 'link(Biochemistry,compartments,allowableCompartment_uuids)', metaclass => 'Typed', lazy => 1, builder => '_build_allowableCompartments');


# BUILDERS:
sub _build_uuid { return Data::UUID->new()->create_str(); }
sub _build_modDate { return DateTime->now()->datetime(); }
sub _build_fbaFormulation {
  my ($self) = @_;
  return $self->getLinkedObject('Model','fbaFormulations',$self->fbaFormulation_uuid());
}
sub _build_guaranteedReactions {
  my ($self) = @_;
  return $self->getLinkedObjectArray('Biochemistry','reactions',$self->guaranteedReaction_uuids());
}
sub _build_blacklistedReactions {
  my ($self) = @_;
  return $self->getLinkedObjectArray('Biochemistry','reactions',$self->blacklistedReaction_uuids());
}
sub _build_allowableCompartments {
  my ($self) = @_;
  return $self->getLinkedObjectArray('Biochemistry','compartments',$self->allowableCompartment_uuids());
}


# CONSTANTS:
sub _type { return 'GapfillingFormulation'; }

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
            'printOrder' => 0,
            'name' => 'fbaFormulation_uuid',
            'type' => 'ModelSEED::uuid',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'mediaHypothesis',
            'default' => '0',
            'type' => 'Bool',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'biomassHypothesis',
            'default' => '0',
            'type' => 'Bool',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'gprHypothesis',
            'default' => '0',
            'type' => 'Bool',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'reactionAdditionHypothesis',
            'default' => '1',
            'type' => 'Bool',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'balancedReactionsOnly',
            'default' => '1',
            'type' => 'Bool',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'guaranteedReaction_uuids',
            'default' => 'sub{return [];}',
            'type' => 'ArrayRef',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'blacklistedReaction_uuids',
            'default' => 'sub{return [];}',
            'type' => 'ArrayRef',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'allowableCompartment_uuids',
            'default' => 'sub{return [];}',
            'type' => 'ArrayRef',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'reactionActivationBonus',
            'default' => '0',
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'drainFluxMultiplier',
            'default' => '1',
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'directionalityMultiplier',
            'default' => '1',
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'deltaGMultiplier',
            'default' => '1',
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'noStructureMultiplier',
            'default' => '1',
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'noDeltaGMultiplier',
            'default' => '1',
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'biomassTransporterMultiplier',
            'default' => '1',
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'singleTransporterMultiplier',
            'default' => '1',
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'transporterMultiplier',
            'default' => '1',
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'modDate',
            'type' => 'Str',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {uuid => 0, fbaFormulation_uuid => 1, mediaHypothesis => 2, biomassHypothesis => 3, gprHypothesis => 4, reactionAdditionHypothesis => 5, balancedReactionsOnly => 6, guaranteedReaction_uuids => 7, blacklistedReaction_uuids => 8, allowableCompartment_uuids => 9, reactionActivationBonus => 10, drainFluxMultiplier => 11, directionalityMultiplier => 12, deltaGMultiplier => 13, noStructureMultiplier => 14, noDeltaGMultiplier => 15, biomassTransporterMultiplier => 16, singleTransporterMultiplier => 17, transporterMultiplier => 18, modDate => 19};
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

my $subobjects = [
          {
            'printOrder' => -1,
            'name' => 'gapfillingGeneCandidates',
            'type' => 'encompassed',
            'class' => 'GapfillingGeneCandidate'
          },
          {
            'printOrder' => -1,
            'name' => 'reactionSetMultipliers',
            'type' => 'encompassed',
            'class' => 'ReactionSetMultiplier'
          }
        ];

my $subobject_map = {gapfillingGeneCandidates => 0, reactionSetMultipliers => 1};
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
around 'gapfillingGeneCandidates' => sub {
  my ($orig, $self) = @_;
  return $self->_build_all_objects('gapfillingGeneCandidates');
};
around 'reactionSetMultipliers' => sub {
  my ($orig, $self) = @_;
  return $self->_build_all_objects('reactionSetMultipliers');
};


__PACKAGE__->meta->make_immutable;
1;
