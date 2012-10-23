########################################################################
# ModelSEED::MS::DB::GapgenFormulation - This is the moose object corresponding to the GapgenFormulation object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package ModelSEED::MS::DB::GapgenFormulation;
use ModelSEED::MS::BaseObject;
use ModelSEED::MS::GapgenSolution;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'ModelSEED::Store', type => 'parent', metaclass => 'Typed');


# ATTRIBUTES:
has uid => (is => 'rw', isa => 'ModelSEED::uid', printOrder => '0', type => 'attribute', metaclass => 'Typed');
has fbaFormulation_link => (is => 'rw', isa => 'ModelSEED::provenance_link', printOrder => '0', type => 'attribute', metaclass => 'Typed');
has model_link => (is => 'rw', isa => 'ModelSEED::provenance_link', printOrder => '-1', required => 1, type => 'attribute', metaclass => 'Typed');
has mediaHypothesis => (is => 'rw', isa => 'Bool', printOrder => '0', default => '0', type => 'attribute', metaclass => 'Typed');
has biomassHypothesis => (is => 'rw', isa => 'Bool', printOrder => '0', default => '0', type => 'attribute', metaclass => 'Typed');
has gprHypothesis => (is => 'rw', isa => 'Bool', printOrder => '0', default => '0', type => 'attribute', metaclass => 'Typed');
has reactionRemovalHypothesis => (is => 'rw', isa => 'Bool', printOrder => '0', default => '1', type => 'attribute', metaclass => 'Typed');
has referenceMedia_link => (is => 'rw', isa => 'ModelSEED::subobject_link', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');
has modDate => (is => 'rw', isa => 'Str', printOrder => '-1', lazy => 1, builder => '_build_modDate', type => 'attribute', metaclass => 'Typed');


# SUBOBJECTS:
has gapgenSolutions => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'encompassed(GapgenSolution)', metaclass => 'Typed', reader => '_gapgenSolutions', printOrder => '0');


# LINKS:
has model => (is => 'rw', type => 'link(ModelSEED::Store,Model,model_link)', metaclass => 'Typed', lazy => 1, builder => '_build_model', clearer => 'clear_model', isa => 'ModelSEED::MS::Model');
has fbaFormulation => (is => 'rw', type => 'link(ModelSEED::Store,FBAFormulation,fbaFormulation_link)', metaclass => 'Typed', lazy => 1, builder => '_build_fbaFormulation', clearer => 'clear_fbaFormulation', isa => 'ModelSEED::MS::FBAFormulation');
has referenceMedia => (is => 'rw', type => 'link(Biochemistry,media,referenceMedia_link)', metaclass => 'Typed', lazy => 1, builder => '_build_referenceMedia', clearer => 'clear_referenceMedia', isa => 'ModelSEED::MS::Media', weak_ref => 1);


# BUILDERS:
sub _build_modDate { return DateTime->now()->datetime(); }
sub _build_model {
  my ($self) = @_;
  return $self->getLinkedObject('ModelSEED::Store','Model',$self->model_link());
}
sub _build_fbaFormulation {
  my ($self) = @_;
  return $self->getLinkedObject('ModelSEED::Store','FBAFormulation',$self->fbaFormulation_link());
}
sub _build_referenceMedia {
  my ($self) = @_;
  return $self->getLinkedObject('Biochemistry','media',$self->referenceMedia_link());
}


# CONSTANTS:
sub _type { return 'GapgenFormulation'; }

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
            'printOrder' => 0,
            'name' => 'fbaFormulation_link',
            'type' => 'ModelSEED::provenance_link',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => -1,
            'name' => 'model_link',
            'type' => 'ModelSEED::provenance_link',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'mediaHypothesis',
            'default' => '0',
            'type' => 'Bool',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'biomassHypothesis',
            'default' => '0',
            'type' => 'Bool',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'gprHypothesis',
            'default' => '0',
            'type' => 'Bool',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'reactionRemovalHypothesis',
            'default' => '1',
            'type' => 'Bool',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => 0,
            'name' => 'referenceMedia_link',
            'type' => 'ModelSEED::subobject_link',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'modDate',
            'type' => 'Str',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {uid => 0, fbaFormulation_link => 1, model_link => 2, mediaHypothesis => 3, biomassHypothesis => 4, gprHypothesis => 5, reactionRemovalHypothesis => 6, referenceMedia_link => 7, modDate => 8};
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
            'attribute' => 'model_link',
            'weak' => 0,
            'parent' => 'ModelSEED::Store',
            'clearer' => 'clear_model',
            'name' => 'model',
            'class' => 'Model',
            'method' => 'Model'
          },
          {
            'attribute' => 'fbaFormulation_link',
            'weak' => 0,
            'parent' => 'ModelSEED::Store',
            'clearer' => 'clear_fbaFormulation',
            'name' => 'fbaFormulation',
            'class' => 'FBAFormulation',
            'method' => 'FBAFormulation'
          },
          {
            'attribute' => 'referenceMedia_link',
            'parent' => 'Biochemistry',
            'clearer' => 'clear_referenceMedia',
            'name' => 'referenceMedia',
            'class' => 'media',
            'method' => 'media'
          }
        ];

my $link_map = {model => 0, fbaFormulation => 1, referenceMedia => 2};
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
            'printOrder' => 0,
            'name' => 'gapgenSolutions',
            'type' => 'encompassed',
            'class' => 'GapgenSolution'
          }
        ];

my $subobject_map = {gapgenSolutions => 0};
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
around 'gapgenSolutions' => sub {
  my ($orig, $self) = @_;
  return $self->_build_all_objects('gapgenSolutions');
};


__PACKAGE__->meta->make_immutable;
1;
