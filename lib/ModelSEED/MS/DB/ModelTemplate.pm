########################################################################
# ModelSEED::MS::DB::ModelTemplate - This is the moose object corresponding to the ModelTemplate object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package ModelSEED::MS::DB::ModelTemplate;
use ModelSEED::MS::IndexedObject;
use ModelSEED::MS::TemplateReaction;
use ModelSEED::MS::TemplateBiomass;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::IndexedObject';


our $VERSION = 1;
# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');


# ATTRIBUTES:
has uuid => (is => 'rw', isa => 'ModelSEED::uuid', printOrder => '0', lazy => 1, builder => '_build_uuid', type => 'attribute', metaclass => 'Typed');
has name => (is => 'rw', isa => 'ModelSEED::varchar', printOrder => '1', required => 1, type => 'attribute', metaclass => 'Typed');
has modelType => (is => 'rw', isa => 'ModelSEED::varchar', printOrder => '1', required => 1, type => 'attribute', metaclass => 'Typed');
has domain => (is => 'rw', isa => 'ModelSEED::varchar', printOrder => '2', required => 1, type => 'attribute', metaclass => 'Typed');
has mapping_uuid => (is => 'rw', isa => 'Str', printOrder => '3', required => 1, type => 'attribute', metaclass => 'Typed');


# ANCESTOR:
has ancestor_uuid => (is => 'rw', isa => 'uuid', type => 'ancestor', metaclass => 'Typed');


# SUBOBJECTS:
has templateReactions => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(TemplateReaction)', metaclass => 'Typed', reader => '_templateReactions', printOrder => '0');
has templateBiomasses => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(TemplateBiomass)', metaclass => 'Typed', reader => '_templateBiomasses', printOrder => '0');


# LINKS:
has mapping => (is => 'rw', type => 'link(ModelSEED::Store,Mapping,mapping_uuid)', metaclass => 'Typed', lazy => 1, builder => '_build_mapping', clearer => 'clear_mapping', isa => 'ModelSEED::MS::Mapping');


# BUILDERS:
sub _build_uuid { return Data::UUID->new()->create_str(); }
sub _build_mapping {
  my ($self) = @_;
  return $self->getLinkedObject('ModelSEED::Store','Mapping',$self->mapping_uuid());
}


# CONSTANTS:
sub __version__ { return $VERSION; }
sub _type { return 'ModelTemplate'; }

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
            'name' => 'name',
            'type' => 'ModelSEED::varchar',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => 1,
            'name' => 'modelType',
            'type' => 'ModelSEED::varchar',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => 2,
            'name' => 'domain',
            'type' => 'ModelSEED::varchar',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => 3,
            'name' => 'mapping_uuid',
            'type' => 'Str',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {uuid => 0, name => 1, modelType => 2, domain => 3, mapping_uuid => 4};
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
          }
        ];

my $link_map = {mapping => 0};
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
            'name' => 'templateReactions',
            'type' => 'child',
            'class' => 'TemplateReaction'
          },
          {
            'printOrder' => 0,
            'name' => 'templateBiomasses',
            'type' => 'child',
            'class' => 'TemplateBiomass'
          }
        ];

my $subobject_map = {templateReactions => 0, templateBiomasses => 1};
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
around 'templateReactions' => sub {
  my ($orig, $self) = @_;
  return $self->_build_all_objects('templateReactions');
};
around 'templateBiomasses' => sub {
  my ($orig, $self) = @_;
  return $self->_build_all_objects('templateBiomasses');
};


__PACKAGE__->meta->make_immutable;
1;
