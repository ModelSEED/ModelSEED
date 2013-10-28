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
use ModelSEED::MS::GapfillingSolution;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');


# ATTRIBUTES:
has uuid => (is => 'rw', isa => 'ModelSEED::uuid', printOrder => '0', lazy => 1, builder => '_build_uuid', type => 'attribute', metaclass => 'Typed');
has fbaFormulation_uuid => (is => 'rw', isa => 'Str', printOrder => '1', type => 'attribute', metaclass => 'Typed');
has model_uuid => (is => 'rw', isa => 'Str', printOrder => '-1', required => 1, type => 'attribute', metaclass => 'Typed');
has mediaHypothesis => (is => 'rw', isa => 'Bool', printOrder => '2', default => '0', type => 'attribute', metaclass => 'Typed');
has biomassHypothesis => (is => 'rw', isa => 'Bool', printOrder => '3', default => '0', type => 'attribute', metaclass => 'Typed');
has gprHypothesis => (is => 'rw', isa => 'Bool', printOrder => '4', default => '0', type => 'attribute', metaclass => 'Typed');
has reactionAdditionHypothesis => (is => 'rw', isa => 'Bool', printOrder => '5', default => '1', type => 'attribute', metaclass => 'Typed');
has balancedReactionsOnly => (is => 'rw', isa => 'Bool', printOrder => '6', default => '1', type => 'attribute', metaclass => 'Typed');
has guaranteedReaction_uuids => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub{return [];}, type => 'attribute', metaclass => 'Typed');
has targetedreaction_uuids => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub{return [];}, type => 'attribute', metaclass => 'Typed');
has blacklistedReaction_uuids => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub{return [];}, type => 'attribute', metaclass => 'Typed');
has allowableCompartment_uuids => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub{return [];}, type => 'attribute', metaclass => 'Typed');
has reactionActivationBonus => (is => 'rw', isa => 'Num', printOrder => '7', default => '0', type => 'attribute', metaclass => 'Typed');
has drainFluxMultiplier => (is => 'rw', isa => 'Num', printOrder => '8', default => '1', type => 'attribute', metaclass => 'Typed');
has directionalityMultiplier => (is => 'rw', isa => 'Num', printOrder => '9', default => '1', type => 'attribute', metaclass => 'Typed');
has deltaGMultiplier => (is => 'rw', isa => 'Num', printOrder => '10', default => '1', type => 'attribute', metaclass => 'Typed');
has noStructureMultiplier => (is => 'rw', isa => 'Num', printOrder => '11', default => '1', type => 'attribute', metaclass => 'Typed');
has noDeltaGMultiplier => (is => 'rw', isa => 'Num', printOrder => '12', default => '1', type => 'attribute', metaclass => 'Typed');
has biomassTransporterMultiplier => (is => 'rw', isa => 'Num', printOrder => '13', default => '1', type => 'attribute', metaclass => 'Typed');
has singleTransporterMultiplier => (is => 'rw', isa => 'Num', printOrder => '14', default => '1', type => 'attribute', metaclass => 'Typed');
has transporterMultiplier => (is => 'rw', isa => 'Num', printOrder => '15', default => '1', type => 'attribute', metaclass => 'Typed');
has modDate => (is => 'rw', isa => 'Str', printOrder => '-1', lazy => 1, builder => '_build_modDate', type => 'attribute', metaclass => 'Typed');
has timePerSolution => (is => 'rw', isa => 'Int', printOrder => '16', type => 'attribute', metaclass => 'Typed');
has totalTimeLimit => (is => 'rw', isa => 'Int', printOrder => '17', type => 'attribute', metaclass => 'Typed');
has completeGapfill => (is => 'rw', isa => 'Bool', printOrder => '18', default => '0', type => 'attribute', metaclass => 'Typed');


# ANCESTOR:
has ancestor_uuid => (is => 'rw', isa => 'uuid', type => 'ancestor', metaclass => 'Typed');


# SUBOBJECTS:
has gapfillingGeneCandidates => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'encompassed(GapfillingGeneCandidate)', metaclass => 'Typed', reader => '_gapfillingGeneCandidates', printOrder => '-1');
has reactionSetMultipliers => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'encompassed(ReactionSetMultiplier)', metaclass => 'Typed', reader => '_reactionSetMultipliers', printOrder => '-1');
has gapfillingSolutions => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'encompassed(GapfillingSolution)', metaclass => 'Typed', reader => '_gapfillingSolutions', printOrder => '0');


# LINKS:
has model => (is => 'rw', type => 'link(ModelSEED::Store,Model,model_uuid)', metaclass => 'Typed', lazy => 1, builder => '_build_model', clearer => 'clear_model', isa => 'ModelSEED::MS::Model');
has fbaFormulation => (is => 'rw', type => 'link(ModelSEED::Store,FBAFormulation,fbaFormulation_uuid)', metaclass => 'Typed', lazy => 1, builder => '_build_fbaFormulation', clearer => 'clear_fbaFormulation', isa => 'ModelSEED::MS::FBAFormulation');
has guaranteedReactions => (is => 'rw', type => 'link(Biochemistry,reactions,guaranteedReaction_uuids)', metaclass => 'Typed', lazy => 1, builder => '_build_guaranteedReactions', clearer => 'clear_guaranteedReactions', isa => 'ArrayRef');
has targetedreactions => (is => 'rw', type => 'link(Biochemistry,reactions,targetedreaction_uuids)', metaclass => 'Typed', lazy => 1, builder => '_build_targetedreactions', clearer => 'clear_targetedreactions', isa => 'ArrayRef');
has blacklistedReactions => (is => 'rw', type => 'link(Biochemistry,reactions,blacklistedReaction_uuids)', metaclass => 'Typed', lazy => 1, builder => '_build_blacklistedReactions', clearer => 'clear_blacklistedReactions', isa => 'ArrayRef');
has allowableCompartments => (is => 'rw', type => 'link(Biochemistry,compartments,allowableCompartment_uuids)', metaclass => 'Typed', lazy => 1, builder => '_build_allowableCompartments', clearer => 'clear_allowableCompartments', isa => 'ArrayRef');


# BUILDERS:
sub _build_uuid { return Data::UUID->new()->create_str(); }
sub _build_modDate { return DateTime->now()->datetime(); }
sub _build_model {
  my ($self) = @_;
  return $self->getLinkedObject('ModelSEED::Store','Model',$self->model_uuid());
}
sub _build_fbaFormulation {
  my ($self) = @_;
  return $self->getLinkedObject('ModelSEED::Store','FBAFormulation',$self->fbaFormulation_uuid());
}
sub _build_guaranteedReactions {
  my ($self) = @_;
  return $self->getLinkedObjectArray('Biochemistry','reactions',$self->guaranteedReaction_uuids());
}
sub _build_targetedreactions {
  my ($self) = @_;
  return $self->getLinkedObjectArray('Biochemistry','reactions',$self->targetedreaction_uuids());
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
            'printOrder' => 1,
            'name' => 'fbaFormulation_uuid',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => -1,
            'name' => 'model_uuid',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 2,
            'name' => 'mediaHypothesis',
            'default' => '0',
            'type' => 'Bool',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 3,
            'name' => 'biomassHypothesis',
            'default' => '0',
            'type' => 'Bool',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 4,
            'name' => 'gprHypothesis',
            'default' => '0',
            'type' => 'Bool',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 5,
            'name' => 'reactionAdditionHypothesis',
            'default' => '1',
            'type' => 'Bool',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 6,
            'name' => 'balancedReactionsOnly',
            'default' => '1',
            'type' => 'Bool',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'guaranteedReaction_uuids',
            'default' => 'sub{return [];}',
            'type' => 'ArrayRef',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'targetedreaction_uuids',
            'default' => 'sub{return [];}',
            'type' => 'ArrayRef',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'blacklistedReaction_uuids',
            'default' => 'sub{return [];}',
            'type' => 'ArrayRef',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'allowableCompartment_uuids',
            'default' => 'sub{return [];}',
            'type' => 'ArrayRef',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 7,
            'name' => 'reactionActivationBonus',
            'default' => '0',
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 8,
            'name' => 'drainFluxMultiplier',
            'default' => '1',
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 9,
            'name' => 'directionalityMultiplier',
            'default' => '1',
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 10,
            'name' => 'deltaGMultiplier',
            'default' => '1',
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 11,
            'name' => 'noStructureMultiplier',
            'default' => '1',
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 12,
            'name' => 'noDeltaGMultiplier',
            'default' => '1',
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 13,
            'name' => 'biomassTransporterMultiplier',
            'default' => '1',
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 14,
            'name' => 'singleTransporterMultiplier',
            'default' => '1',
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 15,
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
          },
          {
            'req' => 0,
            'printOrder' => 16,
            'name' => 'timePerSolution',
            'type' => 'Int',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 17,
            'name' => 'totalTimeLimit',
            'type' => 'Int',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 18,
            'name' => 'completeGapfill',
            'default' => '0',
            'type' => 'Bool',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {uuid => 0, fbaFormulation_uuid => 1, model_uuid => 2, mediaHypothesis => 3, biomassHypothesis => 4, gprHypothesis => 5, reactionAdditionHypothesis => 6, balancedReactionsOnly => 7, guaranteedReaction_uuids => 8, targetedreaction_uuids => 9, blacklistedReaction_uuids => 10, allowableCompartment_uuids => 11, reactionActivationBonus => 12, drainFluxMultiplier => 13, directionalityMultiplier => 14, deltaGMultiplier => 15, noStructureMultiplier => 16, noDeltaGMultiplier => 17, biomassTransporterMultiplier => 18, singleTransporterMultiplier => 19, transporterMultiplier => 20, modDate => 21, timePerSolution => 22, totalTimeLimit => 23, completeGapfill => 24};
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
            'attribute' => 'model_uuid',
            'weak' => 0,
            'parent' => 'ModelSEED::Store',
            'clearer' => 'clear_model',
            'name' => 'model',
            'class' => 'Model',
            'method' => 'Model'
          },
          {
            'attribute' => 'fbaFormulation_uuid',
            'weak' => 0,
            'parent' => 'ModelSEED::Store',
            'clearer' => 'clear_fbaFormulation',
            'name' => 'fbaFormulation',
            'class' => 'FBAFormulation',
            'method' => 'FBAFormulation'
          },
          {
            'array' => 1,
            'attribute' => 'guaranteedReaction_uuids',
            'parent' => 'Biochemistry',
            'clearer' => 'clear_guaranteedReactions',
            'name' => 'guaranteedReactions',
            'class' => 'reactions',
            'method' => 'reactions'
          },
          {
            'array' => 1,
            'attribute' => 'targetedreaction_uuids',
            'parent' => 'Biochemistry',
            'clearer' => 'clear_targetedreactions',
            'name' => 'targetedreactions',
            'class' => 'reactions',
            'method' => 'reactions'
          },
          {
            'array' => 1,
            'attribute' => 'blacklistedReaction_uuids',
            'parent' => 'Biochemistry',
            'clearer' => 'clear_blacklistedReactions',
            'name' => 'blacklistedReactions',
            'class' => 'reactions',
            'method' => 'reactions'
          },
          {
            'array' => 1,
            'attribute' => 'allowableCompartment_uuids',
            'parent' => 'Biochemistry',
            'clearer' => 'clear_allowableCompartments',
            'name' => 'allowableCompartments',
            'class' => 'compartments',
            'method' => 'compartments'
          }
        ];

my $link_map = {model => 0, fbaFormulation => 1, guaranteedReactions => 2, targetedreactions => 3, blacklistedReactions => 4, allowableCompartments => 5};
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
            'name' => 'gapfillingGeneCandidates',
            'type' => 'encompassed',
            'class' => 'GapfillingGeneCandidate'
          },
          {
            'printOrder' => -1,
            'name' => 'reactionSetMultipliers',
            'type' => 'encompassed',
            'class' => 'ReactionSetMultiplier'
          },
          {
            'printOrder' => 0,
            'name' => 'gapfillingSolutions',
            'type' => 'encompassed',
            'class' => 'GapfillingSolution'
          }
        ];

my $subobject_map = {gapfillingGeneCandidates => 0, reactionSetMultipliers => 1, gapfillingSolutions => 2};
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
around 'gapfillingSolutions' => sub {
  my ($orig, $self) = @_;
  return $self->_build_all_objects('gapfillingSolutions');
};


__PACKAGE__->meta->make_immutable;
1;
