########################################################################
# ModelSEED::MS::GapgenFormulation - This is the moose object corresponding to the GapgenFormulation object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-08-07T07:31:48
########################################################################
use strict;
use ModelSEED::MS::DB::GapgenFormulation;
package ModelSEED::MS::GapgenFormulation;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::DB::GapgenFormulation';
#***********************************************************************************************************
# ADDITIONAL ATTRIBUTES:
#***********************************************************************************************************


#***********************************************************************************************************
# BUILDERS:
#***********************************************************************************************************



#***********************************************************************************************************
# CONSTANTS:
#***********************************************************************************************************

#***********************************************************************************************************
# FUNCTIONS:
#***********************************************************************************************************
=head3 prepareFBAFormulation
Definition:
	void prepareFBAFormulation();
Description:
	Ensures that an FBA formulation exists for the gapgen, and that it is properly configured for gapgen
=cut
sub prepareFBAFormulation {
	my ($self,$args) = @_;
	my $form;
	if (!defined($self->fbaFormulation_uuid())) {
		my $exFact = ModelSEED::MS::Factories::ExchangeFormatFactory->new();
		$form = $exFact->buildFBAFormulation({model => $self->parent(),overrides => {
			media => "Media/name/Complete",
			notes => "Default gapgen FBA formulation",
			allReversible => 1,
			reactionKO => "none",
			numberOfSolutions => 1,
			maximizeObjective => 1,
			fbaObjectiveTerms => [{
				variableType => "biomassflux",
				id => "Biomass/id/bio00001",
				coefficient => 1
			}]
		}});
	} else {
		$form = $self->fbaFormulation();
	}
	if ($form->media()->name() eq "Complete") {
		if ($form->defaultMaxDrainFlux() < 100) {
			$form->defaultMaxDrainFlux(100);
		}	
	}
	$form->objectiveConstraintFraction(1);
	$form->defaultMaxFlux(100);
	$form->defaultMinDrainFlux(-100);
	$form->fluxUseVariables(1);
	$form->decomposeReversibleFlux(1);
	#Setting other important parameters
	$form->parameters()->{"Perform gap generation"} = 1;
	$form->parameters()->{"Gap generation media"} = "Carbon-D-Glucose";
	$form->parameters()->{"Minimum flux for use variable positive constraint"} = 10;
	$form->parameters()->{"Objective coefficient file"} = "NONE";
	$form->parameters()->{"just print LP file"} = "0";
	$form->parameters()->{"use database fields"} = "1";
	$form->parameters()->{"REVERSE_USE;FORWARD_USE;REACTION_USE"} = "1";
	$form->parameters()->{"CPLEX solver time limit"} = "82800";
	return $form;	
}

=head3 runGapGeneration
Definition:
	ModelSEED::MS::GapgenSolution = ModelSEED::MS::GapgenFormulation->runGapGeneration({
		model => ModelSEED::MS::Model(REQ)
	});
Description:
	Identifies the solution that disables growth in the specified conditions
=cut
sub runGapGeneration {
	my ($self,$args) = @_;
	#Preparing fba formulation describing gapfilling problem
	my $form = $self->prepareFBAFormulation();
	my $directory = $form->jobDirectory()."/";
	#Running the gapfilling
	my $fbaResults = $form->runFBA();
	#Parsing gapfilling results
	if (!-e $directory."GapfillingComplete.txt") {
		print STDERR "Gapfilling failed!";
		return undef;
	}
	my $filedata = ModelSEED::utilities::LOADFILE($directory."CompleteGapfillingOutput.txt");
	my $gfsolution = $self->add("gapfillingSolutions",{});
	my $count = 0;
	my $model = $self->parent();
	for (my $i=0; $i < @{$filedata}; $i++) {
		if ($filedata->[$i] =~ m/^bio00001/) {
			my $array = [split(/\t/,$filedata->[$i])];
			if (defined($array->[1])) {
				my $subarray = [split(/;/,$array->[1])];
				for (my $j=0; $j < @{$subarray}; $j++) {
					if ($subarray->[$j] =~ m/([\-\+])(rxn\d\d\d\d\d)/) {
						my $rxnid = $2;
						my $sign = $1;
						my $rxn = $model->biochemistry()->queryObject("reactions",{id => $rxnid});
						if (!defined($rxn)) {
							ModelSEED::utilities::ERROR("Could not find gapfilled reaction ".$rxnid."!");
						}
						my $mdlrxn = $model->queryObject("modelreactions",{reaction_uuid => $rxn->uuid()});
						my $direction = ">";
						if ($sign eq "-") {
							$direction = "<";
						}
						if ($rxn->direction() ne $direction) {
							$direction = "=";
						}
						if (defined($mdlrxn)) { 
							$mdlrxn->direction("=");
						} else {
							$mdlrxn = $model->addReactionToModel({
								reaction => $rxn,
								direction => $direction
							});
						}
						$count++;
						$gfsolution->add("gapfillingSolutionReactions",{
							modelreaction_uuid => $mdlrxn->uuid(),
							modelreaction => $mdlrxn,
							direction => $direction
						});
						
					}
				}
			}
			
		}
	}
	$gfsolution->solutionCost($count);
	return $gfsolution;
}

__PACKAGE__->meta->make_immutable;
1;
