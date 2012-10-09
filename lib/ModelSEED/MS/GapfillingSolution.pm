########################################################################
# ModelSEED::MS::GapfillingSolution - This is the moose object corresponding to the GapfillingSolution object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-05-25T05:08:47
########################################################################
use strict;
use ModelSEED::MS::DB::GapfillingSolution;
package ModelSEED::MS::GapfillingSolution;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::DB::GapfillingSolution';
#***********************************************************************************************************
# ADDITIONAL ATTRIBUTES:
#***********************************************************************************************************
has gapfillingReactionString => ( is => 'rw',printOrder => 2, isa => 'Str', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildgapfillingReactionString' );
has biomassRemovalString => ( is => 'rw',printOrder => 3, isa => 'Str', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildbiomassRemovalString' );
has mediaSupplementString => ( is => 'rw',printOrder => 4, isa => 'Str', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildmediaSupplementString' );
has koRestoreString => ( is => 'rw',printOrder => 5, isa => 'Str', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildkoRestoreString' );

#***********************************************************************************************************
# BUILDERS:
#***********************************************************************************************************
sub _buildgapfillingReactionString {
	my ($self) = @_;
	my $string = "";
	my $gapfillingReactions = $self->gapfillingSolutionReactions();
	for (my $i=0; $i < @{$gapfillingReactions}; $i++) {
		if (length($string) > 0) {
			$string .= ";";
		}
		$string .= $gapfillingReactions->[$i]->reaction()->id().$gapfillingReactions->[$i]->direction();
	}
	return $string;
}
sub _buildbiomassRemovalString {
	my ($self) = @_;
	my $string = "";
	for (my $i=0; $i < @{$self->biomassRemovals()}; $i++) {
		if (length($string) > 0) {
			$string .= ";";
		}
		$string .= $self->biomassRemovals()->[$i]->id();
	}
	return $string;
}
sub _buildmediaSupplementString {
	my ($self) = @_;
	my $string = "";
	for (my $i=0; $i < @{$self->mediaSupplements()}; $i++) {
		if (length($string) > 0) {
			$string .= ";";
		}
		$string .= $self->mediaSupplements()->[$i]->id();
	}
	return $string;
}
sub _buildkoRestoreString {
	my ($self) = @_;
	my $string = "";
	for (my $i=0; $i < @{$self->koRestores()}; $i++) {
		if (length($string) > 0) {
			$string .= ";";
		}
		$string .= $self->koRestores()->[$i]->id();
	}
	return $string;
}

#***********************************************************************************************************
# CONSTANTS:
#***********************************************************************************************************

#***********************************************************************************************************
# FUNCTIONS:
#***********************************************************************************************************
=head3 printSolution

Definition:
	string printSolution();
Description:
	Prints solution in human readable format

=cut
sub printSolution {
	my ($self) = @_;
	my $rxns = $self->gapfillingSolutionReactions();
	my $output = "Solution cost:".$self->solutionCost()."\n";
	if (@{$rxns} > 0) {
		$output .= "Gapfilled reactions ".@{$rxns}."{\n";
		$output .= "ID\tDirection\tEquation\n";
		for (my $i=0; $i < @{$rxns}; $i++) {
			my $rxn = $rxns->[$i];
			$output .= $rxn->reaction()->id()."[c]\t".$rxn->direction()."\t".$rxn->reaction()->definition()."\n";
		}	
		$output .= "}\n";
	}
	if (@{$self->biomassRemoval_uuids()} > 0) {
		$output .= "Removed biomass compounds".@{$self->biomassRemovals()}."{\n";
		$output .= "ID\tName\tFormula\n";
		for (my $i=0; $i < @{$self->biomassRemovals()}; $i++) {
			my $cpd = $self->biomassRemovals()->[$i];
			$output .= $cpd->id()."\t".$cpd->name()."\t".$cpd->formula()."\n";
		}	
		$output .= "}\n";
	}
	if (@{$self->biomassRemoval_uuids()} > 0) {
		$output .= "Supplemented media compounds".@{$self->mediaSupplements()}."{\n";
		$output .= "ID\tName\tFormula\n";
		for (my $i=0; $i < @{$self->mediaSupplements()}; $i++) {
			my $cpd = $self->mediaSupplements()->[$i];
			$output .= $cpd->id()."\t".$cpd->name()."\t".$cpd->formula()."\n";
		}	
		$output .= "}\n";
	}
	return $output;
}

__PACKAGE__->meta->make_immutable;
1;
