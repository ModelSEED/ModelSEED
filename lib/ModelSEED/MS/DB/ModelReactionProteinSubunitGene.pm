########################################################################
# ModelSEED::MS::DB::ModelReactionProteinSubunitGene - This is the moose object corresponding to the ModelReactionProteinSubunitGene object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package ModelSEED::MS::DB::ModelReactionProteinSubunitGene;
use ModelSEED::MS::BaseObject;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'ModelSEED::MS::ModelReactionProteinSubunit', weak_ref => 1, type => 'parent', metaclass => 'Typed');


# ATTRIBUTES:
has feature_uuid => (is => 'rw', isa => 'ModelSEED::uuid', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');


# LINKS:
has feature => (is => 'rw', type => 'link(Annotation,features,feature_uuid)', metaclass => 'Typed', lazy => 1, builder => '_build_feature', clearer => 'clear_feature', isa => 'ModelSEED::MS::Feature', weak_ref => 1);


# BUILDERS:
sub _build_feature {
  my ($self) = @_;
  return $self->getLinkedObject('Annotation','features',$self->feature_uuid());
}


# CONSTANTS:
sub _type { return 'ModelReactionProteinSubunitGene'; }

my $attributes = [
          {
            'req' => 1,
            'printOrder' => 0,
            'name' => 'feature_uuid',
            'type' => 'ModelSEED::uuid',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {feature_uuid => 0};
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
            'attribute' => 'feature_uuid',
            'parent' => 'Annotation',
            'clearer' => 'clear_feature',
            'name' => 'feature',
            'class' => 'features',
            'method' => 'features'
          }
        ];

my $link_map = {feature => 0};
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
