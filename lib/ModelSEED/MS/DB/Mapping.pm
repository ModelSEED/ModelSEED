########################################################################
# ModelSEED::MS::DB::Mapping - This is the moose object corresponding to the Mapping object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package ModelSEED::MS::DB::Mapping;
use ModelSEED::MS::ProvenanceObject;
use ModelSEED::MS::UniversalReaction;
use ModelSEED::MS::BiomassTemplate;
use ModelSEED::MS::Role;
use ModelSEED::MS::RoleSet;
use ModelSEED::MS::Complex;
use ModelSEED::MS::AliasSet;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::ProvenanceObject';


our $VERSION = 2;
# PARENT:
has parent => (is => 'rw', isa => 'ModelSEED::Store', type => 'parent', metaclass => 'Typed');


# ATTRIBUTES:
has uid => (is => 'rw', isa => 'ModelSEED::uid', printOrder => '0', type => 'attribute', metaclass => 'Typed');
has modDate => (is => 'rw', isa => 'Str', printOrder => '-1', lazy => 1, builder => '_build_modDate', type => 'attribute', metaclass => 'Typed');
has name => (is => 'rw', isa => 'ModelSEED::varchar', printOrder => '1', default => '', type => 'attribute', metaclass => 'Typed');
has defaultNameSpace => (is => 'rw', isa => 'Str', printOrder => '2', default => 'SEED', type => 'attribute', metaclass => 'Typed');
has biochemistry_link => (is => 'rw', isa => 'ModelSEED::provenance_link', printOrder => '3', type => 'attribute', metaclass => 'Typed');
has forwardedLinks => (is => 'rw', isa => 'HashRef', printOrder => '-1', default => sub {return {};}, type => 'attribute', metaclass => 'Typed');


# SUBOBJECTS:
has universalReactions => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(UniversalReaction)', metaclass => 'Typed', reader => '_universalReactions', printOrder => '0');
has biomassTemplates => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(BiomassTemplate)', metaclass => 'Typed', reader => '_biomassTemplates', printOrder => '1');
has roles => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(Role)', metaclass => 'Typed', reader => '_roles', printOrder => '2');
has rolesets => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(RoleSet)', metaclass => 'Typed', reader => '_rolesets', printOrder => '3');
has complexes => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(Complex)', metaclass => 'Typed', reader => '_complexes', printOrder => '4');
has aliasSets => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(AliasSet)', metaclass => 'Typed', reader => '_aliasSets', printOrder => '-1');


# LINKS:
has biochemistry => (is => 'rw', type => 'link(ModelSEED::Store,Biochemistry,biochemistry_link)', metaclass => 'Typed', lazy => 1, builder => '_build_biochemistry', clearer => 'clear_biochemistry', isa => 'ModelSEED::MS::Biochemistry');


# BUILDERS:
sub _build_modDate { return DateTime->now()->datetime(); }
sub _build_biochemistry {
  my ($self) = @_;
  return $self->getLinkedObject('ModelSEED::Store','Biochemistry',$self->biochemistry_link());
}


# CONSTANTS:
sub __version__ { return $VERSION; }
sub _type { return 'Mapping'; }

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
            'len' => 32,
            'req' => 0,
            'printOrder' => 2,
            'name' => 'defaultNameSpace',
            'default' => 'SEED',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 3,
            'name' => 'biochemistry_link',
            'type' => 'ModelSEED::provenance_link',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'forwardedLinks',
            'default' => 'sub {return {};}',
            'type' => 'HashRef',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {uid => 0, modDate => 1, name => 2, defaultNameSpace => 3, biochemistry_link => 4, forwardedLinks => 5};
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
            'attribute' => 'biochemistry_link',
            'weak' => 0,
            'parent' => 'ModelSEED::Store',
            'clearer' => 'clear_biochemistry',
            'name' => 'biochemistry',
            'class' => 'Biochemistry',
            'method' => 'Biochemistry'
          }
        ];

my $link_map = {biochemistry => 0};
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
            'name' => 'universalReactions',
            'type' => 'child',
            'class' => 'UniversalReaction'
          },
          {
            'printOrder' => 1,
            'name' => 'biomassTemplates',
            'type' => 'child',
            'class' => 'BiomassTemplate'
          },
          {
            'printOrder' => 2,
            'name' => 'roles',
            'type' => 'child',
            'class' => 'Role'
          },
          {
            'printOrder' => 3,
            'name' => 'rolesets',
            'type' => 'child',
            'class' => 'RoleSet'
          },
          {
            'printOrder' => 4,
            'name' => 'complexes',
            'type' => 'child',
            'class' => 'Complex'
          },
          {
            'printOrder' => -1,
            'name' => 'aliasSets',
            'type' => 'child',
            'class' => 'AliasSet'
          }
        ];

my $subobject_map = {universalReactions => 0, biomassTemplates => 1, roles => 2, rolesets => 3, complexes => 4, aliasSets => 5};
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
around 'universalReactions' => sub {
  my ($orig, $self) = @_;
  return $self->_build_all_objects('universalReactions');
};
around 'biomassTemplates' => sub {
  my ($orig, $self) = @_;
  return $self->_build_all_objects('biomassTemplates');
};
around 'roles' => sub {
  my ($orig, $self) = @_;
  return $self->_build_all_objects('roles');
};
around 'rolesets' => sub {
  my ($orig, $self) = @_;
  return $self->_build_all_objects('rolesets');
};
around 'complexes' => sub {
  my ($orig, $self) = @_;
  return $self->_build_all_objects('complexes');
};
around 'aliasSets' => sub {
  my ($orig, $self) = @_;
  return $self->_build_all_objects('aliasSets');
};


__PACKAGE__->meta->make_immutable;
1;
