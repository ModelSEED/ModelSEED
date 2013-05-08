########################################################################
# ModelSEED::MS::DB::TemplateReaction - This is the moose object corresponding to the TemplateReaction object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package ModelSEED::MS::DB::TemplateReaction;
use ModelSEED::MS::BaseObject;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'ModelSEED::MS::ModelTemplate', weak_ref => 1, type => 'parent', metaclass => 'Typed');


# ATTRIBUTES:
has uuid => (is => 'rw', isa => 'Str', printOrder => '-1', lazy => 1, builder => '_build_uuid', type => 'attribute', metaclass => 'Typed');
has reaction_uuid => (is => 'rw', isa => 'Str', printOrder => '-1', required => 1, type => 'attribute', metaclass => 'Typed');
has compartment_uuid => (is => 'rw', isa => 'Str', printOrder => '-1', required => 1, type => 'attribute', metaclass => 'Typed');
has complex_uuids => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has direction => (is => 'rw', isa => 'ModelSEED::varchar', printOrder => '1', type => 'attribute', metaclass => 'Typed');
has type => (is => 'rw', isa => 'ModelSEED::varchar', printOrder => '1', type => 'attribute', metaclass => 'Typed');


# ANCESTOR:
has ancestor_uuid => (is => 'rw', isa => 'uuid', type => 'ancestor', metaclass => 'Typed');


# LINKS:
has reaction => (is => 'rw', type => 'link(Biochemistry,reactions,reaction_uuid)', metaclass => 'Typed', lazy => 1, builder => '_build_reaction', clearer => 'clear_reaction', isa => 'ModelSEED::MS::Reaction', weak_ref => 1);
has compartment => (is => 'rw', type => 'link(Biochemistry,compartments,compartment_uuid)', metaclass => 'Typed', lazy => 1, builder => '_build_compartment', clearer => 'clear_compartment', isa => 'ModelSEED::MS::Compartment', weak_ref => 1);
has complexes => (is => 'rw', type => 'link(Mapping,complexes,complex_uuids)', metaclass => 'Typed', lazy => 1, builder => '_build_complexes', clearer => 'clear_complexes', isa => 'ArrayRef');


# BUILDERS:
sub _build_uuid { return Data::UUID->new()->create_str(); }
sub _build_reaction {
  my ($self) = @_;
  return $self->getLinkedObject('Biochemistry','reactions',$self->reaction_uuid());
}
sub _build_compartment {
  my ($self) = @_;
  return $self->getLinkedObject('Biochemistry','compartments',$self->compartment_uuid());
}
sub _build_complexes {
  my ($self) = @_;
  return $self->getLinkedObjectArray('Mapping','complexes',$self->complex_uuids());
}


# CONSTANTS:
sub _type { return 'TemplateReaction'; }

my $attributes = [
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'uuid',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => -1,
            'name' => 'reaction_uuid',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => -1,
            'name' => 'compartment_uuid',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'complex_uuids',
            'type' => 'ArrayRef',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 1,
            'name' => 'direction',
            'type' => 'ModelSEED::varchar',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 1,
            'name' => 'type',
            'type' => 'ModelSEED::varchar',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {uuid => 0, reaction_uuid => 1, compartment_uuid => 2, complex_uuids => 3, direction => 4, type => 5};
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
            'attribute' => 'reaction_uuid',
            'weak' => 1,
            'parent' => 'Biochemistry',
            'clearer' => 'clear_reaction',
            'name' => 'reaction',
            'class' => 'reactions',
            'method' => 'reactions'
          },
          {
            'attribute' => 'compartment_uuid',
            'weak' => 1,
            'parent' => 'Biochemistry',
            'clearer' => 'clear_compartment',
            'name' => 'compartment',
            'class' => 'compartments',
            'method' => 'compartments'
          },
          {
            'weak' => 1,
            'parent' => 'Mapping',
            'name' => 'complexes',
            'attribute' => 'complex_uuids',
            'array' => 1,
            'clearer' => 'clear_complexes',
            'method' => 'complexes',
            'class' => 'complexes'
          }
        ];

my $link_map = {reaction => 0, compartment => 1, complexes => 2};
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
