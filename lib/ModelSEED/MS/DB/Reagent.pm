########################################################################
# ModelSEED::MS::DB::Reagent - This is the moose object corresponding to the Reagent object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package ModelSEED::MS::DB::Reagent;
use ModelSEED::MS::BaseObject;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'ModelSEED::MS::Reaction', weak_ref => 1, type => 'parent', metaclass => 'Typed');


# ATTRIBUTES:
has compound_link => (is => 'rw', isa => 'ModelSEED::subobject_link', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');
has compartment_link => (is => 'rw', isa => 'ModelSEED::subobject_link', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');
has coefficient => (is => 'rw', isa => 'Num', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');
has isCofactor => (is => 'rw', isa => 'Bool', printOrder => '0', default => '0', type => 'attribute', metaclass => 'Typed');


# LINKS:
has compound => (is => 'rw', type => 'link(Biochemistry,compounds,compound_link)', metaclass => 'Typed', lazy => 1, builder => '_build_compound', clearer => 'clear_compound', isa => 'ModelSEED::MS::Compound', weak_ref => 1);
has compartment => (is => 'rw', type => 'link(Biochemistry,compartments,compartment_link)', metaclass => 'Typed', lazy => 1, builder => '_build_compartment', clearer => 'clear_compartment', isa => 'ModelSEED::MS::Compartment', weak_ref => 1);


# BUILDERS:
sub _build_compound {
  my ($self) = @_;
  return $self->getLinkedObject('Biochemistry','compounds',$self->compound_link());
}
sub _build_compartment {
  my ($self) = @_;
  return $self->getLinkedObject('Biochemistry','compartments',$self->compartment_link());
}


# CONSTANTS:
sub _type { return 'Reagent'; }

my $attributes = [
          {
            'len' => 36,
            'req' => 1,
            'printOrder' => 0,
            'name' => 'compound_link',
            'type' => 'ModelSEED::subobject_link',
            'perm' => 'rw'
          },
          {
            'len' => 36,
            'req' => 1,
            'printOrder' => 0,
            'name' => 'compartment_link',
            'type' => 'ModelSEED::subobject_link',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => 0,
            'name' => 'coefficient',
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'isCofactor',
            'default' => '0',
            'type' => 'Bool',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {compound_link => 0, compartment_link => 1, coefficient => 2, isCofactor => 3};
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
          },
          {
            'attribute' => 'compartment_link',
            'parent' => 'Biochemistry',
            'clearer' => 'clear_compartment',
            'name' => 'compartment',
            'class' => 'compartments',
            'method' => 'compartments'
          }
        ];

my $link_map = {compound => 0, compartment => 1};
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
