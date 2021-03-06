########################################################################
# ModelSEED::MS::DB::FBAPhenotypeSimultationResult - This is the moose object corresponding to the FBAPhenotypeSimultationResult object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
package ModelSEED::MS::DB::FBAPhenotypeSimultationResult;
use ModelSEED::MS::BaseObject;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::BaseObject';


# PARENT:
has parent => (is => 'rw', isa => 'ModelSEED::MS::FBAResult', weak_ref => 1, type => 'parent', metaclass => 'Typed');


# ATTRIBUTES:
has simulatedGrowthFraction => (is => 'rw', isa => 'Num', printOrder => '3', required => 1, type => 'attribute', metaclass => 'Typed');
has simulatedGrowth => (is => 'rw', isa => 'Num', printOrder => '4', required => 1, type => 'attribute', metaclass => 'Typed');
has class => (is => 'rw', isa => 'Str', printOrder => '5', required => 1, type => 'attribute', metaclass => 'Typed');
has noGrowthCompounds => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub{return [];}, type => 'attribute', metaclass => 'Typed');
has dependantReactions => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub{return [];}, type => 'attribute', metaclass => 'Typed');
has dependantGenes => (is => 'rw', isa => 'ArrayRef', printOrder => '-1', default => sub{return [];}, type => 'attribute', metaclass => 'Typed');
has fluxes => (is => 'rw', isa => 'HashRef', printOrder => '-1', default => sub{return {};}, type => 'attribute', metaclass => 'Typed');
has fbaPhenotypeSimulation_uuid => (is => 'rw', isa => 'ModelSEED::uuid', printOrder => '-1', required => 1, type => 'attribute', metaclass => 'Typed');


# LINKS:
has fbaPhenotypeSimulation => (is => 'rw', type => 'link(FBAFormulation,fbaPhenotypeSimulations,fbaPhenotypeSimulation_uuid)', metaclass => 'Typed', lazy => 1, builder => '_build_fbaPhenotypeSimulation', clearer => 'clear_fbaPhenotypeSimulation', isa => 'ModelSEED::MS::FBAPhenotypeSimulation', weak_ref => 1);


# BUILDERS:
sub _build_fbaPhenotypeSimulation {
  my ($self) = @_;
  return $self->getLinkedObject('FBAFormulation','fbaPhenotypeSimulations',$self->fbaPhenotypeSimulation_uuid());
}


# CONSTANTS:
sub _type { return 'FBAPhenotypeSimultationResult'; }

my $attributes = [
          {
            'req' => 1,
            'printOrder' => 3,
            'name' => 'simulatedGrowthFraction',
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => 4,
            'name' => 'simulatedGrowth',
            'type' => 'Num',
            'perm' => 'rw'
          },
          {
            'len' => 1,
            'req' => 1,
            'printOrder' => 5,
            'name' => 'class',
            'type' => 'Str',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'noGrowthCompounds',
            'default' => 'sub{return [];}',
            'type' => 'ArrayRef',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'dependantReactions',
            'default' => 'sub{return [];}',
            'type' => 'ArrayRef',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'dependantGenes',
            'default' => 'sub{return [];}',
            'type' => 'ArrayRef',
            'perm' => 'rw'
          },
          {
            'req' => 0,
            'printOrder' => -1,
            'name' => 'fluxes',
            'default' => 'sub{return {};}',
            'type' => 'HashRef',
            'perm' => 'rw'
          },
          {
            'req' => 1,
            'printOrder' => -1,
            'name' => 'fbaPhenotypeSimulation_uuid',
            'type' => 'ModelSEED::uuid',
            'perm' => 'rw'
          }
        ];

my $attribute_map = {simulatedGrowthFraction => 0, simulatedGrowth => 1, class => 2, noGrowthCompounds => 3, dependantReactions => 4, dependantGenes => 5, fluxes => 6, fbaPhenotypeSimulation_uuid => 7};
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
            'attribute' => 'fbaPhenotypeSimulation_uuid',
            'parent' => 'FBAFormulation',
            'clearer' => 'clear_fbaPhenotypeSimulation',
            'name' => 'fbaPhenotypeSimulation',
            'class' => 'fbaPhenotypeSimulations',
            'method' => 'fbaPhenotypeSimulations'
          }
        ];

my $link_map = {fbaPhenotypeSimulation => 0};
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
