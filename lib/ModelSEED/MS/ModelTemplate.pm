########################################################################
# ModelSEED::MS::ModelTemplate - This is the moose object corresponding to the ModelTemplate object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2013-04-26T05:53:23
########################################################################
use strict;
use ModelSEED::MS::DB::ModelTemplate;
package ModelSEED::MS::ModelTemplate;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::DB::ModelTemplate';
#***********************************************************************************************************
# ADDITIONAL ATTRIBUTES:
#***********************************************************************************************************
has biochemistry => ( is => 'rw', isa => 'ModelSEED::MS::Biochemistry',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildbiochemistry' );

#***********************************************************************************************************
# BUILDERS:
#***********************************************************************************************************
sub _buildbiochemistry {
	my ($self) = @_;
	return $self->mapping()->biochemistry();
}

#***********************************************************************************************************
# CONSTANTS:
#***********************************************************************************************************

#***********************************************************************************************************
# FUNCTIONS:
#***********************************************************************************************************
sub buildModel {
    my $self = shift;
	my $args = ModelSEED::utilities::args(["annotation"],{}, @_);
	my $mdl = ModelSEED::MS::Model->new({
		id => $args->{annotation}->genomes()->[0]->id().".fbamdl.0",
		version => 0,
		type => $self->modelType(),
		name => $args->{annotation}->name(),
		growth => 0,
		status => "Reconstructed",
		current => 1,
		mapping_uuid => $self->mapping()->uuid(),
		mapping => $self->mapping(),
		biochemistry_uuid => $self->mapping()->biochemistry()->uuid(),
		biochemistry => $self->mapping()->biochemistry(),
		annotation_uuid => $args->{annotation}->uuid(),
		annotation => $args->{annotation}
	});
	my $rxns = $self->templateReactions();
	for (my $i=0; $i < @{$rxns}; $i++) {
		my $rxn = $rxns->[$i];
		$rxn->addRxnToModel({
			annotation => $args->{annotation},
			model => $mdl
		});
	}
	my $bios = $self->templateBiomasses();
	for (my $i=0; $i < @{$bios}; $i++) {
		my $bio = $bios->[$i];
		$bio->addBioToModel({
			annotation => $args->{annotation},
			model => $mdl
		});
	}
	return $mdl;
}

__PACKAGE__->meta->make_immutable;
1;
