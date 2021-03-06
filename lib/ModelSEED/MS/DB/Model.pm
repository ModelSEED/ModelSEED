########################################################################
# ModelSEED::MS::DB::Model - This is the moose object corresponding to the Model object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package ModelSEED::MS::DB::Model;
use ModelSEED::MS::IndexedObject;
use ModelSEED::MS::Biomass;
use ModelSEED::MS::ModelCompartment;
use ModelSEED::MS::ModelCompound;
use ModelSEED::MS::ModelReaction;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::IndexedObject';


our $VERSION = 2;
# PARENT:
has parent => (is => 'rw', isa => 'Ref', weak_ref => 1, type => 'parent', metaclass => 'Typed');


# ATTRIBUTES:
has uuid => (is => 'rw', isa => 'ModelSEED::uuid', printOrder => '0', lazy => 1, builder => '_build_uuid', type => 'attribute', metaclass => 'Typed');
has kbid => (is => 'rw', isa => 'Str', printOrder => '0', type => 'attribute', metaclass => 'Typed');
has source_id => (is => 'rw', isa => 'Str', printOrder => '0', type => 'attribute', metaclass => 'Typed');
has source => (is => 'rw', isa => 'Str', printOrder => '0', type => 'attribute', metaclass => 'Typed');
has defaultNameSpace => (is => 'rw', isa => 'Str', printOrder => '3', default => 'ModelSEED', type => 'attribute', metaclass => 'Typed');
has modDate => (is => 'rw', isa => 'Str', printOrder => '-1', lazy => 1, builder => '_build_modDate', type => 'attribute', metaclass => 'Typed');
has id => (is => 'rw', isa => 'ModelSEED::varchar', printOrder => '1', required => 1, type => 'attribute', metaclass => 'Typed');
has name => (is => 'rw', isa => 'Str', printOrder => '2', default => '', type => 'attribute', metaclass => 'Typed');
has version => (is => 'rw', isa => 'Int', printOrder => '3', default => '0', type => 'attribute', metaclass => 'Typed');
has type => (is => 'rw', isa => 'Str', printOrder => '5', default => 'Singlegenome', type => 'attribute', metaclass => 'Typed');
has status => (is => 'rw', isa => 'Str', printOrder => '7', type => 'attribute', metaclass => 'Typed');
has growth => (is => 'rw', isa => 'Num', printOrder => '6', type => 'attribute', metaclass => 'Typed');
has current => (is => 'rw', isa => 'Int', printOrder => '4', default => '1', type => 'attribute', metaclass => 'Typed');
has mapping_uuid => (is => 'rw', isa => 'Str', printOrder => '8', type => 'attribute', metaclass => 'Typed');
has biochemistry_uuid => (is => 'rw', isa => 'Str', printOrder => '9', required => 1, type => 'attribute', metaclass => 'Typed');
has annotation_uuid => (is => 'rw', isa => 'Str', printOrder => '10', type => 'attribute', metaclass => 'Typed');
has Genome_wsid => (is => 'rw', isa => 'Str', printOrder => '10', type => 'attribute', metaclass => 'Typed');
has MetagenomeAnno_wsid => (is => 'rw', isa => 'Str', printOrder => '10', type => 'attribute', metaclass => 'Typed');
has ModelTemplate_wsid => (is => 'rw', isa => 'Str', printOrder => '10', type => 'attribute', metaclass => 'Typed');
has fbaFormulation_uuids => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub{return [];}, type => 'attribute', metaclass => 'Typed');
has integratedGapfilling_uuids => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub{return [];}, type => 'attribute', metaclass => 'Typed');
has integratedGapfillingSolutions => (is => 'rw', isa => 'HashRef', printOrder => '-1', default => sub{return {};}, type => 'attribute', metaclass => 'Typed');
has unintegratedGapfilling_uuids => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub{return [];}, type => 'attribute', metaclass => 'Typed');
has integratedGapgen_uuids => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub{return [];}, type => 'attribute', metaclass => 'Typed');
has integratedGapgenSolutions => (is => 'rw', isa => 'HashRef', printOrder => '-1', default => sub{return {};}, type => 'attribute', metaclass => 'Typed');
has unintegratedGapgen_uuids => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub{return [];}, type => 'attribute', metaclass => 'Typed');
has forwardedLinks => (is => 'rw', isa => 'HashRef', printOrder => '-1', default => sub {return {};}, type => 'attribute', metaclass => 'Typed');


# ANCESTOR:
has ancestor_uuid => (is => 'rw', isa => 'uuid', type => 'ancestor', metaclass => 'Typed');


# SUBOBJECTS:
has biomasses => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(Biomass)', metaclass => 'Typed', reader => '_biomasses', printOrder => '0');
has modelcompartments => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(ModelCompartment)', metaclass => 'Typed', reader => '_modelcompartments', printOrder => '1');
has modelcompounds => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(ModelCompound)', metaclass => 'Typed', reader => '_modelcompounds', printOrder => '2');
has modelreactions => (is => 'rw', isa => 'ArrayRef[HashRef]', default => sub { return []; }, type => 'child(ModelReaction)', metaclass => 'Typed', reader => '_modelreactions', printOrder => '3');


# LINKS:
has fbaFormulations => (is => 'rw', type => 'link(ModelSEED::Store,FBAFormulation,fbaFormulation_uuids)', metaclass => 'Typed', lazy => 1, builder => '_build_fbaFormulations', clearer => 'clear_fbaFormulations', isa => 'ArrayRef');
has unintegratedGapfillings => (is => 'rw', type => 'link(ModelSEED::Store,GapfillingFormulation,unintegratedGapfilling_uuids)', metaclass => 'Typed', lazy => 1, builder => '_build_unintegratedGapfillings', clearer => 'clear_unintegratedGapfillings', isa => 'ArrayRef');
has integratedGapfillings => (is => 'rw', type => 'link(ModelSEED::Store,GapfillingFormulation,integratedGapfilling_uuids)', metaclass => 'Typed', lazy => 1, builder => '_build_integratedGapfillings', clearer => 'clear_integratedGapfillings', isa => 'ArrayRef');
has unintegratedGapgens => (is => 'rw', type => 'link(ModelSEED::Store,GapgenFormulation,unintegratedGapgen_uuids)', metaclass => 'Typed', lazy => 1, builder => '_build_unintegratedGapgens', clearer => 'clear_unintegratedGapgens', isa => 'ArrayRef');
has integratedGapgens => (is => 'rw', type => 'link(ModelSEED::Store,GapgenFormulation,integratedGapgen_uuids)', metaclass => 'Typed', lazy => 1, builder => '_build_integratedGapgens', clearer => 'clear_integratedGapgens', isa => 'ArrayRef');
has biochemistry => (is => 'rw', type => 'link(ModelSEED::Store,Biochemistry,biochemistry_uuid)', metaclass => 'Typed', lazy => 1, builder => '_build_biochemistry', clearer => 'clear_biochemistry', isa => 'ModelSEED::MS::Biochemistry');
has mapping => (is => 'rw', type => 'link(ModelSEED::Store,Mapping,mapping_uuid)', metaclass => 'Typed', lazy => 1, builder => '_build_mapping', clearer => 'clear_mapping', isa => 'ModelSEED::MS::Mapping');
has annotation => (is => 'rw', type => 'link(ModelSEED::Store,Annotation,annotation_uuid)', metaclass => 'Typed', lazy => 1, builder => '_build_annotation', clearer => 'clear_annotation', isa => 'ModelSEED::MS::Annotation');


# BUILDERS:
sub _build_uuid { return Data::UUID->new()->create_str(); }
sub _build_modDate { return DateTime->now()->datetime(); }
sub _build_fbaFormulations {
  my ($self) = @_;
  return $self->getLinkedObjectArray('ModelSEED::Store','FBAFormulation',$self->fbaFormulation_uuids());
}
sub _build_unintegratedGapfillings {
  my ($self) = @_;
  return $self->getLinkedObjectArray('ModelSEED::Store','GapfillingFormulation',$self->unintegratedGapfilling_uuids());
}
sub _build_integratedGapfillings {
  my ($self) = @_;
  return $self->getLinkedObjectArray('ModelSEED::Store','GapfillingFormulation',$self->integratedGapfilling_uuids());
}
sub _build_unintegratedGapgens {
  my ($self) = @_;
  return $self->getLinkedObjectArray('ModelSEED::Store','GapgenFormulation',$self->unintegratedGapgen_uuids());
}
sub _build_integratedGapgens {
  my ($self) = @_;
  return $self->getLinkedObjectArray('ModelSEED::Store','GapgenFormulation',$self->integratedGapgen_uuids());
}
sub _build_biochemistry {
  my ($self) = @_;
  return $self->getLinkedObject('ModelSEED::Store','Biochemistry',$self->biochemistry_uuid());
}
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
sub _type { return 'Model'; }

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
            'name' => 'kbid',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'source_id',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 0,
            'name' => 'source',
            'type' => 'Str',
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
            'req' => 1,
            'printOrder' => 1,
            'name' => 'id',
            'type' => 'ModelSEED::varchar',
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
            'req' => 0,
            'printOrder' => 3,
            'name' => 'version',
            'default' => '0',
            'type' => 'Int',
            'perm' => 'rw'
          },
          {
            'len' => 32,
            'req' => 0,
            'printOrder' => 5,
            'name' => 'type',
            'default' => 'Singlegenome',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'len' => 32,
            'req' => 0,
            'printOrder' => 7,
            'name' => 'status',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 6,
            'name' => 'growth',
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 4,
            'name' => 'current',
            'default' => '1',
            'type' => 'Int',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 8,
            'name' => 'mapping_uuid',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => 9,
            'name' => 'biochemistry_uuid',
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
            'printOrder' => 10,
            'name' => 'Genome_wsid',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 10,
            'name' => 'MetagenomeAnno_wsid',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => 10,
            'name' => 'ModelTemplate_wsid',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'fbaFormulation_uuids',
            'default' => 'sub{return [];}',
            'type' => 'ArrayRef',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'integratedGapfilling_uuids',
            'default' => 'sub{return [];}',
            'type' => 'ArrayRef',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'integratedGapfillingSolutions',
            'default' => 'sub{return {};}',
            'type' => 'HashRef',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'unintegratedGapfilling_uuids',
            'default' => 'sub{return [];}',
            'type' => 'ArrayRef',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'integratedGapgen_uuids',
            'default' => 'sub{return [];}',
            'type' => 'ArrayRef',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'integratedGapgenSolutions',
            'default' => 'sub{return {};}',
            'type' => 'HashRef',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'unintegratedGapgen_uuids',
            'default' => 'sub{return [];}',
            'type' => 'ArrayRef',
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

my $attribute_map = {uuid => 0, kbid => 1, source_id => 2, source => 3, defaultNameSpace => 4, modDate => 5, id => 6, name => 7, version => 8, type => 9, status => 10, growth => 11, current => 12, mapping_uuid => 13, biochemistry_uuid => 14, annotation_uuid => 15, Genome_wsid => 16, MetagenomeAnno_wsid => 17, ModelTemplate_wsid => 18, fbaFormulation_uuids => 19, integratedGapfilling_uuids => 20, integratedGapfillingSolutions => 21, unintegratedGapfilling_uuids => 22, integratedGapgen_uuids => 23, integratedGapgenSolutions => 24, unintegratedGapgen_uuids => 25, forwardedLinks => 26};
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
            'attribute' => 'fbaFormulation_uuids',
            'parent' => 'ModelSEED::Store',
            'clearer' => 'clear_fbaFormulations',
            'name' => 'fbaFormulations',
            'class' => 'FBAFormulation',
            'method' => 'FBAFormulation'
          },
          {
            'array' => 1,
            'attribute' => 'unintegratedGapfilling_uuids',
            'parent' => 'ModelSEED::Store',
            'clearer' => 'clear_unintegratedGapfillings',
            'name' => 'unintegratedGapfillings',
            'class' => 'GapfillingFormulation',
            'method' => 'GapfillingFormulation'
          },
          {
            'array' => 1,
            'attribute' => 'integratedGapfilling_uuids',
            'parent' => 'ModelSEED::Store',
            'clearer' => 'clear_integratedGapfillings',
            'name' => 'integratedGapfillings',
            'class' => 'GapfillingFormulation',
            'method' => 'GapfillingFormulation'
          },
          {
            'array' => 1,
            'attribute' => 'unintegratedGapgen_uuids',
            'parent' => 'ModelSEED::Store',
            'clearer' => 'clear_unintegratedGapgens',
            'name' => 'unintegratedGapgens',
            'class' => 'GapgenFormulation',
            'method' => 'GapgenFormulation'
          },
          {
            'array' => 1,
            'attribute' => 'integratedGapgen_uuids',
            'parent' => 'ModelSEED::Store',
            'clearer' => 'clear_integratedGapgens',
            'name' => 'integratedGapgens',
            'class' => 'GapgenFormulation',
            'method' => 'GapgenFormulation'
          },
          {
            'attribute' => 'biochemistry_uuid',
            'weak' => 0,
            'parent' => 'ModelSEED::Store',
            'clearer' => 'clear_biochemistry',
            'name' => 'biochemistry',
            'class' => 'Biochemistry',
            'method' => 'Biochemistry'
          },
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

my $link_map = {fbaFormulations => 0, unintegratedGapfillings => 1, integratedGapfillings => 2, unintegratedGapgens => 3, integratedGapgens => 4, biochemistry => 5, mapping => 6, annotation => 7};
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
            'name' => 'biomasses',
            'type' => 'child',
            'class' => 'Biomass'
          },
          {
            'printOrder' => 1,
            'name' => 'modelcompartments',
            'type' => 'child',
            'class' => 'ModelCompartment'
          },
          {
            'printOrder' => 2,
            'name' => 'modelcompounds',
            'type' => 'child',
            'class' => 'ModelCompound'
          },
          {
            'printOrder' => 3,
            'name' => 'modelreactions',
            'type' => 'child',
            'class' => 'ModelReaction'
          }
        ];

my $subobject_map = {biomasses => 0, modelcompartments => 1, modelcompounds => 2, modelreactions => 3};
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
around 'biomasses' => sub {
  my ($orig, $self) = @_;
  return $self->_build_all_objects('biomasses');
};
around 'modelcompartments' => sub {
  my ($orig, $self) = @_;
  return $self->_build_all_objects('modelcompartments');
};
around 'modelcompounds' => sub {
  my ($orig, $self) = @_;
  return $self->_build_all_objects('modelcompounds');
};
around 'modelreactions' => sub {
  my ($orig, $self) = @_;
  return $self->_build_all_objects('modelreactions');
};


__PACKAGE__->meta->make_immutable;
1;
