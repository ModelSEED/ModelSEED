########################################################################
# ModelSEED::MS::DB::TranscriptionFactorMapTarget - This is the moose object corresponding to the TranscriptionFactorMapTarget object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package ModelSEED::MS::DB::TranscriptionFactorMapTarget;
use ModelSEED::MS::BaseObject;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'ModelSEED::MS::TranscriptionFactorMap', weak_ref => 1, type => 'parent', metaclass => 'Typed');


# ATTRIBUTES:
has target_uuid => (is => 'rw', isa => 'ModelSEED::varchar', printOrder => '1', required => 1, type => 'attribute', metaclass => 'Typed');
has tfOffProbability => (is => 'rw', isa => 'Num', printOrder => '2', required => 1, default => '1', type => 'attribute', metaclass => 'Typed');
has tfOnProbability => (is => 'rw', isa => 'Num', printOrder => '3', required => 1, default => '1', type => 'attribute', metaclass => 'Typed');


# LINKS:
has target => (is => 'rw', type => 'link(Annotation,features,target_uuid)', metaclass => 'Typed', lazy => 1, builder => '_build_target', clearer => 'clear_target', isa => 'ModelSEED::MS::Feature', weak_ref => 1);


# BUILDERS:
sub _build_target {
  my ($self) = @_;
  return $self->getLinkedObject('Annotation','features',$self->target_uuid());
}


# CONSTANTS:
sub _type { return 'TranscriptionFactorMapTarget'; }

my $attributes = [
          {
            'req' => 1,
            'printOrder' => 1,
            'name' => 'target_uuid',
            'type' => 'ModelSEED::varchar',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => 2,
            'name' => 'tfOffProbability',
            'default' => 1,
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => 3,
            'name' => 'tfOnProbability',
            'default' => 1,
            'type' => 'Num',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {target_uuid => 0, tfOffProbability => 1, tfOnProbability => 2};
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
            'attribute' => 'target_uuid',
            'parent' => 'Annotation',
            'clearer' => 'clear_target',
            'name' => 'target',
            'class' => 'features',
            'method' => 'features'
          }
        ];

my $link_map = {target => 0};
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
