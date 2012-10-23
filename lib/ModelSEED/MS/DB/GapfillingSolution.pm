########################################################################
# ModelSEED::MS::DB::GapfillingSolution - This is the moose object corresponding to the GapfillingSolution object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package ModelSEED::MS::DB::GapfillingSolution;
use ModelSEED::MS::BaseObject;
use ModelSEED::MS::GapfillingSolutionReaction;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'ModelSEED::MS::GapfillingFormulation', weak_ref => 1, type => 'parent', metaclass => 'Typed');


# ATTRIBUTES:
has uid => (is => 'rw', isa => 'ModelSEED::uid', printOrder => '0', type => 'attribute', metaclass => 'Typed');
has modDate => (is => 'rw', isa => 'Str', printOrder => '-1', lazy => 1, builder => '_build_modDate', type => 'attribute', metaclass => 'Typed');
has solutionCost => (is => 'rw', isa => 'Num', printOrder => '1', default => '1', type => 'attribute', metaclass => 'Typed');
has biomassRemoval_links => (is => 'rw', isa => 'ArrayRef[ModelSEED::subobject_link]', printOrder => '-1', default => sub{return [];}, type => 'attribute', metaclass => 'Typed');
has mediaSupplement_links => (is => 'rw', isa => 'ArrayRef[ModelSEED::subobject_link]', printOrder => '-1', default => sub{return [];}, type => 'attribute', metaclass => 'Typed');
has koRestore_links => (is => 'rw', isa => 'ArrayRef[ModelSEED::subobject_link]', printOrder => '-1', default => sub{return [];}, type => 'attribute', metaclass => 'Typed');


# SUBOBJECTS:
has gapfillingSolutionReactions => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'encompassed(GapfillingSolutionReaction)', metaclass => 'Typed', reader => '_gapfillingSolutionReactions', printOrder => '-1');


# LINKS:
has biomassRemovals => (is => 'rw', type => 'link(Model,modelcompounds,biomassRemoval_links)', metaclass => 'Typed', lazy => 1, builder => '_build_biomassRemovals', clearer => 'clear_biomassRemovals', isa => 'ArrayRef');
has mediaSupplements => (is => 'rw', type => 'link(Model,modelcompounds,mediaSupplement_links)', metaclass => 'Typed', lazy => 1, builder => '_build_mediaSupplements', clearer => 'clear_mediaSupplements', isa => 'ArrayRef');
has koRestores => (is => 'rw', type => 'link(Model,modelreactions,koRestore_links)', metaclass => 'Typed', lazy => 1, builder => '_build_koRestores', clearer => 'clear_koRestores', isa => 'ArrayRef');


# BUILDERS:
sub _build_modDate { return DateTime->now()->datetime(); }
sub _build_biomassRemovals {
  my ($self) = @_;
  return $self->getLinkedObjectArray('Model','modelcompounds',$self->biomassRemoval_links());
}
sub _build_mediaSupplements {
  my ($self) = @_;
  return $self->getLinkedObjectArray('Model','modelcompounds',$self->mediaSupplement_links());
}
sub _build_koRestores {
  my ($self) = @_;
  return $self->getLinkedObjectArray('Model','modelreactions',$self->koRestore_links());
}


# CONSTANTS:
sub _type { return 'GapfillingSolution'; }

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
            'printOrder' => 1,
            'name' => 'solutionCost',
            'default' => '1',
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'biomassRemoval_links',
            'default' => 'sub{return [];}',
            'type' => 'ArrayRef[ModelSEED::subobject_link]',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'mediaSupplement_links',
            'default' => 'sub{return [];}',
            'type' => 'ArrayRef[ModelSEED::subobject_link]',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'koRestore_links',
            'default' => 'sub{return [];}',
            'type' => 'ArrayRef[ModelSEED::subobject_link]',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {uid => 0, modDate => 1, solutionCost => 2, biomassRemoval_links => 3, mediaSupplement_links => 4, koRestore_links => 5};
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
            'attribute' => 'biomassRemoval_links',
            'parent' => 'Model',
            'clearer' => 'clear_biomassRemovals',
            'name' => 'biomassRemovals',
            'class' => 'modelcompounds',
            'method' => 'modelcompounds'
          },
          {
            'array' => 1,
            'attribute' => 'mediaSupplement_links',
            'parent' => 'Model',
            'clearer' => 'clear_mediaSupplements',
            'name' => 'mediaSupplements',
            'class' => 'modelcompounds',
            'method' => 'modelcompounds'
          },
          {
            'array' => 1,
            'attribute' => 'koRestore_links',
            'parent' => 'Model',
            'clearer' => 'clear_koRestores',
            'name' => 'koRestores',
            'class' => 'modelreactions',
            'method' => 'modelreactions'
          }
        ];

my $link_map = {biomassRemovals => 0, mediaSupplements => 1, koRestores => 2};
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
            'name' => 'gapfillingSolutionReactions',
            'type' => 'encompassed',
            'class' => 'GapfillingSolutionReaction'
          }
        ];

my $subobject_map = {gapfillingSolutionReactions => 0};
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
around 'gapfillingSolutionReactions' => sub {
  my ($orig, $self) = @_;
  return $self->_build_all_objects('gapfillingSolutionReactions');
};


__PACKAGE__->meta->make_immutable;
1;
