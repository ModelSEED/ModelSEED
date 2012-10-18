########################################################################
# ModelSEED::MS::DB::ModelReactionProtein - This is the moose object corresponding to the ModelReactionProtein object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package ModelSEED::MS::DB::ModelReactionProtein;
use ModelSEED::MS::BaseObject;
use ModelSEED::MS::ModelReactionProteinSubunit;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'ModelSEED::MS::ModelReaction', weak_ref => 1, type => 'parent', metaclass => 'Typed');


# ATTRIBUTES:
has complex_uuid => (is => 'rw', isa => 'ModelSEED::uuid', printOrder => '0', required => 1, trigger => &_trigger_complex_uuid, type => 'attribute', metaclass => 'Typed');
has note => (is => 'rw', isa => 'Str', printOrder => '0', default => '', type => 'attribute', metaclass => 'Typed');


# SUBOBJECTS:
has modelReactionProteinSubunits => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'encompassed(ModelReactionProteinSubunit)', metaclass => 'Typed', reader => '_modelReactionProteinSubunits', printOrder => '-1');


# LINKS:
has complex => (is => 'rw', type => 'link(Mapping,complexes,complex_uuid)', metaclass => 'Typed', lazy => 1, builder => '_build_complex', clearer => 'clear_complex', trigger => &_trigger_complex, isa => 'ModelSEED::MS::Complex', weak_ref => 1);


# BUILDERS:
sub _build_complex {
  my ($self) = @_;
  return $self->getLinkedObject('Mapping','complexes',$self->complex_uuid());
}
sub _trigger_complex {
   my ($self, $new, $old) = @_;
   $self->complex_uuid( $new->uuid );
}
sub _trigger_complex_uuid {
    my ($self, $new, $old) = @_;
    $self->clear_complex if( $self->complex->uuid ne $new );
}


# CONSTANTS:
sub _type { return 'ModelReactionProtein'; }

my $attributes = [
          {
            'req' => 1,
            'printOrder' => 0,
            'name' => 'complex_uuid',
            'type' => 'ModelSEED::uuid',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'note',
            'default' => '',
            'type' => 'Str',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {complex_uuid => 0, note => 1};
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
            'attribute' => 'complex_uuid',
            'parent' => 'Mapping',
            'clearer' => 'clear_complex',
            'name' => 'complex',
            'class' => 'complexes',
            'method' => 'complexes'
          }
        ];

my $link_map = {complex => 0};
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
            'printOrder' => -1,
            'name' => 'modelReactionProteinSubunits',
            'type' => 'encompassed',
            'class' => 'ModelReactionProteinSubunit'
          }
        ];

my $subobject_map = {modelReactionProteinSubunits => 0};
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
around 'modelReactionProteinSubunits' => sub {
  my ($orig, $self) = @_;
  return $self->_build_all_objects('modelReactionProteinSubunits');
};


__PACKAGE__->meta->make_immutable;
1;
