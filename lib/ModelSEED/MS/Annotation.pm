########################################################################
# ModelSEED::MS::Annotation - This is the moose object corresponding to the Annotation object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-03-26T23:22:35
########################################################################
use strict;
use ModelSEED::MS::DB::Annotation;
package ModelSEED::MS::Annotation;

=head1 ModelSEED::MS::Annotation

This object is a provenance object that encapsulates the
genome annotations used to construct a metabolic model.

=head2 METHODS

=head3 roles

    \@ = $anno->roles;

Return an arrayref of L<ModelSEED::MS::Role> objects
that are part of the annotation object. Each genome in
an annotation object has features that may be annotated with
one or more functional roles. This list is the non-redundant 
set of those roles.

=head3 subsystems

Return an arrayref of L<ModelSEED::MS::RoleSet> objects
that are the set of subsystems contained within the annotation
object.

=head3 featuresInRoleSet

    \@ = $anno->featuresInRoleSet($roleSet);

Return an arrayref of L<ModelSEED::MS::Feature> objects that are
the set of features that are annotated with roles in the
L<ModelSEED::MS::RoleSet> provided as an argument.  Note that since
"Subsystems" are implemented as RoleSets, this will return the
features in a subsystem for this annotation object.

=head3 createStandardFBAModel

	$model = $anno->createStandardFBAModel(\%config);

Construct a standard FBA Model from the annotation object. Config
is a hash-ref that currently supports the following parameters:

=over 4

=item prefix

A prefix to append to the annotation's ID for the model name

=item mapping

A L<ModelSEED::MS::Mapping> object to use in place of the default one
contained within the annotation object.

=back

=head3 classifyGenomeFromAnnotation

    $string = $anno->classifyGenomeFromAnnotation

Return a string that defines what "kind" of annotation this is.
TODO: This is not implemented yet and only returns "Gram negative"

=cut

use ModelSEED::MS::Model;
use ModelSEED::utilities;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::DB::Annotation';

my $cmpTranslation = {
	extracellular => "e",
    cellwall => "w",
    periplasm => "p",
    cytosol => "c",
    golgi => "g",
    endoplasm => "r",
    lysosome => "l",
    nucleus => "n",
    chloroplast => "h",
    mitochondria => "m",
    peroxisome => "x",
    vacuole => "v",
    plastid => "d",
    unknown => "u",
};

#***********************************************************************************************************
# ADDITIONAL ATTRIBUTES:
#***********************************************************************************************************
has roleHash => ( is => 'rw', isa => 'HashRef',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildroleHash' );

#***********************************************************************************************************
# BUILDERS:
#***********************************************************************************************************
sub _buildroleHash {
	my ($self) = @_;
	my $roleFeatures;
	my $features = $self->features();
    ModelSEED::utilities::verbose("Processing " . scalar(@$features) . " features...");
	for (my $i=0; $i < @{$features}; $i++) {
		my $ftr = $features->[$i];
		my $ftrroles = $ftr->featureroles();
		for (my $j=0; $j < @{$ftrroles}; $j++) {
			my $ftrrole = $ftrroles->[$j];
			my $compartmentStr = $ftrrole->compartment();
			my $cmparray = [split(/;/,$compartmentStr)];
			for (my $k=0; $k < @{$cmparray}; $k++) {
				my $abbrev = $cmparray->[$k];
				if (length($cmparray->[$k]) > 1 && defined($cmpTranslation->{$cmparray->[$k]})) {
					$abbrev = $cmpTranslation->{$cmparray->[$k]};
				} elsif (length($cmparray->[$k]) > 1 && !defined($cmpTranslation->{$cmparray->[$k]})) {
					print STDERR "Compartment ".$cmparray->[$k]." not found!\n";
				}
				push(@{$roleFeatures->{$ftrrole->role_uuid()}->{$abbrev}},$ftr);
			}
		}
	}
	return $roleFeatures;
}

#***********************************************************************************************************
# CONSTANTS:
#***********************************************************************************************************

#***********************************************************************************************************
# FUNCTIONS:
#***********************************************************************************************************
=head3 GenerateGenomeObject

Definition:
	{} = ModelSEED::MS::Annotation->GenerateGenomeObject();
Description:
	Generates a KBase style genome object from the annotation object

=cut

sub GenerateGenomeObject {
    my ($self,$args) = @_;
    $args = ModelSEED::utilities::args([],{
		domain => "Bacteria",
		genome => 0,
		geneticcode => 11,
	}, $args);
	my $genomeobj = $self->genomes()->[$args->{genome}];
	my $genome = {
		source => "SEED",
		source_id => $genomeobj->id(),
		features => [],
		taxonomy => $genomeobj->taxonomy(),
		size => $genomeobj->size(),
		scientific_name => $genomeobj->name(),
		domain => $args->{domain},
		gc => $genomeobj->gc(),
		genetic_code => $args->{geneticcode},
		id => $genomeobj->id(),
		annotation_uuid => $self->uuid()
	};
	my $ftrs = $self->features();
	for (my $i=0; $i < @{$ftrs}; $i++) {
		my $ftr = $ftrs->[$i];
		my $direction = "+";
		if (defined($ftr->direction()) && $ftr->direction() eq "rev") {
			$direction = "-";
		}
		my $length = ($ftr->stop()-$ftr->start());
		push(@{$genome->{features}},{
			location => [[
				$ftr->contig(),
            	$ftr->start(),
            	$direction,
            	$length
			]],
			protein_translation => $ftr->sequence(),
			function => $ftr->roleList(),
			aliases => [],
			id => $ftr->id(),
			annotations => []
		});
	}
	return $genome;
}

=head3 searchForFeature

Definition:
	ModelSEED::MS::Feature = ModelSEED::MS::Annotation->searchForFeature(string id);
Description:
	Searches for the input Feature in the annotation

=cut

sub searchForFeature {
    my ($self,$feature) = @_;
	#First search by exact alias match
	my $obj = $self->getObjectByAlias("features",$feature);
	#Next, search by name
	if (!defined($obj)) {
		$obj = $self->queryObject("features",{id => $feature});
	}
	if (!defined($obj)) {
		$obj = $self->queryObject("features",{name => $feature});
	}
	return $obj;
}

=head3 export

Definition:
	string = ModelSEED::MS::Annotation->export();
Description:
	Exports annotation data to the specified format.

=cut

sub export {
    my $self = shift;
	my $args = ModelSEED::utilities::args(["format"], {}, @_);
	if (lc($args->{format}) eq "readable") {
		return $self->toReadableString();
	} elsif (lc($args->{format}) eq "html") {
		return $self->createHTML();
	} elsif (lc($args->{format}) eq "json") {
		return $self->toJSON({pp => 1});
	}
	ModelSEED::utilities::error("Unrecognized type for export: ".$args->{format});
}

sub roles {
    my ($self) = @_;
    my $roles = {};
    my $features = $self->features;
    foreach my $feature (@$features) {
        map { $roles->{$_->role->name} =  $_->role } @{$feature->featureroles};
    }
    return [values %$roles];
}

sub subsystems {
    my ($self) = @_;
    my $subsystems = [];
    my $roles = $self->roles;
    foreach my $role (@$roles) {
        my $results = $role->sets_with_role({type => "SEED Subsystem"});
        push(@$subsystems, @$results);
    }
    return $subsystems;
}

sub featuresInRoleSet {
    my ($self, $roleSet) = @_;
    my $roleHash = {};
    my $results = [];
    foreach my $roleSetRoleUUID (@{$roleSet->role_uuids()}) {
        $roleHash->{$roleSetRoleUUID} = 1;
    }
    my $features = $self->features;
    foreach my $feature (@$features) {
        my $featureRoles = $feature->featureroles;
        foreach my $featureRole (@$featureRoles) {
            if(defined($roleHash->{$featureRole->role_uuid})) {
                push(@$results, $feature);
                last;
            }
        }
    }
    return $results;
}

sub createStandardFBAModel {
    my $self = shift;
	my $args = ModelSEED::utilities::args([],{
		prefix => "Seed",
		mapping => $self->mapping(),
		verbose => 0,
		isplant => 0,
	}, @_);
	my $mapping = $args->{mapping};
	my $biochem = $mapping->biochemistry();
	my $type = "Singlegenome";
	if (@{$self->genomes()} > 1) {
		$type = "Metagenome";
	}
	my $mdl = ModelSEED::MS::Model->new({
		id => $args->{prefix}.$self->genomes()->[0]->id(),
		version => 0,
		type => $type,
		name => $self->name(),
		growth => 0,
		status => "Reconstruction started",
		current => 1,
		mapping_uuid => $mapping->uuid(),
		mapping => $mapping,
		biochemistry_uuid => $biochem->uuid(),
		biochemistry => $biochem,
		annotation_uuid => $self->uuid(),
		annotation => $self
	});
	$mdl->buildModelFromAnnotation($args);
	return $mdl;
}

sub classifyGenomeFromAnnotation {
    my $self = shift;
	my $map = $self->mapping();
	my $classifier = $map->typeClassifier();
	my $class = $classifier->classifyAnnotation({annotation => $self});
	ModelSEED::utilities::verbose("Classifier used to classify genome as ".$class->name()."!");
	return $class->name();
}

__PACKAGE__->meta->make_immutable;
1;
