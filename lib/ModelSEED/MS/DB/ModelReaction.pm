########################################################################
# ModelSEED::MS::DB::ModelReaction - This is the moose object corresponding to the ModelReaction object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package ModelSEED::MS::DB::ModelReaction;
use ModelSEED::MS::BaseObject;
use ModelSEED::MS::ModelReactionProtein;
use ModelSEED::MS::ModelReactionReagent;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'ModelSEED::MS::Model', weak_ref => 1, type => 'parent', metaclass => 'Typed');


# ATTRIBUTES:
has uid => (is => 'rw', isa => 'ModelSEED::uid', printOrder => '0', type => 'attribute', metaclass => 'Typed');
has modDate => (is => 'rw', isa => 'Str', printOrder => '-1', lazy => 1, builder => '_build_modDate', type => 'attribute', metaclass => 'Typed');
has reaction_link => (is => 'rw', isa => 'ModelSEED::subobject_link', printOrder => '-1', required => 1, type => 'attribute', metaclass => 'Typed');
has direction => (is => 'rw', isa => 'Str', printOrder => '5', default => '=', type => 'attribute', metaclass => 'Typed');
has protons => (is => 'rw', isa => 'Num', printOrder => '7', default => '0', type => 'attribute', metaclass => 'Typed');
has modelcompartment_link => (is => 'rw', isa => 'ModelSEED::subobject_link', printOrder => '-1', required => 1, type => 'attribute', metaclass => 'Typed');


# SUBOBJECTS:
has modelReactionProteins => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'encompassed(ModelReactionProtein)', metaclass => 'Typed', reader => '_modelReactionProteins', printOrder => '-1');
has modelReactionReagents => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'encompassed(ModelReactionReagent)', metaclass => 'Typed', reader => '_modelReactionReagents', printOrder => '-1');


# LINKS:
has reaction => (is => 'rw', type => 'link(Biochemistry,reactions,reaction_link)', metaclass => 'Typed', lazy => 1, builder => '_build_reaction', clearer => 'clear_reaction', isa => 'ModelSEED::MS::Reaction', weak_ref => 1);
has modelcompartment => (is => 'rw', type => 'link(Model,modelcompartments,modelcompartment_link)', metaclass => 'Typed', lazy => 1, builder => '_build_modelcompartment', clearer => 'clear_modelcompartment', isa => 'ModelSEED::MS::ModelCompartment', weak_ref => 1);


# BUILDERS:
sub _build_modDate { return DateTime->now()->datetime(); }
sub _build_reaction {
  my ($self) = @_;
  return $self->getLinkedObject('Biochemistry','reactions',$self->reaction_link());
}
sub _build_modelcompartment {
  my ($self) = @_;
  return $self->getLinkedObject('Model','modelcompartments',$self->modelcompartment_link());
}


# CONSTANTS:
sub _type { return 'ModelReaction'; }

my $attributes = [
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'uid',
            'type' => 'ModelSEED::uid',
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
            'req' => 1,
            'printOrder' => -1,
            'name' => 'reaction_link',
            'type' => 'ModelSEED::subobject_link',
            'perm' => 'rw'
          },
          {
            'len' => 1,
            'req' => 0,
            'printOrder' => 5,
            'name' => 'direction',
            'default' => '=',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 7,
            'name' => 'protons',
            'default' => 0,
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => -1,
            'name' => 'modelcompartment_link',
            'type' => 'ModelSEED::subobject_link',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {uid => 0, modDate => 1, reaction_link => 2, direction => 3, protons => 4, modelcompartment_link => 5};
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
            'attribute' => 'reaction_link',
            'parent' => 'Biochemistry',
            'clearer' => 'clear_reaction',
            'name' => 'reaction',
            'class' => 'reactions',
            'method' => 'reactions'
          },
          {
            'attribute' => 'modelcompartment_link',
            'parent' => 'Model',
            'clearer' => 'clear_modelcompartment',
            'name' => 'modelcompartment',
            'class' => 'modelcompartments',
            'method' => 'modelcompartments'
          }
        ];

my $link_map = {reaction => 0, modelcompartment => 1};
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
            'name' => 'modelReactionProteins',
            'type' => 'encompassed',
            'class' => 'ModelReactionProtein'
          },
          {
            'printOrder' => -1,
            'name' => 'modelReactionReagents',
            'type' => 'encompassed',
            'class' => 'ModelReactionReagent'
          }
        ];

my $subobject_map = {modelReactionProteins => 0, modelReactionReagents => 1};
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
around 'modelReactionProteins' => sub {
  my ($orig, $self) = @_;
  return $self->_build_all_objects('modelReactionProteins');
};
around 'modelReactionReagents' => sub {
  my ($orig, $self) = @_;
  return $self->_build_all_objects('modelReactionReagents');
};


__PACKAGE__->meta->make_immutable;
1;
