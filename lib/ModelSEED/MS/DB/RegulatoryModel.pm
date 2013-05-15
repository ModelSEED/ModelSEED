########################################################################
# ModelSEED::MS::DB::RegulatoryModel - This is the moose object corresponding to the RegulatoryModel object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package ModelSEED::MS::DB::RegulatoryModel;
use ModelSEED::MS::IndexedObject;
use ModelSEED::MS::RegulatoryModelRegulon;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::IndexedObject';


our $VERSION = 2;
# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');


# ATTRIBUTES:
has uuid => (is => 'rw', isa => 'ModelSEED::uuid', printOrder => '0', lazy => 1, builder => '_build_uuid', type => 'attribute', metaclass => 'Typed');
has defaultNameSpace => (is => 'rw', isa => 'Str', printOrder => '3', default => 'ModelSEED', type => 'attribute', metaclass => 'Typed');
has modDate => (is => 'rw', isa => 'Str', printOrder => '-1', lazy => 1, builder => '_build_modDate', type => 'attribute', metaclass => 'Typed');
has name => (is => 'rw', isa => 'Str', printOrder => '2', default => '', type => 'attribute', metaclass => 'Typed');
has type => (is => 'rw', isa => 'Str', printOrder => '5', default => 'AutoModel', type => 'attribute', metaclass => 'Typed');
has mapping_uuid => (is => 'rw', isa => 'Str', printOrder => '9', required => 1, type => 'attribute', metaclass => 'Typed');
has annotation_uuid => (is => 'rw', isa => 'Str', printOrder => '10', type => 'attribute', metaclass => 'Typed');
has forwardedLinks => (is => 'rw', isa => 'HashRef', printOrder => '-1', default => sub {return {};}, type => 'attribute', metaclass => 'Typed');


# ANCESTOR:
has ancestor_uuid => (is => 'rw', isa => 'uuid', type => 'ancestor', metaclass => 'Typed');


# SUBOBJECTS:
has regulatoryModelRegulons => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(RegulatoryModelRegulon)', metaclass => 'Typed', reader => '_regulatoryModelRegulons', printOrder => '3');


# LINKS:
has mapping => (is => 'rw', type => 'link(ModelSEED::Store,Mapping,mapping_uuid)', metaclass => 'Typed', lazy => 1, builder => '_build_mapping', clearer => 'clear_mapping', isa => 'ModelSEED::MS::Mapping');
has annotation => (is => 'rw', type => 'link(ModelSEED::Store,Annotation,annotation_uuid)', metaclass => 'Typed', lazy => 1, builder => '_build_annotation', clearer => 'clear_annotation', isa => 'ModelSEED::MS::Annotation');


# BUILDERS:
sub _build_uuid { return Data::UUID->new()->create_str(); }
sub _build_modDate { return DateTime->now()->datetime(); }
sub _build_mapping {
  my ($self) = @_;
  return $self->getLinkedObject('ModelSEED::Store','Mapping',$self->mapping_uuid());
}
sub _build_annotation {
  my ($self) = @_;
  return $self->getLinkedObject('ModelSEED::Store','Annotation',$self->annotation_uuid());
}


# CONSTANTS:
sub __version__ { return $VERSION; }
sub _type { return 'RegulatoryModel'; }

my $attributes = [
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'uuid',
            'type' => 'ModelSEED::uuid',
            'perm' => 'rw'
          },
          {
            'len' => 32,
            'req' => 0,
            'printOrder' => 3,
            'name' => 'defaultNameSpace',
            'default' => 'ModelSEED',
            'type' => 'Str',
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
          },
          {
            'len' => 32,
            'req' => 0,
            'printOrder' => 5,
            'name' => 'type',
            'default' => 'AutoModel',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => 9,
            'name' => 'mapping_uuid',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 10,
            'name' => 'annotation_uuid',
            'type' => 'Str',
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

my $attribute_map = {uuid => 0, defaultNameSpace => 1, modDate => 2, name => 3, type => 4, mapping_uuid => 5, annotation_uuid => 6, forwardedLinks => 7};
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
            'attribute' => 'mapping_uuid',
            'weak' => 0,
            'parent' => 'ModelSEED::Store',
            'clearer' => 'clear_mapping',
            'name' => 'mapping',
            'class' => 'Mapping',
            'method' => 'Mapping'
          },
          {
            'attribute' => 'annotation_uuid',
            'weak' => 0,
            'parent' => 'ModelSEED::Store',
            'clearer' => 'clear_annotation',
            'name' => 'annotation',
            'class' => 'Annotation',
            'method' => 'Annotation'
          }
        ];

my $link_map = {mapping => 0, annotation => 1};
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
            'printOrder' => 3,
            'name' => 'regulatoryModelRegulons',
            'type' => 'child',
            'class' => 'RegulatoryModelRegulon'
          }
        ];

my $subobject_map = {regulatoryModelRegulons => 0};
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
around 'regulatoryModelRegulons' => sub {
  my ($orig, $self) = @_;
  return $self->_build_all_objects('regulatoryModelRegulons');
};


__PACKAGE__->meta->make_immutable;
1;
