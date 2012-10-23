########################################################################
# ModelSEED::MS::DB::BiomassTemplateComponent - This is the moose object corresponding to the BiomassTemplateComponent object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package ModelSEED::MS::DB::BiomassTemplateComponent;
use ModelSEED::MS::BaseObject;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'ModelSEED::MS::BiomassTemplate', weak_ref => 1, type => 'parent', metaclass => 'Typed');


# ATTRIBUTES:
has uid => (is => 'rw', isa => 'ModelSEED::uid', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');
has modDate => (is => 'rw', isa => 'Str', printOrder => '-1', lazy => 1, builder => '_build_modDate', type => 'attribute', metaclass => 'Typed');
has class => (is => 'rw', isa => 'Str', printOrder => '0', default => '0', type => 'attribute', metaclass => 'Typed');
has compound_link => (is => 'rw', isa => 'ModelSEED::subobject_link', printOrder => '0', type => 'attribute', metaclass => 'Typed');
has coefficientType => (is => 'rw', isa => 'Str', printOrder => '0', default => '0', type => 'attribute', metaclass => 'Typed');
has coefficient => (is => 'rw', isa => 'Num', printOrder => '0', default => '0', type => 'attribute', metaclass => 'Typed');
has condition => (is => 'rw', isa => 'Str', printOrder => '0', default => '0', type => 'attribute', metaclass => 'Typed');


# LINKS:
has compound => (is => 'rw', type => 'link(Biochemistry,compounds,compound_link)', metaclass => 'Typed', lazy => 1, builder => '_build_compound', clearer => 'clear_compound', isa => 'ModelSEED::MS::Compound', weak_ref => 1);


# BUILDERS:
sub _build_modDate { return DateTime->now()->datetime(); }
sub _build_compound {
  my ($self) = @_;
  return $self->getLinkedObject('Biochemistry','compounds',$self->compound_link());
}


# CONSTANTS:
sub _type { return 'BiomassTemplateComponent'; }

my $attributes = [
          {
            'req' => 1,
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
            'name' => 'class',
            'default' => '0',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'compound_link',
            'type' => 'ModelSEED::subobject_link',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'coefficientType',
            'default' => '0',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'coefficient',
            'default' => '0',
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'condition',
            'default' => '0',
            'type' => 'Str',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {uid => 0, modDate => 1, class => 2, compound_link => 3, coefficientType => 4, coefficient => 5, condition => 6};
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
