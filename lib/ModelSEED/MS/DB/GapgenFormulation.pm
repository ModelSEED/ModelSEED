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
has parent => (is => 'rw', isa => 'ModelSEED::MS::Model', weak_ref => 1, type => 'parent', metaclass => 'Typed');


# ATTRIBUTES:
has uuid => (is => 'rw', isa => 'ModelSEED::uuid', printOrder => '0', lazy => 1, builder => '_build_uuid', type => 'attribute', metaclass => 'Typed');
has FBAFormulation_uuid => (is => 'rw', isa => 'ModelSEED::uuid', printOrder => '0', type => 'attribute', metaclass => 'Typed');
has mediaHypothesis => (is => 'rw', isa => 'Bool', printOrder => '0', default => '0', type => 'attribute', metaclass => 'Typed');
has biomassHypothesis => (is => 'rw', isa => 'Bool', printOrder => '0', default => '0', type => 'attribute', metaclass => 'Typed');
has gprHypothesis => (is => 'rw', isa => 'Bool', printOrder => '0', default => '0', type => 'attribute', metaclass => 'Typed');
has reactionRemovalHypothesis => (is => 'rw', isa => 'Bool', printOrder => '0', default => '1', type => 'attribute', metaclass => 'Typed');
has referenceMedia_uuid => (is => 'rw', isa => 'ModelSEED::uuid', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');
has modDate => (is => 'rw', isa => 'Str', printOrder => '-1', lazy => 1, builder => '_build_modDate', type => 'attribute', metaclass => 'Typed');


# ANCESTOR:
has ancestor_uuid => (is => 'rw', isa => 'uuid', type => 'ancestor', metaclass => 'Typed');


# SUBOBJECTS:
has gapgenSolutions => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'encompassed(GapgenSolution)', metaclass => 'Typed', reader => '_gapgenSolutions', printOrder => '-1');


# LINKS:
has FBAFormulation => (is => 'rw', isa => 'ModelSEED::MS::FBAFormulation', type => 'link(ModelSEED::Store,FBAFormulation,FBAFormulation_uuid)', metaclass => 'Typed', lazy => 1, builder => '_build_FBAFormulation');
has referenceMedia => (is => 'rw', isa => 'ModelSEED::MS::Media', type => 'link(Biochemistry,media,referenceMedia_uuid)', metaclass => 'Typed', lazy => 1, builder => '_build_referenceMedia', weak_ref => 1);


# BUILDERS:
sub _build_uuid { return Data::UUID->new()->create_str(); }
sub _build_modDate { return DateTime->now()->datetime(); }
sub _build_FBAFormulation {
  my ($self) = @_;
  return $self->getLinkedObject('ModelSEED::Store','FBAFormulation',$self->FBAFormulation_uuid());
}
sub _build_referenceMedia {
  my ($self) = @_;
  return $self->getLinkedObject('Biochemistry','media',$self->referenceMedia_uuid());
}


# CONSTANTS:
sub _type { return 'GapgenFormulation'; }

my $attributes = [
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'uuid',
            'type' => 'ModelSEED::uuid',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'FBAFormulation_uuid',
            'type' => 'ModelSEED::uuid',
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
            'name' => 'referenceMedia_uuid',
            'type' => 'ModelSEED::uuid',
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

my $attribute_map = {uuid => 0, FBAFormulation_uuid => 1, mediaHypothesis => 2, biomassHypothesis => 3, gprHypothesis => 4, reactionRemovalHypothesis => 5, referenceMedia_uuid => 6, modDate => 7};
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

my $subobjects = [
          {
            'printOrder' => -1,
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
