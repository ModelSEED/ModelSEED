########################################################################
# ModelSEED::MS::DB::ModelCompound - This is the moose object corresponding to the ModelCompound object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package ModelSEED::MS::DB::ModelCompound;
use ModelSEED::MS::BaseObject;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'ModelSEED::MS::Model', weak_ref => 1, type => 'parent', metaclass => 'Typed');


# ATTRIBUTES:
has uid => (is => 'rw', isa => 'ModelSEED::uid', printOrder => '0', type => 'attribute', metaclass => 'Typed');
has modDate => (is => 'rw', isa => 'Str', printOrder => '-1', lazy => 1, builder => '_build_modDate', type => 'attribute', metaclass => 'Typed');
has compound_link => (is => 'rw', isa => 'ModelSEED::subobject_link', printOrder => '6', required => 1, type => 'attribute', metaclass => 'Typed');
has charge => (is => 'rw', isa => 'Num', printOrder => '3', type => 'attribute', metaclass => 'Typed');
has formula => (is => 'rw', isa => 'Str', printOrder => '4', default => '', type => 'attribute', metaclass => 'Typed');
has modelcompartment_link => (is => 'rw', isa => 'ModelSEED::subobject_link', printOrder => '5', required => 1, type => 'attribute', metaclass => 'Typed');


# LINKS:
has compound => (is => 'rw', type => 'link(Biochemistry,compounds,compound_link)', metaclass => 'Typed', lazy => 1, builder => '_build_compound', clearer => 'clear_compound', isa => 'ModelSEED::MS::Compound', weak_ref => 1);
has modelcompartment => (is => 'rw', type => 'link(Model,modelcompartments,modelcompartment_link)', metaclass => 'Typed', lazy => 1, builder => '_build_modelcompartment', clearer => 'clear_modelcompartment', isa => 'ModelSEED::MS::ModelCompartment', weak_ref => 1);


# BUILDERS:
sub _build_modDate { return DateTime->now()->datetime(); }
sub _build_compound {
  my ($self) = @_;
  return $self->getLinkedObject('Biochemistry','compounds',$self->compound_link());
}
sub _build_modelcompartment {
  my ($self) = @_;
  return $self->getLinkedObject('Model','modelcompartments',$self->modelcompartment_link());
}


# CONSTANTS:
sub _type { return 'ModelCompound'; }

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
            'printOrder' => 6,
            'name' => 'compound_link',
            'type' => 'ModelSEED::subobject_link',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 3,
            'name' => 'charge',
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 4,
            'name' => 'formula',
            'default' => '',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => 5,
            'name' => 'modelcompartment_link',
            'type' => 'ModelSEED::subobject_link',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {uid => 0, modDate => 1, compound_link => 2, charge => 3, formula => 4, modelcompartment_link => 5};
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
            'attribute' => 'modelcompartment_link',
            'parent' => 'Model',
            'clearer' => 'clear_modelcompartment',
            'name' => 'modelcompartment',
            'class' => 'modelcompartments',
            'method' => 'modelcompartments'
          }
        ];

my $link_map = {compound => 0, modelcompartment => 1};
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
