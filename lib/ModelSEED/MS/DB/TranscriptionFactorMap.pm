########################################################################
# ModelSEED::MS::DB::TranscriptionFactorMap - This is the moose object corresponding to the TranscriptionFactorMap object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package ModelSEED::MS::DB::TranscriptionFactorMap;
use ModelSEED::MS::BaseObject;
use ModelSEED::MS::TranscriptionFactorMapTarget;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'ModelSEED::MS::PROMModel', weak_ref => 1, type => 'parent', metaclass => 'Typed');


# ATTRIBUTES:
has uuid => (is => 'rw', isa => 'ModelSEED::uuid', printOrder => '0', lazy => 1, builder => '_build_uuid', type => 'attribute', metaclass => 'Typed');
has transcriptionFactor_uuid => (is => 'rw', isa => 'ModelSEED::varchar', printOrder => '1', required => 1, type => 'attribute', metaclass => 'Typed');
has modDate => (is => 'rw', isa => 'Str', printOrder => '-1', lazy => 1, builder => '_build_modDate', type => 'attribute', metaclass => 'Typed');
has name => (is => 'rw', isa => 'Str', printOrder => '2', default => '', type => 'attribute', metaclass => 'Typed');


# ANCESTOR:
has ancestor_uuid => (is => 'rw', isa => 'uuid', type => 'ancestor', metaclass => 'Typed');


# SUBOBJECTS:
has transcriptionFactorMapTargets => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'encompassed(TranscriptionFactorMapTarget)', metaclass => 'Typed', reader => '_transcriptionFactorMapTargets', printOrder => '0');


# LINKS:
has transcriptionFactor => (is => 'rw', type => 'link(Annotation,features,transcriptionFactor_uuid)', metaclass => 'Typed', lazy => 1, builder => '_build_transcriptionFactor', clearer => 'clear_transcriptionFactor', isa => 'ModelSEED::MS::Feature', weak_ref => 1);


# BUILDERS:
sub _build_uuid { return Data::UUID->new()->create_str(); }
sub _build_modDate { return DateTime->now()->datetime(); }
sub _build_transcriptionFactor {
  my ($self) = @_;
  return $self->getLinkedObject('Annotation','features',$self->transcriptionFactor_uuid());
}


# CONSTANTS:
sub _type { return 'TranscriptionFactorMap'; }

my $attributes = [
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'uuid',
            'type' => 'ModelSEED::uuid',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => 1,
            'name' => 'transcriptionFactor_uuid',
            'type' => 'ModelSEED::varchar',
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
            'len' => 32,
            'req' => 0,
            'printOrder' => 2,
            'name' => 'name',
            'default' => '',
            'type' => 'Str',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {uuid => 0, transcriptionFactor_uuid => 1, modDate => 2, name => 3};
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
            'attribute' => 'transcriptionFactor_uuid',
            'parent' => 'Annotation',
            'clearer' => 'clear_transcriptionFactor',
            'name' => 'transcriptionFactor',
            'class' => 'features',
            'method' => 'features'
          }
        ];

my $link_map = {transcriptionFactor => 0};
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
            'name' => 'transcriptionFactorMapTargets',
            'type' => 'encompassed',
            'class' => 'TranscriptionFactorMapTarget'
          }
        ];

my $subobject_map = {transcriptionFactorMapTargets => 0};
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
around 'transcriptionFactorMapTargets' => sub {
  my ($orig, $self) = @_;
  return $self->_build_all_objects('transcriptionFactorMapTargets');
};


__PACKAGE__->meta->make_immutable;
1;
