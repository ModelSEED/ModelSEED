########################################################################
# ModelSEED::MS::DB::GapgenSolution - This is the moose object corresponding to the GapgenSolution object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package ModelSEED::MS::DB::GapgenSolution;
use ModelSEED::MS::BaseObject;
use ModelSEED::MS::GapgenSolutionReaction;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'ModelSEED::MS::GapgenFormulation', weak_ref => 1, type => 'parent', metaclass => 'Typed');


# ATTRIBUTES:
has uid => (is => 'rw', isa => 'ModelSEED::uid', printOrder => '0', type => 'attribute', metaclass => 'Typed');
has modDate => (is => 'rw', isa => 'Str', printOrder => '-1', lazy => 1, builder => '_build_modDate', type => 'attribute', metaclass => 'Typed');
has solutionCost => (is => 'rw', isa => 'Num', printOrder => '0', default => '1', type => 'attribute', metaclass => 'Typed');
has biomassSupplement_links => (is => 'rw', isa => 'ArrayRef[ModelSEED::subobject_link]', printOrder => '-1', default => sub{return [];}, type => 'attribute', metaclass => 'Typed');
has mediaRemoval_links => (is => 'rw', isa => 'ArrayRef[ModelSEED::subobject_link]', printOrder => '-1', default => sub{return [];}, type => 'attribute', metaclass => 'Typed');
has additionalKO_links => (is => 'rw', isa => 'ArrayRef[ModelSEED::subobject_link]', printOrder => '-1', default => sub{return [];}, type => 'attribute', metaclass => 'Typed');


# SUBOBJECTS:
has gapgenSolutionReactions => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'encompassed(GapgenSolutionReaction)', metaclass => 'Typed', reader => '_gapgenSolutionReactions', printOrder => '-1');


# LINKS:
has biomassSupplements => (is => 'rw', type => 'link(Model,modelcompounds,biomassSupplement_links)', metaclass => 'Typed', lazy => 1, builder => '_build_biomassSupplements', clearer => 'clear_biomassSupplements', isa => 'ArrayRef');
has mediaRemovals => (is => 'rw', type => 'link(Model,modelcompounds,mediaRemoval_links)', metaclass => 'Typed', lazy => 1, builder => '_build_mediaRemovals', clearer => 'clear_mediaRemovals', isa => 'ArrayRef');
has additionalKOs => (is => 'rw', type => 'link(Model,modelreactions,additionalKO_links)', metaclass => 'Typed', lazy => 1, builder => '_build_additionalKOs', clearer => 'clear_additionalKOs', isa => 'ArrayRef');


# BUILDERS:
sub _build_modDate { return DateTime->now()->datetime(); }
sub _build_biomassSupplements {
  my ($self) = @_;
  return $self->getLinkedObjectArray('Model','modelcompounds',$self->biomassSupplement_links());
}
sub _build_mediaRemovals {
  my ($self) = @_;
  return $self->getLinkedObjectArray('Model','modelcompounds',$self->mediaRemoval_links());
}
sub _build_additionalKOs {
  my ($self) = @_;
  return $self->getLinkedObjectArray('Model','modelreactions',$self->additionalKO_links());
}


# CONSTANTS:
sub _type { return 'GapgenSolution'; }

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
            'req' => 0,
            'printOrder' => 0,
            'name' => 'solutionCost',
            'default' => '1',
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'biomassSupplement_links',
            'default' => 'sub{return [];}',
            'type' => 'ArrayRef[ModelSEED::subobject_link]',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'mediaRemoval_links',
            'default' => 'sub{return [];}',
            'type' => 'ArrayRef[ModelSEED::subobject_link]',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'additionalKO_links',
            'default' => 'sub{return [];}',
            'type' => 'ArrayRef[ModelSEED::subobject_link]',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {uid => 0, modDate => 1, solutionCost => 2, biomassSupplement_links => 3, mediaRemoval_links => 4, additionalKO_links => 5};
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
            'attribute' => 'biomassSupplement_links',
            'parent' => 'Model',
            'clearer' => 'clear_biomassSupplements',
            'name' => 'biomassSupplements',
            'class' => 'modelcompounds',
            'method' => 'modelcompounds'
          },
          {
            'array' => 1,
            'attribute' => 'mediaRemoval_links',
            'parent' => 'Model',
            'clearer' => 'clear_mediaRemovals',
            'name' => 'mediaRemovals',
            'class' => 'modelcompounds',
            'method' => 'modelcompounds'
          },
          {
            'array' => 1,
            'attribute' => 'additionalKO_links',
            'parent' => 'Model',
            'clearer' => 'clear_additionalKOs',
            'name' => 'additionalKOs',
            'class' => 'modelreactions',
            'method' => 'modelreactions'
          }
        ];

my $link_map = {biomassSupplements => 0, mediaRemovals => 1, additionalKOs => 2};
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
            'name' => 'gapgenSolutionReactions',
            'type' => 'encompassed',
            'class' => 'GapgenSolutionReaction'
          }
        ];

my $subobject_map = {gapgenSolutionReactions => 0};
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
around 'gapgenSolutionReactions' => sub {
  my ($orig, $self) = @_;
  return $self->_build_all_objects('gapgenSolutionReactions');
};


__PACKAGE__->meta->make_immutable;
1;
