########################################################################
# ModelSEED::MS::GapfillingFormulation - This is the moose object corresponding to the GapfillingFormulation object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-05-21T20:27:15
########################################################################
use strict;
use ModelSEED::MS::DB::GapfillingFormulation;
package ModelSEED::MS::GapfillingFormulation;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::DB::GapfillingFormulation';
#***********************************************************************************************************
# ADDITIONAL ATTRIBUTES:
#***********************************************************************************************************
has guaranteedReactionString => ( is => 'rw',printOrder => 16, isa => 'Str', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildguaranteedReactionString' );
has blacklistedReactionString => ( is => 'rw',printOrder => 17, isa => 'Str', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildblacklistedReactionString' );
has allowableCompartmentString => ( is => 'rw',printOrder => 18, isa => 'Str', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildallowableCompartmentString' );
has mediaID => ( is => 'rw',printOrder => 19, isa => 'Str', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildmediaID' );
has reactionKOString => ( is => 'rw',printOrder => 19, isa => 'Str', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildreactionKOString' );
has geneKOString => ( is => 'rw',printOrder => 19, isa => 'Str', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildgeneKOString' );

#***********************************************************************************************************
# BUILDERS:
#***********************************************************************************************************
sub _buildguaranteedReactionString {
	my ($self) = @_;
	my $string = "";
	for (my $i=0; $i < @{$self->guaranteedReactions()}; $i++) {
		if (length($string) > 0) {
			$string .= ";";
		}
		$string .= $self->guaranteedReactions()->[$i]->id();
	}
	return $string;
}
sub _buildblacklistedReactionString {
	my ($self) = @_;
	my $string = "";
	for (my $i=0; $i < @{$self->blacklistedReactions()}; $i++) {
		if (length($string) > 0) {
			$string .= ";";
		}
		$string .= $self->blacklistedReactions()->[$i]->id();
	}
	return $string;
}
sub _buildallowableCompartmentString {
	my ($self) = @_;
	my $string = "";
	for (my $i=0; $i < @{$self->allowableCompartments()}; $i++) {
		if (length($string) > 0) {
			$string .= ";";
		}
		$string .= $self->allowableCompartments()->[$i]->id();
	}
	return $string;
}
sub _buildmediaID {
	my ($self) = @_;
	return $self->fbaFormulation()->media()->id();
}
sub _buildreactionKOString {
	my ($self) = @_;
	my $string = "";
	my $rxnkos = $self->fbaFormulation()->reactionKOs();
	for (my $i=0; $i < @{$rxnkos}; $i++) {
		if ($i > 0) {
			$string .= ", ";
		}
		$string .= $rxnkos->[$i]->id();
	}
	return $string;
}
sub _buildgeneKOString {
	my ($self) = @_;
	my $string = "";
	my $genekos = $self->fbaFormulation()->geneKOs();
	for (my $i=0; $i < @{$genekos}; $i++) {
		if ($i > 0) {
			$string .= ", ";
		}
		$string .= $genekos->[$i]->id();
	}
	return $string;
}

#***********************************************************************************************************
# CONSTANTS:
#***********************************************************************************************************

#***********************************************************************************************************
# FUNCTIONS:
#***********************************************************************************************************

=head3 biochemistry

Definition:
	ModelSEED::MS::Biochemistry = biochemistry();
Description:
	Returns biochemistry behind gapfilling object

=cut

sub biochemistry {
	my ($self) = @_;
	$self->model()->biochemistry();	
}

=head3 annotation

Definition:
	ModelSEED::MS::Annotation = annotation();
Description:
	Returns annotation behind gapfilling object

=cut

sub annotation {
	my ($self) = @_;
	$self->model()->annotation();	
}

=head3 mapping

Definition:
	ModelSEED::MS::Mapping = mapping();
Description:
	Returns mapping behind gapfilling object

=cut

sub mapping {
	my ($self) = @_;
	$self->model()->mapping();	
}

=head3 calculateReactionCosts

Definition:
	ModelSEED::MS::GapfillingSolution = ModelSEED::MS::GapfillingFormulation->calculateReactionCosts({
		modelreaction => ModelSEED::MS::ModelReaction
	});
Description:
	Calculates the cost of adding or adjusting the reaction directionality in the model

=cut

sub calculateReactionCosts {
	my ($self,$args) = @_;
	$args = ModelSEED::utilities::ARGS($args,["modelreaction"],{});
	my $rxn = $args->{modelreaction};
	my $rcosts = 1;
	my $fcosts = 1;
	if (@{$rxn->modelReactionProteins()} > 0 && $rxn->modelReactionProteins()->[0]->note() ne "CANDIDATE") {
		if ($rxn->direction() eq ">" || $rxn->direction() eq "=") {
			$fcosts = 0;	
		}
		if ($rxn->direction() eq "<" || $rxn->direction() eq "=") {
			$rcosts = 0;
		}
	}
	if ($fcosts == 0 && $rcosts == 0) {
		return {forwardDirection => $fcosts,reverseDirection => $rcosts};
	}
	#Handling directionality multiplier
	if ($rxn->direction() eq ">") {
		$rcosts = $rcosts*$self->directionalityMultiplier();
		if ($rxn->reaction()->deltaG() ne 10000000) {
			$rcosts = $rcosts*(1-$self->deltaGMultiplier()*$rxn->reaction()->deltaG());
		}
	} elsif ($rxn->direction() eq "<") {
		$fcosts = $fcosts*$self->directionalityMultiplier();
		if ($rxn->reaction()->deltaG() ne 10000000) {
			$fcosts = $fcosts*(1+$self->deltaGMultiplier()*$rxn->reaction()->deltaG());
		}
	}
	#Checking for structure
	if (!defined($rxn->reaction()->deltaG()) || $rxn->reaction()->deltaG() eq 10000000) {
		$rcosts = $rcosts*$self->noDeltaGMultiplier();
		$fcosts = $fcosts*$self->noDeltaGMultiplier();
	}
	#Checking for transport based penalties
	if ($rxn->isTransporter() == 1) {
		$rcosts = $rcosts*$self->transporterMultiplier();
		$fcosts = $fcosts*$self->transporterMultiplier();
		if ($rxn->biomassTransporter() == 1) {
			$rcosts = $rcosts*$self->biomassTransporterMultiplier();
			$fcosts = $fcosts*$self->biomassTransporterMultiplier();
		}
		if (@{$rxn->modelReactionReagents()} <= 2) {
			$rcosts = $rcosts*$self->singleTransporterMultiplier();
			$fcosts = $fcosts*$self->singleTransporterMultiplier();
		}
	}
	#Checking for structure based penalties
	if ($rxn->missingStructure() == 1) {
		$rcosts = $rcosts*$self->noStructureMultiplier();
		$fcosts = $fcosts*$self->noStructureMultiplier();
	}		
	#Handling reactionset multipliers
	for (my $i=0; $i < @{$self->reactionSetMultipliers()}; $i++) {
		my $setMult = $self->reactionSetMultipliers()->[$i];
		my $set = $setMult->reactionset();
		if ($set->containsReaction($rxn->reaction()) == 1) {
			if ($setMult->multiplierType() eq "absolute") {
				$rcosts = $rcosts*$setMult->multiplier();
				$fcosts = $fcosts*$setMult->multiplier();
			} else {
				my $coverage = $set->modelCoverage({model=>$rxn->parent()});
				my $multiplier = $setMult->multiplier()/$coverage;
			}	
		}
	}
	return {forwardDirection => $fcosts,reverseDirection => $rcosts};
}

=head3 prepareFBAFormulation

Definition:
	void prepareFBAFormulation();
Description:
	Ensures that an FBA formulation exists for the gapfilling, and that it is properly configured for gapfilling

=cut

sub prepareFBAFormulation {
	my ($self,$args) = @_;
	my $form;
	if (!defined($self->fbaFormulation_uuid())) {
		my $exFact = ModelSEED::MS::Factories::ExchangeFormatFactory->new();
		$form = $exFact->buildFBAFormulation({model => $self->model(),overrides => {
			media => "Media/name/Complete",
			notes => "Default gapfilling FBA formulation",
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
		$self->fbaFormulation($form);
		$self->fbaFormulation_uuid($form->uuid());
	} else {
		$form = $self->fbaFormulation();
	}
	if ($form->media()->name() eq "Complete") {
		if ($form->defaultMaxDrainFlux() < 10000) {
			$form->defaultMaxDrainFlux(10000);
		}	
	} else {
		my $mediacpds = $form->media()->mediacompounds();
		foreach my $cpd (@{$mediacpds}) {
			if ($cpd->maxFlux() > 0) {
				$cpd->maxFlux(10000);
			}
			if ($cpd->minFlux() < 0) {
				$cpd->minFlux(-10000);
			}
		}
	}
	$form->objectiveConstraintFraction(1);
	$form->defaultMaxFlux(10000);
	$form->defaultMinDrainFlux(-10000);
	$form->fluxUseVariables(1);
	$form->decomposeReversibleFlux(1);
	#Setting up dissapproved compartments
	my $badCompList = [];
	my $approvedHash = {};
	my $cmps = $self->allowableCompartments();
	for (my $i=0; $i < @{$cmps}; $i++) {
		$approvedHash->{$cmps->[$i]->id()} = 1;	
	}
	$cmps = $self->biochemistry()->compartments();
	for (my $i=0; $i < @{$cmps}; $i++) {
		if (!defined($approvedHash->{$cmps->[$i]->id()})) {
			push(@{$badCompList},$cmps->[$i]->id());
		}	
	}
	$form->parameters()->{"dissapproved compartments"} = join(";",@{$badCompList});
	#Adding blacklisted reactions to KO list
	my $rxnhash = {};
	my $rxns = $self->guaranteedReactions();
	for (my $i=0; $i < @{$rxns}; $i++) {
		$rxnhash->{$rxns->[$i]->id()} = 1;	
	}
	$rxns = $form->reactionKOs();
	for (my $i=0; $i < @{$rxns}; $i++) {
		if (!defined($rxnhash->{$rxns->[$i]->id()})) {
			push(@{$form->reactionKOs()},$rxns->[$i]);
			push(@{$form->reactionKO_uuids()},$rxns->[$i]->uuid());
			$rxnhash->{$rxns->[$i]->id()} = 1;
		}	
	}
	#Setting up gauranteed reactions
	my $rxnlist = [];
	$rxns = $self->guaranteedReactions();
	for (my $i=0; $i < @{$rxns}; $i++) {
		push(@{$rxnlist},$rxns->[$i]->id());	
	}
	$form->parameters()->{"Allowable unbalanced reactions"} = join(",",@{$rxnlist});
	#Setting other important parameters
	$form->parameters()->{"Complete gap filling"} = 1;
	$form->parameters()->{"Reaction activation bonus"} = $self->reactionActivationBonus();
	$form->parameters()->{"Minimum flux for use variable positive constraint"} = 10;
	$form->parameters()->{"Objective coefficient file"} = "NONE";
	$form->parameters()->{"just print LP file"} = "0";
	$form->parameters()->{"use database fields"} = "1";
	$form->parameters()->{"REVERSE_USE;FORWARD_USE;REACTION_USE"} = "1";
	$form->parameters()->{"CPLEX solver time limit"} = "82800";
	$form->parameters()->{"Perform gap filling"} = "1";
	$form->parameters()->{"Add DB reactions for gapfilling"} = "1";
	$form->parameters()->{"Balanced reactions in gap filling only"} = $self->balancedReactionsOnly();
	$form->parameters()->{"drain flux penalty"} = $self->drainFluxMultiplier();#Penalty doesn't exist in MFAToolkit yet
	$form->parameters()->{"directionality penalty"} = $self->directionalityMultiplier();#5
	$form->parameters()->{"delta G multiplier"} = $self->deltaGMultiplier();#Penalty doesn't exist in MFAToolkit yet
	$form->parameters()->{"unknown structure penalty"} = $self->noStructureMultiplier();#1
	$form->parameters()->{"no delta G penalty"} = $self->noDeltaGMultiplier();#1
	$form->parameters()->{"biomass transporter penalty"} = $self->biomassTransporterMultiplier();#3
	$form->parameters()->{"single compound transporter penalty"} = $self->singleTransporterMultiplier();#3
	$form->parameters()->{"transporter penalty"} = $self->transporterMultiplier();#0
	$form->parameters()->{"unbalanced penalty"} = 10;
	$form->parameters()->{"no functional role penalty"} = 2;
	$form->parameters()->{"no KEGG map penalty"} = 1;
	$form->parameters()->{"non KEGG reaction penalty"} = 1;
	$form->parameters()->{"no subsystem penalty"} = 1;
	$form->parameters()->{"subsystem coverage bonus"} = 1;
	$form->parameters()->{"scenario coverage bonus"} = 1;
	$form->parameters()->{"Add positive use variable constraints"} = 0;
	$form->parameters()->{"Biomass modification hypothesis"} = 0;
	$form->parameters()->{"Biomass component reaction penalty"} = 500;
	$form->inputfiles()->{"InactiveModelReactions.txt"} = [];
	my $objterms = $form->fbaObjectiveTerms();
	for (my $i=0; $i < @{$objterms}; $i++) {
		my $term = $objterms->[$i];
		if ($term->entityType() eq "Reaction" || $term->entityType() eq "Biomass") {
			(my $obj) = $self->interpretReference($term->entityType()."/uuid/".$term->entity_uuid());
			if (defined($obj)) {
				push(@{$form->inputfiles()->{"InactiveModelReactions.txt"}},$obj->id());
			}
		}
	}
	push(@{$form->outputfiles}, "CompleteGapfillingOutput.txt");
	if ($self->biomassHypothesis() == 1) {
		$form->parameters()->{"Biomass modification hypothesis"} = 1;
		$self->printBiomassComponentReactions();
	}
	if ($self->mediaHypothesis() == 1) {
		
	}
	if ($self->gprHypothesis() == 1) {
		
	}
	return $form;	
}

=head3 printBiomassComponentReactions

Definition:
	void ModelSEED::MS::GapfillingFormulation->printBiomassComponentReactions();
Description:
	Print biomass component reactions designed to simulate removal of biomass components from the model

=cut

sub printBiomassComponentReactions {
	my ($self,$args) = @_;
	my $form = $self->fbaFormulation();
	my $filename = $form->jobDirectory()."/BiomassHypothesisEquations.txt";
	my $output = ["id\tequation\tname"];
	my $bio = $self->model()->biomasses()->[0];
	my $biocpds = $bio->biomasscompounds();
	my $cpdsWithProducts = {
		cpd11493 => ["cpd12370"],
		cpd15665 => ["cpd15666"],
		cpd15667 => ["cpd15666"],
		cpd15668 => ["cpd15666"],
		cpd15669 => ["cpd15666"],
		cpd00166 => ["cpd01997","cpd03422"],
	};
	foreach my $cpd (@{$biocpds}) {
		if ($cpd->coefficient() < 0) {
			my $equation = "=> ".$cpd->modelcompound()->compound()->id()."[b]";
			if (defined($cpdsWithProducts->{$cpd->modelcompound()->compound()->id()})) {
				$equation = join("[b] + ",@{$cpdsWithProducts->{$cpd->modelcompound()->compound()->id()}})."[b] ".$equation;
			}
			push(@{$output},$cpd->modelcompound()->compound()->id()."DrnRxn\t".$equation."\t".$cpd->modelcompound()->compound()->id()."DrnRxn");
		}
	}
	ModelSEED::utilities::PRINTFILE($filename,$output);	
}

=head3 runGapFilling

Definition:
	ModelSEED::MS::GapfillingSolution = ModelSEED::MS::GapfillingFormulation->runGapFilling({
		model => ModelSEED::MS::Model(REQ)
	});
Description:
	Identifies the solution that gapfills the input model

=cut

sub runGapFilling {
	my ($self,$args) = @_;
	#Preparing fba formulation describing gapfilling problem
	my $form = $self->prepareFBAFormulation();	
	#Running the gapfilling
	my $fbaResults = $form->runFBA();
	#Parsing solutions
	$self->parseGapfillingResults($fbaResults);
	return $self;
}

=head3 parseGapfillingResults

Definition:
	void parseGapfillingResults();
Description:
	Parses Gapfilling results

=cut

sub parseGapfillingResults {
	my ($self,$fbaResults) = @_;
	my $outputHash = $fbaResults->outputfiles();
	if (defined($outputHash->{"CompleteGapfillingOutput.txt"})) {
		my $filedata = $outputHash->{"CompleteGapfillingOutput.txt"};
		$self->createSolutionsFromArray({
			data => $filedata
		});
	}
}

=head3 createSolutionsFromArray

Definition:
	void createSolutionsFromArray({
		data => [string]:gapfilling solution data,
		model => ModelSEED::MS::Model:gapfilled model
	});
Description:
	Parsing input data to generate gapfilling solutions

=cut

sub createSolutionsFromArray {
	my ($self,$args) = @_;
	$args = ModelSEED::utilities::ARGS($args,["data"],{
		model => $self->model()
	});
	my $data = $args->{data};
	my $mdl = $args->{model};
	my $bio = $mdl->biochemistry();
	my $count = 0;
	my $rxnHash;
	for (my $i=0; $i < @{$data}; $i++) {
		if ($data->[$i] =~ m/^bio00001/) {
			my $gfsolution = $self->add("gapfillingSolutions",{});
			my $array = [split(/\t/,$data->[$i])];
			if (defined($array->[1])) {
				my $subarray = [split(/;/,$array->[1])];
				for (my $j=0; $j < @{$subarray}; $j++) {
					if ($subarray->[$j] =~ m/([\+])(.+)DrnRxn/) {
						my $cpdid = $2;
						my $sign = $1;
						my $bio = $mdl->biomasses()->[0];
						my $biocpds = $bio->biomasscompounds();
						my $found = 0;
						for (my $i=0; $i < @{$biocpds}; $i++) {
							my $biocpd = $biocpds->[$i];
							if ($biocpd->modelcompound()->compound()->id() eq $cpdid) {
								$bio->remove("biomasscompounds",$biocpd);
								$found = 1;
								push(@{$self->biomassRemovals()},$biocpd->modelcompound());
								push(@{$self->biomassRemoval_uuids()},$biocpd->modelcompound()->uuid());	
							}
						}
						if ($found == 0) {
							ModelSEED::utilities::ERROR("Could not find compound to remove from biomass ".$cpdid."!");
						}
						$count += 5;
					} elsif ($subarray->[$j] =~ m/([\-\+])(.+)/) {
						my $comp = "c";
						my $rxnid = $2;
						my $sign = $1;
						if ($sign eq "+") {
							$sign = ">";
						} else {
							$sign = "<";
						}
						my $rxn = $mdl->biochemistry()->queryObject("reactions",{id => $rxnid});
						if (!defined($rxn)) {
							ModelSEED::utilities::ERROR("Could not find gapfilled reaction ".$rxnid."!");
						}
						my $cmp = $mdl->biochemistry()->queryObject("compartments",{id => $comp});
						if (!defined($rxn)) {
							ModelSEED::utilities::ERROR("Could not find gapfilled reaction compartment ".$comp."!");
						}
						if (defined($rxnHash->{$rxn->uuid()}->{$cmp->uuid()}) && $rxnHash->{$rxn->uuid()}->{$cmp->uuid()} ne $sign) {
							$rxnHash->{$rxn->uuid()}->{$cmp->uuid()} = "=";
						} else {
							$rxnHash->{$rxn->uuid()}->{$cmp->uuid()} = $sign;
						}
						$count++;
					}
				}
			}
			$gfsolution->solutionCost($count);
			foreach my $ruuid (keys(%{$rxnHash})) {
				foreach my $cuuid (keys(%{$rxnHash->{$ruuid}})) {
					$gfsolution->add("gapfillingSolutionReactions",{
						reaction_uuid => $ruuid,
						compartment_uuid => $cuuid,
						direction => $rxnHash->{$ruuid}->{$cuuid}
					});
				}
			}
		}
	}
}

sub parseGeneCandidates {
	my ($self,$args) = @_;
	$args = ModelSEED::utilities::ARGS($args,["geneCandidates"],{});
	for (my $i=0; $i < @{$args->{geneCandidates}};$i++) {
		my $candidate = $args->{geneCandidates}->[$i];
		my $ftr = $self->interpretReference($candidate->{feature},"Feature");
		if (defined($ftr)) {
			(my $role,my $type,my $field,my $id) = $self->interpretReference($candidate->{role},"Role");
			if (!defined($role)) {
				$role = $self->mapping->add("roles",{
					name => $id,
					source => "GeneCandidates"
				});
			}
			(my $orthoGenome,$type,$field,$id) = $self->interpretReference($candidate->{orthologGenome},"Genome");
			if (!defined($orthoGenome)) {
				$orthoGenome = $self->annotation->add("genomes",{
					id => $id,
					name => $id,
					source => "GeneCandidates"
				});
			}
			(my $ortho,$type,$field,$id) = $self->interpretReference($candidate->{ortholog},"Feature");
			if (!defined($ortho)) {
				$ortho = $self->annotation->add("features",{
					id => $id,
					genome_uuid => $orthoGenome->uuid(),
				});
				$ortho->add("featureroles",{
					role_uuid => $role->uuid(),
				});
			}
			$self->add("gapfillingGeneCandidates",{
				feature_uuid => $ftr->uuid(),
				ortholog_uuid => $ortho->uuid(),
				orthologGenome_uuid => $orthoGenome->uuid(),
				similarityScore => $candidate->{similarityScore},
				distanceScore => $candidate->{distanceScore},
				role_uuid => $role->uuid()
			});
		}
	}
}

sub parseSetMultipliers {
	my ($self,$args) = @_;
	$args = ModelSEED::utilities::ARGS($args,["sets"],{});
	for (my $i=0; $i < @{$args->{sets}};$i++) {
		my $set = $args->{sets}->[$i];
		my $obj = $self->interpretReference($set->{set},"Reactionset");
		if (defined($obj)) {
			$self->add("reactionSetMultipliers",{
				reactionset_uuid => $obj->uuid(),
				reactionsetType => $set->{reactionsetType},
				multiplierType => $set->{multiplierType},
				description => $set->{description},
				multiplier => $set->{multiplier}
			});
		}
	}
}

sub parseGuaranteedReactions {
	my ($self,$args) = @_;
	$args->{data} = "uuid";
	$args->{class} = "Reaction";
	$self->guaranteedReaction_uuids($self->parseReferenceList($args));
}

sub parseBlacklistedReactions {
	my ($self,$args) = @_;
	$args->{data} = "uuid";
	$args->{class} = "Reaction";
	$self->blacklistedReaction_uuids($self->parseReferenceList($args));
}

sub parseAllowableCompartments {
	my ($self,$args) = @_;
	$args->{data} = "uuid";
	$args->{class} = "Compartment";
	$self->allowableCompartment_uuids($self->parseReferenceList($args));
}

=head3 printStudy

Definition:
	string printStudy();
Description:
	Prints study data and solutions in human readable format

=cut

sub printStudy {
	my ($self,$index) = @_;
	my $solutions = $self->gapfillingSolutions();
	my $numSolutions = @{$solutions};
	my $output = "*********************************************\n";
	$output .= "Gapfilling formulation: GF".$index."\n";
	$output .= "Media: ".$self->mediaID()."\n";
	if ($self->geneKOString() ne "") {
		$output .= "GeneKO: ".$self->geneKOString()."\n";
	}
	if ($self->reactionKOString() ne "") {
		$output .= "ReactionKO: ".$self->reactionKOString()."\n";
	}
	$output .= "---------------------------------------------\n";
	if ($numSolutions == 0) {
		$output .= "No gapfilling solutions found!\n";
		$output .= "---------------------------------------------\n";
	} else {
		$output .= $numSolutions." gapfilling solution(s) found.\n";
		$output .= "---------------------------------------------\n";
	}
	for (my $i=0; $i < @{$solutions}; $i++) {
		$output .= "New gapfilling solution: GF".$index.".".$i."\n";
		$output .= $solutions->[$i]->printSolution();
		$output .= "---------------------------------------------\n";
	}
	return $output;
}

__PACKAGE__->meta->make_immutable;
1;
