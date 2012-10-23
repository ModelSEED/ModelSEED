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
has reaction_link => (is => 'rw', isa => 'ModelSEED::subobject_link', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');
has compartment_link => (is => 'rw', isa => 'ModelSEED::subobject_link', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');
has direction => (is => 'rw', isa => 'Str', printOrder => '0', default => '1', type => 'attribute', metaclass => 'Typed');
has candidateFeature_links => (is => 'rw', isa => 'ArrayRef[ModelSEED::subobject_link]', printOrder => '-1', default => sub{return [];}, type => 'attribute', metaclass => 'Typed');


# LINKS:
has reaction => (is => 'rw', type => 'link(Biochemistry,reactions,reaction_link)', metaclass => 'Typed', lazy => 1, builder => '_build_reaction', clearer => 'clear_reaction', isa => 'ModelSEED::MS::Reaction', weak_ref => 1);
has compartment => (is => 'rw', type => 'link(Biochemistry,compartments,compartment_link)', metaclass => 'Typed', lazy => 1, builder => '_build_compartment', clearer => 'clear_compartment', isa => 'ModelSEED::MS::Compartment', weak_ref => 1);
has candidateFeatures => (is => 'rw', type => 'link(Annotation,features,candidateFeature_links)', metaclass => 'Typed', lazy => 1, builder => '_build_candidateFeatures', clearer => 'clear_candidateFeatures', isa => 'ArrayRef');


# BUILDERS:
sub _build_reaction {
  my ($self) = @_;
  return $self->getLinkedObject('Biochemistry','reactions',$self->reaction_link());
}
sub _build_compartment {
  my ($self) = @_;
  return $self->getLinkedObject('Biochemistry','compartments',$self->compartment_link());
}
sub _build_candidateFeatures {
  my ($self) = @_;
  return $self->getLinkedObjectArray('Annotation','features',$self->candidateFeature_links());
}


# CONSTANTS:
sub _type { return 'GapfillingSolutionReaction'; }

my $attributes = [
          {
            'req' => 1,
            'printOrder' => 0,
            'name' => 'reaction_link',
            'type' => 'ModelSEED::subobject_link',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => 0,
            'name' => 'compartment_link',
            'type' => 'ModelSEED::subobject_link',
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
            'name' => 'candidateFeature_links',
            'default' => 'sub{return [];}',
            'type' => 'ArrayRef[ModelSEED::subobject_link]',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {reaction_link => 0, compartment_link => 1, direction => 2, candidateFeature_links => 3};
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
            'attribute' => 'compartment_link',
            'parent' => 'Biochemistry',
            'clearer' => 'clear_compartment',
            'name' => 'compartment',
            'class' => 'compartments',
            'method' => 'compartments'
          },
          {
            'array' => 1,
            'attribute' => 'candidateFeature_links',
            'parent' => 'Annotation',
            'clearer' => 'clear_candidateFeatures',
            'name' => 'candidateFeatures',
            'class' => 'features',
            'method' => 'features'
          }
        ];

my $link_map = {reaction => 0, compartment => 1, candidateFeatures => 2};
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
