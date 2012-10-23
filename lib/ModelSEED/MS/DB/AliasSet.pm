########################################################################
# ModelSEED::MS::DB::AliasSet - This is the moose object corresponding to the AliasSet object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package ModelSEED::MS::DB::AliasSet;
use ModelSEED::MS::IndexedObject;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::IndexedObject';


# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');


# ATTRIBUTES:
has uid => (is => 'rw', isa => 'ModelSEED::uid', printOrder => '0', type => 'attribute', metaclass => 'Typed');
has modDate => (is => 'rw', isa => 'Str', printOrder => '-1', lazy => 1, builder => '_build_modDate', type => 'attribute', metaclass => 'Typed');
has name => (is => 'rw', isa => 'Str', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');
has source => (is => 'rw', isa => 'Str', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');
has class => (is => 'rw', isa => 'Str', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');
has attribute => (is => 'rw', isa => 'Str', printOrder => '0', required => 1, type => 'attribute', metaclass => 'Typed');
has aliases => (is => 'rw', isa => 'HashRef', printOrder => '0', default => sub {return {};}, type => 'attribute', metaclass => 'Typed');


# LINKS:


# BUILDERS:
sub _build_modDate { return DateTime->now()->datetime(); }


# CONSTANTS:
sub _type { return 'AliasSet'; }

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
            'printOrder' => 0,
            'name' => 'name',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => 0,
            'name' => 'source',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => 0,
            'name' => 'class',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => 0,
            'name' => 'attribute',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'aliases',
            'default' => 'sub {return {};}',
            'type' => 'HashRef',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {uid => 0, modDate => 1, name => 2, source => 3, class => 4, attribute => 5, aliases => 6};
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

my $links = [];

my $link_map = {};
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
