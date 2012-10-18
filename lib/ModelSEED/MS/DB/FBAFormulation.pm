########################################################################
# ModelSEED::MS::DB::FBAFormulation - This is the moose object corresponding to the FBAFormulation object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package ModelSEED::MS::DB::FBAFormulation;
use ModelSEED::MS::IndexedObject;
use ModelSEED::MS::FBAObjectiveTerm;
use ModelSEED::MS::FBAConstraint;
use ModelSEED::MS::FBAReactionBound;
use ModelSEED::MS::FBACompoundBound;
use ModelSEED::MS::FBAResult;
use ModelSEED::MS::FBAPhenotypeSimulation;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::IndexedObject';


# PARENT:
has parent => (is => 'rw', isa => 'ModelSEED::Store', type => 'parent', metaclass => 'Typed');


# ATTRIBUTES:
has uuid => (is => 'rw', isa => 'ModelSEED::uuid', printOrder => '-1', lazy => 1, builder => '_build_uuid', type => 'attribute', metaclass => 'Typed');
has modDate => (is => 'rw', isa => 'Str', printOrder => '-1', lazy => 1, builder => '_build_modDate', type => 'attribute', metaclass => 'Typed');
has regulatorymodel_uuid => (is => 'rw', isa => 'ModelSEED::uuid', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has model_uuid => (is => 'rw', isa => 'ModelSEED::uuid', printOrder => '-1', required => 1, trigger => &_trigger_model_uuid, type => 'attribute', metaclass => 'Typed');
has media_uuid => (is => 'rw', isa => 'ModelSEED::uuid', printOrder => '-1', required => 1, trigger => &_trigger_media_uuid, type => 'attribute', metaclass => 'Typed');
has secondaryMedia_uuids => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub{return [];}, trigger => &_trigger_secondaryMedia_uuids, type => 'attribute', metaclass => 'Typed');
has fva => (is => 'rw', isa => 'Bool', printOrder => '10', default => '0', type => 'attribute', metaclass => 'Typed');
has comboDeletions => (is => 'rw', isa => 'Int', printOrder => '11', default => '0', type => 'attribute', metaclass => 'Typed');
has fluxMinimization => (is => 'rw', isa => 'Bool', printOrder => '12', default => '0', type => 'attribute', metaclass => 'Typed');
has findMinimalMedia => (is => 'rw', isa => 'Bool', printOrder => '13', default => '0', type => 'attribute', metaclass => 'Typed');
has notes => (is => 'rw', isa => 'Str', printOrder => '-1', default => '', type => 'attribute', metaclass => 'Typed');
has expressionData_uuid => (is => 'rw', isa => 'ModelSEED::uuid', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has objectiveConstraintFraction => (is => 'rw', isa => 'ModelSEED::varchar', printOrder => '0', default => 'none', type => 'attribute', metaclass => 'Typed');
has allReversible => (is => 'rw', isa => 'Int', printOrder => '14', default => '0', type => 'attribute', metaclass => 'Typed');
has defaultMaxFlux => (is => 'rw', isa => 'Int', printOrder => '20', required => 1, default => '1000', type => 'attribute', metaclass => 'Typed');
has defaultMaxDrainFlux => (is => 'rw', isa => 'Int', printOrder => '22', required => 1, default => '1000', type => 'attribute', metaclass => 'Typed');
has defaultMinDrainFlux => (is => 'rw', isa => 'Int', printOrder => '21', required => 1, default => '-1000', type => 'attribute', metaclass => 'Typed');
has maximizeObjective => (is => 'rw', isa => 'Bool', printOrder => '-1', required => 1, default => '1', type => 'attribute', metaclass => 'Typed');
has decomposeReversibleFlux => (is => 'rw', isa => 'Bool', printOrder => '-1', default => '0', type => 'attribute', metaclass => 'Typed');
has decomposeReversibleDrainFlux => (is => 'rw', isa => 'Bool', printOrder => '-1', default => '0', type => 'attribute', metaclass => 'Typed');
has fluxUseVariables => (is => 'rw', isa => 'Bool', printOrder => '-1', default => '0', type => 'attribute', metaclass => 'Typed');
has drainfluxUseVariables => (is => 'rw', isa => 'Bool', printOrder => '-1', default => '0', type => 'attribute', metaclass => 'Typed');
has geneKO_uuids => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub{return [];}, trigger => &_trigger_geneKO_uuids, type => 'attribute', metaclass => 'Typed');
has reactionKO_uuids => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub{return [];}, trigger => &_trigger_reactionKO_uuids, type => 'attribute', metaclass => 'Typed');
has parameters => (is => 'rw', isa => 'HashRef', printOrder => '-1', default => sub{return {};}, type => 'attribute', metaclass => 'Typed');
has inputfiles => (is => 'rw', isa => 'HashRef', printOrder => '-1', default => sub{return {};}, type => 'attribute', metaclass => 'Typed');
has outputfiles => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub{return [];}, type => 'attribute', metaclass => 'Typed');
has uptakeLimits => (is => 'rw', isa => 'HashRef', printOrder => '-1', default => sub{return {};}, type => 'attribute', metaclass => 'Typed');
has numberOfSolutions => (is => 'rw', isa => 'Int', printOrder => '23', default => '1', type => 'attribute', metaclass => 'Typed');
has simpleThermoConstraints => (is => 'rw', isa => 'Bool', printOrder => '15', default => '1', type => 'attribute', metaclass => 'Typed');
has thermodynamicConstraints => (is => 'rw', isa => 'Bool', printOrder => '16', default => '1', type => 'attribute', metaclass => 'Typed');
has noErrorThermodynamicConstraints => (is => 'rw', isa => 'Bool', printOrder => '17', default => '1', type => 'attribute', metaclass => 'Typed');
has minimizeErrorThermodynamicConstraints => (is => 'rw', isa => 'Bool', printOrder => '18', default => '1', type => 'attribute', metaclass => 'Typed');


# ANCESTOR:
has ancestor_uuid => (is => 'rw', isa => 'uuid', type => 'ancestor', metaclass => 'Typed');


# SUBOBJECTS:
has fbaObjectiveTerms => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'encompassed(FBAObjectiveTerm)', metaclass => 'Typed', reader => '_fbaObjectiveTerms', printOrder => '-1');
has fbaConstraints => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'encompassed(FBAConstraint)', metaclass => 'Typed', reader => '_fbaConstraints', printOrder => '1');
has fbaReactionBounds => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'encompassed(FBAReactionBound)', metaclass => 'Typed', reader => '_fbaReactionBounds', printOrder => '2');
has fbaCompoundBounds => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'encompassed(FBACompoundBound)', metaclass => 'Typed', reader => '_fbaCompoundBounds', printOrder => '3');
has fbaResults => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'result(FBAResult)', metaclass => 'Typed', reader => '_fbaResults', printOrder => '5');
has fbaPhenotypeSimulations => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'encompassed(FBAPhenotypeSimulation)', metaclass => 'Typed', reader => '_fbaPhenotypeSimulations', printOrder => '4');


# LINKS:
has model => (is => 'rw', type => 'link(ModelSEED::Store,Model,model_uuid)', metaclass => 'Typed', lazy => 1, builder => '_build_model', clearer => 'clear_model', trigger => &_trigger_model, isa => 'ModelSEED::MS::Model');
has media => (is => 'rw', type => 'link(Biochemistry,media,media_uuid)', metaclass => 'Typed', lazy => 1, builder => '_build_media', clearer => 'clear_media', trigger => &_trigger_media, isa => 'ModelSEED::MS::Media', weak_ref => 1);
has geneKOs => (is => 'rw', type => 'link(Annotation,features,geneKO_uuids)', metaclass => 'Typed', lazy => 1, builder => '_build_geneKOs', clearer => 'clear_geneKOs', trigger => &_trigger_geneKOs, isa => 'ArrayRef');
has reactionKOs => (is => 'rw', type => 'link(Biochemistry,reactions,reactionKO_uuids)', metaclass => 'Typed', lazy => 1, builder => '_build_reactionKOs', clearer => 'clear_reactionKOs', trigger => &_trigger_reactionKOs, isa => 'ArrayRef');
has secondaryMedia => (is => 'rw', type => 'link(Biochemistry,media,secondaryMedia_uuids)', metaclass => 'Typed', lazy => 1, builder => '_build_secondaryMedia', clearer => 'clear_secondaryMedia', trigger => &_trigger_secondaryMedia, isa => 'ArrayRef');


# BUILDERS:
sub _build_uuid { return Data::UUID->new()->create_str(); }
sub _build_modDate { return DateTime->now()->datetime(); }
sub _build_model {
  my ($self) = @_;
  return $self->getLinkedObject('ModelSEED::Store','Model',$self->model_uuid());
}
sub _trigger_model {
   my ($self, $new, $old) = @_;
   $self->model_uuid( $new->uuid );
}
sub _trigger_model_uuid {
    my ($self, $new, $old) = @_;
    $self->clear_model if( $self->model->uuid ne $new );
}
sub _build_media {
  my ($self) = @_;
  return $self->getLinkedObject('Biochemistry','media',$self->media_uuid());
}
sub _trigger_media {
   my ($self, $new, $old) = @_;
   $self->media_uuid( $new->uuid );
}
sub _trigger_media_uuid {
    my ($self, $new, $old) = @_;
    $self->clear_media if( $self->media->uuid ne $new );
}
sub _build_geneKOs {
  my ($self) = @_;
  return $self->getLinkedObjectArray('Annotation','features',$self->geneKO_uuids());
}
sub _trigger_geneKOs {
   my ($self, $new, $old) = @_;
   $self->geneKO_uuids( $new->uuid );
}
sub _trigger_geneKO_uuids {
    my ($self, $new, $old) = @_;
    $self->clear_geneKOs if( $self->geneKOs->uuid ne $new );
}
sub _build_reactionKOs {
  my ($self) = @_;
  return $self->getLinkedObjectArray('Biochemistry','reactions',$self->reactionKO_uuids());
}
sub _trigger_reactionKOs {
   my ($self, $new, $old) = @_;
   $self->reactionKO_uuids( $new->uuid );
}
sub _trigger_reactionKO_uuids {
    my ($self, $new, $old) = @_;
    $self->clear_reactionKOs if( $self->reactionKOs->uuid ne $new );
}
sub _build_secondaryMedia {
  my ($self) = @_;
  return $self->getLinkedObjectArray('Biochemistry','media',$self->secondaryMedia_uuids());
}
sub _trigger_secondaryMedia {
   my ($self, $new, $old) = @_;
   $self->secondaryMedia_uuids( $new->uuid );
}
sub _trigger_secondaryMedia_uuids {
    my ($self, $new, $old) = @_;
    $self->clear_secondaryMedia if( $self->secondaryMedia->uuid ne $new );
}


# CONSTANTS:
sub _type { return 'FBAFormulation'; }

my $attributes = [
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'uuid',
            'type' => 'ModelSEED::uuid',
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
            'printOrder' => -1,
            'name' => 'regulatorymodel_uuid',
            'type' => 'ModelSEED::uuid',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => -1,
            'name' => 'model_uuid',
            'type' => 'ModelSEED::uuid',
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
            'printOrder' => -1,
            'name' => 'secondaryMedia_uuids',
            'default' => 'sub{return [];}',
            'type' => 'ArrayRef',
            'perm' => 'rw'
          },
          {
            'printOrder' => 10,
            'name' => 'fva',
            'default' => 0,
            'type' => 'Bool',
            'perm' => 'rw'
          },
          {
            'printOrder' => 11,
            'name' => 'comboDeletions',
            'default' => 0,
            'type' => 'Int',
            'perm' => 'rw'
          },
          {
            'printOrder' => 12,
            'name' => 'fluxMinimization',
            'default' => 0,
            'type' => 'Bool',
            'perm' => 'rw'
          },
          {
            'printOrder' => 13,
            'name' => 'findMinimalMedia',
            'default' => 0,
            'type' => 'Bool',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'notes',
            'default' => '',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'expressionData_uuid',
            'type' => 'ModelSEED::uuid',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'objectiveConstraintFraction',
            'default' => 'none',
            'type' => 'ModelSEED::varchar',
            'perm' => 'rw'
          },
          {
            'len' => 255,
            'req' => 0,
            'printOrder' => 14,
            'name' => 'allReversible',
            'default' => '0',
            'type' => 'Int',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => 20,
            'name' => 'defaultMaxFlux',
            'default' => 1000,
            'type' => 'Int',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => 22,
            'name' => 'defaultMaxDrainFlux',
            'default' => 1000,
            'type' => 'Int',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => 21,
            'name' => 'defaultMinDrainFlux',
            'default' => -1000,
            'type' => 'Int',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => -1,
            'name' => 'maximizeObjective',
            'default' => 1,
            'type' => 'Bool',
            'perm' => 'rw'
          },
          {
            'len' => 32,
            'req' => 0,
            'printOrder' => -1,
            'name' => 'decomposeReversibleFlux',
            'default' => 0,
            'type' => 'Bool',
            'perm' => 'rw'
          },
          {
            'len' => 32,
            'req' => 0,
            'printOrder' => -1,
            'name' => 'decomposeReversibleDrainFlux',
            'default' => 0,
            'type' => 'Bool',
            'perm' => 'rw'
          },
          {
            'len' => 32,
            'req' => 0,
            'printOrder' => -1,
            'name' => 'fluxUseVariables',
            'default' => 0,
            'type' => 'Bool',
            'perm' => 'rw'
          },
          {
            'len' => 32,
            'req' => 0,
            'printOrder' => -1,
            'name' => 'drainfluxUseVariables',
            'default' => 0,
            'type' => 'Bool',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'geneKO_uuids',
            'default' => 'sub{return [];}',
            'type' => 'ArrayRef',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'reactionKO_uuids',
            'default' => 'sub{return [];}',
            'type' => 'ArrayRef',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'parameters',
            'default' => 'sub{return {};}',
            'type' => 'HashRef',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'inputfiles',
            'default' => 'sub{return {};}',
            'type' => 'HashRef',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'outputfiles',
            'default' => 'sub{return [];}',
            'type' => 'ArrayRef',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'uptakeLimits',
            'default' => 'sub{return {};}',
            'type' => 'HashRef',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 23,
            'name' => 'numberOfSolutions',
            'default' => 1,
            'type' => 'Int',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 15,
            'name' => 'simpleThermoConstraints',
            'default' => 1,
            'type' => 'Bool',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 16,
            'name' => 'thermodynamicConstraints',
            'default' => 1,
            'type' => 'Bool',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 17,
            'name' => 'noErrorThermodynamicConstraints',
            'default' => 1,
            'type' => 'Bool',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 18,
            'name' => 'minimizeErrorThermodynamicConstraints',
            'default' => 1,
            'type' => 'Bool',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {uuid => 0, modDate => 1, regulatorymodel_uuid => 2, model_uuid => 3, media_uuid => 4, secondaryMedia_uuids => 5, fva => 6, comboDeletions => 7, fluxMinimization => 8, findMinimalMedia => 9, notes => 10, expressionData_uuid => 11, objectiveConstraintFraction => 12, allReversible => 13, defaultMaxFlux => 14, defaultMaxDrainFlux => 15, defaultMinDrainFlux => 16, maximizeObjective => 17, decomposeReversibleFlux => 18, decomposeReversibleDrainFlux => 19, fluxUseVariables => 20, drainfluxUseVariables => 21, geneKO_uuids => 22, reactionKO_uuids => 23, parameters => 24, inputfiles => 25, outputfiles => 26, uptakeLimits => 27, numberOfSolutions => 28, simpleThermoConstraints => 29, thermodynamicConstraints => 30, noErrorThermodynamicConstraints => 31, minimizeErrorThermodynamicConstraints => 32};
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
            'attribute' => 'media_uuid',
            'parent' => 'Biochemistry',
            'clearer' => 'clear_media',
            'name' => 'media',
            'class' => 'media',
            'method' => 'media'
          },
          {
            'array' => 1,
            'attribute' => 'geneKO_uuids',
            'parent' => 'Annotation',
            'clearer' => 'clear_geneKOs',
            'name' => 'geneKOs',
            'class' => 'features',
            'method' => 'features'
          },
          {
            'array' => 1,
            'attribute' => 'reactionKO_uuids',
            'parent' => 'Biochemistry',
            'clearer' => 'clear_reactionKOs',
            'name' => 'reactionKOs',
            'class' => 'reactions',
            'method' => 'reactions'
          },
          {
            'array' => 1,
            'attribute' => 'secondaryMedia_uuids',
            'parent' => 'Biochemistry',
            'clearer' => 'clear_secondaryMedia',
            'name' => 'secondaryMedia',
            'class' => 'media',
            'method' => 'media'
          }
        ];

my $link_map = {model => 0, media => 1, geneKOs => 2, reactionKOs => 3, secondaryMedia => 4};
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
            'name' => 'fbaObjectiveTerms',
            'type' => 'encompassed',
            'class' => 'FBAObjectiveTerm'
          },
          {
            'printOrder' => 1,
            'name' => 'fbaConstraints',
            'type' => 'encompassed',
            'class' => 'FBAConstraint'
          },
          {
            'printOrder' => 2,
            'name' => 'fbaReactionBounds',
            'type' => 'encompassed',
            'class' => 'FBAReactionBound'
          },
          {
            'printOrder' => 3,
            'name' => 'fbaCompoundBounds',
            'type' => 'encompassed',
            'class' => 'FBACompoundBound'
          },
          {
            'printOrder' => 5,
            'name' => 'fbaResults',
            'type' => 'result',
            'class' => 'FBAResult'
          },
          {
            'printOrder' => 4,
            'name' => 'fbaPhenotypeSimulations',
            'type' => 'encompassed',
            'class' => 'FBAPhenotypeSimulation'
          }
        ];

my $subobject_map = {fbaObjectiveTerms => 0, fbaConstraints => 1, fbaReactionBounds => 2, fbaCompoundBounds => 3, fbaResults => 4, fbaPhenotypeSimulations => 5};
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
around 'fbaObjectiveTerms' => sub {
  my ($orig, $self) = @_;
  return $self->_build_all_objects('fbaObjectiveTerms');
};
around 'fbaConstraints' => sub {
  my ($orig, $self) = @_;
  return $self->_build_all_objects('fbaConstraints');
};
around 'fbaReactionBounds' => sub {
  my ($orig, $self) = @_;
  return $self->_build_all_objects('fbaReactionBounds');
};
around 'fbaCompoundBounds' => sub {
  my ($orig, $self) = @_;
  return $self->_build_all_objects('fbaCompoundBounds');
};
around 'fbaResults' => sub {
  my ($orig, $self) = @_;
  return $self->_build_all_objects('fbaResults');
};
around 'fbaPhenotypeSimulations' => sub {
  my ($orig, $self) = @_;
  return $self->_build_all_objects('fbaPhenotypeSimulations');
};


__PACKAGE__->meta->make_immutable;
1;
