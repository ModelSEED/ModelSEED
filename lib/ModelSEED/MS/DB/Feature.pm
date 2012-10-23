########################################################################
# ModelSEED::MS::DB::Feature - This is the moose object corresponding to the Feature object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package ModelSEED::MS::DB::Feature;
use ModelSEED::MS::BaseObject;
use ModelSEED::MS::FeatureRole;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'ModelSEED::MS::Annotation', weak_ref => 1, type => 'parent', metaclass => 'Typed');


# ATTRIBUTES:
has uid => (is => 'rw', isa => 'ModelSEED::uid', printOrder => '0', type => 'attribute', metaclass => 'Typed');
has modDate => (is => 'rw', isa => 'Str', printOrder => '-1', lazy => 1, builder => '_build_modDate', type => 'attribute', metaclass => 'Typed');
has id => (is => 'rw', isa => 'Str', printOrder => '1', required => 1, type => 'attribute', metaclass => 'Typed');
has cksum => (is => 'rw', isa => 'ModelSEED::varchar', printOrder => '-1', default => '', type => 'attribute', metaclass => 'Typed');
has genome_link => (is => 'rw', isa => 'ModelSEED::subobject_link', printOrder => '-1', required => 1, type => 'attribute', metaclass => 'Typed');
has start => (is => 'rw', isa => 'Int', printOrder => '3', type => 'attribute', metaclass => 'Typed');
has stop => (is => 'rw', isa => 'Int', printOrder => '4', type => 'attribute', metaclass => 'Typed');
has contig => (is => 'rw', isa => 'Str', printOrder => '5', type => 'attribute', metaclass => 'Typed');
has direction => (is => 'rw', isa => 'Str', printOrder => '6', type => 'attribute', metaclass => 'Typed');
has sequence => (is => 'rw', isa => 'Str', printOrder => '-1', type => 'attribute', metaclass => 'Typed');
has type => (is => 'rw', isa => 'Str', printOrder => '7', type => 'attribute', metaclass => 'Typed');


# SUBOBJECTS:
has featureroles => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'encompassed(FeatureRole)', metaclass => 'Typed', reader => '_featureroles', printOrder => '-1');


# LINKS:
has genome => (is => 'rw', type => 'link(Annotation,genomes,genome_link)', metaclass => 'Typed', lazy => 1, builder => '_build_genome', clearer => 'clear_genome', isa => 'ModelSEED::MS::Genome', weak_ref => 1);


# BUILDERS:
sub _build_modDate { return DateTime->now()->datetime(); }
sub _build_genome {
  my ($self) = @_;
  return $self->getLinkedObject('Annotation','genomes',$self->genome_link());
}


# CONSTANTS:
sub _type { return 'Feature'; }

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
            'len' => 32,
            'req' => 1,
            'printOrder' => 1,
            'name' => 'id',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'cksum',
            'default' => '',
            'type' => 'ModelSEED::varchar',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => -1,
            'name' => 'genome_link',
            'type' => 'ModelSEED::subobject_link',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 3,
            'name' => 'start',
            'type' => 'Int',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 4,
            'name' => 'stop',
            'type' => 'Int',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 5,
            'name' => 'contig',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 6,
            'name' => 'direction',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'sequence',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 7,
            'name' => 'type',
            'type' => 'Str',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {uid => 0, modDate => 1, id => 2, cksum => 3, genome_link => 4, start => 5, stop => 6, contig => 7, direction => 8, sequence => 9, type => 10};
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
            'attribute' => 'genome_link',
            'parent' => 'Annotation',
            'clearer' => 'clear_genome',
            'name' => 'genome',
            'class' => 'genomes',
            'method' => 'genomes'
          }
        ];

my $link_map = {genome => 0};
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
            'name' => 'featureroles',
            'type' => 'encompassed',
            'class' => 'FeatureRole'
          }
        ];

my $subobject_map = {featureroles => 0};
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
around 'featureroles' => sub {
  my ($orig, $self) = @_;
  return $self->_build_all_objects('featureroles');
};


__PACKAGE__->meta->make_immutable;
1;
