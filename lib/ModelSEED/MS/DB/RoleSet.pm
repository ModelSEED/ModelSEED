########################################################################
# ModelSEED::MS::DB::RoleSet - This is the moose object corresponding to the RoleSet object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package ModelSEED::MS::DB::RoleSet;
use ModelSEED::MS::BaseObject;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'ModelSEED::MS::Mapping', weak_ref => 1, type => 'parent', metaclass => 'Typed');


# ATTRIBUTES:
has uid => (is => 'rw', isa => 'ModelSEED::uid', printOrder => '0', type => 'attribute', metaclass => 'Typed');
has modDate => (is => 'rw', isa => 'Str', printOrder => '-1', lazy => 1, builder => '_build_modDate', type => 'attribute', metaclass => 'Typed');
has name => (is => 'rw', isa => 'ModelSEED::varchar', printOrder => '3', default => '', type => 'attribute', metaclass => 'Typed');
has class => (is => 'rw', isa => 'ModelSEED::varchar', printOrder => '1', default => 'unclassified', type => 'attribute', metaclass => 'Typed');
has subclass => (is => 'rw', isa => 'ModelSEED::varchar', printOrder => '2', default => 'unclassified', type => 'attribute', metaclass => 'Typed');
has type => (is => 'rw', isa => 'Str', printOrder => '4', required => 1, type => 'attribute', metaclass => 'Typed');
has role_links => (is => 'rw', isa => 'ArrayRef[ModelSEED::subobject_link]', printOrder => '-1', default => sub{return [];}, type => 'attribute', metaclass => 'Typed');


# LINKS:
has roles => (is => 'rw', type => 'link(Mapping,roles,role_links)', metaclass => 'Typed', lazy => 1, builder => '_build_roles', clearer => 'clear_roles', isa => 'ArrayRef');
has id => (is => 'rw', lazy => 1, builder => '_build_id', isa => 'Str', type => 'id', metaclass => 'Typed');


# BUILDERS:
sub _build_modDate { return DateTime->now()->datetime(); }
sub _build_roles {
  my ($self) = @_;
  return $self->getLinkedObjectArray('Mapping','roles',$self->role_links());
}


# CONSTANTS:
sub _type { return 'RoleSet'; }

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
            'printOrder' => 3,
            'name' => 'name',
            'default' => '',
            'type' => 'ModelSEED::varchar',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 1,
            'name' => 'class',
            'default' => 'unclassified',
            'type' => 'ModelSEED::varchar',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 2,
            'name' => 'subclass',
            'default' => 'unclassified',
            'type' => 'ModelSEED::varchar',
            'perm' => 'rw'
          },
          {
            'len' => 32,
            'req' => 1,
            'printOrder' => 4,
            'name' => 'type',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'role_links',
            'default' => 'sub{return [];}',
            'type' => 'ArrayRef[ModelSEED::subobject_link]',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {uid => 0, modDate => 1, name => 2, class => 3, subclass => 4, type => 5, role_links => 6};
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
            'attribute' => 'role_links',
            'parent' => 'Mapping',
            'clearer' => 'clear_roles',
            'name' => 'roles',
            'class' => 'roles',
            'method' => 'roles'
          }
        ];

my $link_map = {roles => 0};
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
sub _aliasowner { return 'Mapping'; }


__PACKAGE__->meta->make_immutable;
1;
