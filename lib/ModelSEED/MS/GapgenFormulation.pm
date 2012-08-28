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
	$form->parameters()->{"Gap generation media"} = $self->referenceMedia()->name();
	if ($self->referenceMedia()->name() ne $form->media()->name()) {
		push(@{$form->secondaryMedia_uuids()},$self->referenceMedia()->uuid());
		push(@{$form->secondaryMedia()},$self->referenceMedia());
	}
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
	if (!-e $directory."/ProblemReport.txt") {
		print STDERR "Gapgeneration failed!";
		return;
	}
	my $tbl = ModelSEED::utilities::LOADTABLE($directory."/ProblemReport.txt",";");
	my $column;
	for (my $i=0; $i < @{$tbl->{headings}}; $i++) {
		if ($tbl->{headings}->[$i] eq "Notes") {
			$column = $i;
			last;
		}
	}
	if (defined($column)) {
		for (my $j=0; $j < @{$tbl->{data}}; $j++) {
			my $row = $tbl->{data}->[$j];
			if ($row->[$column] =~ m/^Recursive\sMILP\s([^)]+)/) {
				my @SolutionList = split(/\|/,$1);
				for (my $k=0; $k < @SolutionList; $k++) {
					if ($SolutionList[$k] =~ m/(\d+):(.+)/) {
						my $ggsolution = $self->add("gapgenSolutions",{
							solutionCost => $1,
						});
						my $rxns = [split(/,/,$2)];
						for (my $m=0; $m < @{$rxns}; $m++) {
							if ($subarray->[$j] =~ m/([\-\+])(rxn\d\d\d\d\d)/) {
								my $rxnid = $2;
								my $sign = $1;
								my $rxn = $model->biochemistry()->queryObject("reactions",{id => $rxnid});
								if (!defined($rxn)) {
									ModelSEED::utilities::ERROR("Could not find gapgen reaction ".$rxnid."!");
								}
								my $mdlrxn = $model->queryObject("modelreactions",{reaction_uuid => $rxn->uuid()});
								my $direction = ">";
								if ($sign eq "-") {
									$direction = "<";
								}
								$ggsolution->add("gapgenSolutionReactions",{
									modelreaction_uuid => $mdlrxn->uuid(),
									modelreaction => $mdlrxn,
									direction => $direction
								});
								if ($mdlrxn->direction() eq $direction) {
									$model->remove("modelreactions",$mdlrxn);
								} elsif ($direction eq ">") {
									$mdlrxn->direction("<");
								} elsif ($direction eq "<") {
									$mdlrxn->direction(">");
								}
							}
						}
					}
				}
			}
		}
	}
	return $ggsolution;
}

__PACKAGE__->meta->make_immutable;
1;
