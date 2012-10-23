########################################################################
# ModelSEED::MS::DB::MediaCompound - This is the moose object corresponding to the MediaCompound object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package ModelSEED::MS::DB::MediaCompound;
use ModelSEED::MS::BaseObject;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'ModelSEED::MS::Media', weak_ref => 1, type => 'parent', metaclass => 'Typed');


# ATTRIBUTES:
has compound_link => (is => 'rw', isa => 'ModelSEED::subobject_link', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');
has concentration => (is => 'rw', isa => 'Num', printOrder => '0', default => '0.001', type => 'attribute', metaclass => 'Typed');
has maxFlux => (is => 'rw', isa => 'Num', printOrder => '0', default => '100', type => 'attribute', metaclass => 'Typed');
has minFlux => (is => 'rw', isa => 'Num', printOrder => '0', default => '-100', type => 'attribute', metaclass => 'Typed');


# LINKS:
has compound => (is => 'rw', type => 'link(Biochemistry,compounds,compound_link)', metaclass => 'Typed', lazy => 1, builder => '_build_compound', clearer => 'clear_compound', isa => 'ModelSEED::MS::Compound', weak_ref => 1);


# BUILDERS:
sub _build_compound {
  my ($self) = @_;
  return $self->getLinkedObject('Biochemistry','compounds',$self->compound_link());
}


# CONSTANTS:
sub _type { return 'MediaCompound'; }

my $attributes = [
          {
            'req' => 1,
            'printOrder' => 0,
            'name' => 'compound_link',
            'type' => 'ModelSEED::subobject_link',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'concentration',
            'default' => '0.001',
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'maxFlux',
            'default' => '100',
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'minFlux',
            'default' => '-100',
            'type' => 'Num',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {compound_link => 0, concentration => 1, maxFlux => 2, minFlux => 3};
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
            'attribute' => 'compound_link',
            'parent' => 'Biochemistry',
            'clearer' => 'clear_compound',
            'name' => 'compound',
            'class' => 'compounds',
            'method' => 'compounds'
          }
        ];

my $link_map = {compound => 0};
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
