########################################################################
# ModelSEED::MS::DB::Complex - This is the moose object corresponding to the Complex object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package ModelSEED::MS::DB::Complex;
use ModelSEED::MS::BaseObject;
use ModelSEED::MS::ComplexRole;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'ModelSEED::MS::Mapping', weak_ref => 1, type => 'parent', metaclass => 'Typed');


# ATTRIBUTES:
has uid => (is => 'rw', isa => 'ModelSEED::uid', printOrder => '0', type => 'attribute', metaclass => 'Typed');
has modDate => (is => 'rw', isa => 'Str', printOrder => '-1', lazy => 1, builder => '_build_modDate', type => 'attribute', metaclass => 'Typed');
has name => (is => 'rw', isa => 'ModelSEED::varchar', printOrder => '1', default => '', type => 'attribute', metaclass => 'Typed');
has reaction_links => (is => 'rw', isa => 'ArrayRef[ModelSEED::subobject_link]', printOrder => '-1', default => sub{return [];}, type => 'attribute', metaclass => 'Typed');


# SUBOBJECTS:
has complexroles => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'encompassed(ComplexRole)', metaclass => 'Typed', reader => '_complexroles', printOrder => '-1');


# LINKS:
has reactions => (is => 'rw', type => 'link(Biochemistry,reactions,reaction_links)', metaclass => 'Typed', lazy => 1, builder => '_build_reactions', clearer => 'clear_reactions', isa => 'ArrayRef');
has id => (is => 'rw', lazy => 1, builder => '_build_id', isa => 'Str', type => 'id', metaclass => 'Typed');


# BUILDERS:
sub _build_modDate { return DateTime->now()->datetime(); }
sub _build_reactions {
  my ($self) = @_;
  return $self->getLinkedObjectArray('Biochemistry','reactions',$self->reaction_links());
}


# CONSTANTS:
sub _type { return 'Complex'; }

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
            'req' => 0,
            'printOrder' => 1,
            'name' => 'name',
            'default' => '',
            'type' => 'ModelSEED::varchar',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'reaction_links',
            'default' => 'sub{return [];}',
            'type' => 'ArrayRef[ModelSEED::subobject_link]',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {uid => 0, modDate => 1, name => 2, reaction_links => 3};
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
            'array' => 1,
            'attribute' => 'reaction_links',
            'parent' => 'Biochemistry',
            'clearer' => 'clear_reactions',
            'name' => 'reactions',
            'class' => 'reactions',
            'method' => 'reactions'
          }
        ];

my $link_map = {reactions => 0};
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
            'name' => 'complexroles',
            'type' => 'encompassed',
            'class' => 'ComplexRole'
          }
        ];

my $subobject_map = {complexroles => 0};
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
sub _aliasowner { return 'Mapping'; }


# SUBOBJECT READERS:
around 'complexroles' => sub {
  my ($orig, $self) = @_;
  return $self->_build_all_objects('complexroles');
};


__PACKAGE__->meta->make_immutable;
1;
