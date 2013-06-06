########################################################################
# ModelSEED::MS::Model - This is the moose object corresponding to the Model object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-03-26T23:22:35
########################################################################
use strict;
use YAML::XS;
use XML::LibXML;
use ModelSEED::MS::DB::Model;
package ModelSEED::MS::Model;
use Moose;
use namespace::autoclean;
use Class::Autouse qw(
    Graph::Directed
);
use ModelSEED::utilities;
extends 'ModelSEED::MS::DB::Model';
#***********************************************************************************************************
# ADDITIONAL ATTRIBUTES:
#***********************************************************************************************************
has features => ( is => 'rw', isa => 'ArrayRef',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildfeatures' );

#***********************************************************************************************************
# BUILDERS:
#***********************************************************************************************************
sub _buildfeatures {
	my ($self) = @_;
	#Retrieving list of genes in model
	my $rxns = $self->modelreactions();
	my $ftrhash = {};
	for (my $i=0; $i < @{$rxns};$i++) {
		my $rxn = $rxns->[$i];
		my $ftrs = $rxn->featureUUIDs();
		foreach my $ftr (@{$ftrs}) {
			$ftrhash->{$ftr} = 1;
		}
	}
	return [keys(%{$ftrhash})];
}

#***********************************************************************************************************
# CONSTANTS:
#***********************************************************************************************************

#***********************************************************************************************************
# FUNCTIONS:
#***********************************************************************************************************

=head3 findCreateEquivalentCompartment

Definition:
	void ModelSEED::MS::Model->findCreateEquivalentCompartment({
		modelcompartment => ModelSEED::MS::ModelCompartment(REQ),
		create => 0/1(1)
	});
Description:
	Search for an equivalent comparment for the input model compartment

=cut

sub findCreateEquivalentCompartment {
	my $self = shift;
	my $args = ModelSEED::utilities::args(["modelcompartment"], {create => 1}, @_);
	my $mdlcmp = $args->{modelcompartment};
	my $cmp = $self->queryObject("modelcompartments",{
		label => $mdlcmp->label()
	});
	if (!defined($cmp) && $args->{create} == 1) {
		my $biocmp = $self->biochemistry()->findCreateEquivalentCompartment({
			compartment => $mdlcmp->compartment(),
			create => 1
		});
		$cmp = $self->addCompartmentToModel({
			compartment => $biocmp,
			pH => $mdlcmp->pH(),
			potential => $mdlcmp->potential(),
			compartmentIndex => $mdlcmp->compartmentIndex(),
		});
	}
	$mdlcmp->mapped_uuid($cmp->uuid());
	$cmp->mapped_uuid($mdlcmp->uuid());
	return $cmp;
}

=head3 findCreateEquivalentCompound

Definition:
	void ModelSEED::MS::Model->findCreateEquivalentCompound({
		modelcompound => ModelSEED::MS::ModelCompound(REQ),
		modelcompartment => ModelSEED::MS::ModelCompartment(REQ),
		create => 0/1(1)
	});
Description:
	Search for an equivalent compound for the input model compound

=cut

sub findCreateEquivalentCompound {
    my $self = shift;
	my $args = ModelSEED::utilities::args(["modelcompound"], {create => 1}, @_);
	my $inmdlcpd = $args->{modelcompound};
	my $outcpd = $self->queryObject("modelcompounds",{
		name => $inmdlcpd->name(),
		modelCompartmentLabel => $inmdlcpd->modelCompartmentLabel()
	});
	if (!defined($outcpd) && $args->{create} == 1) {
		my $mdlcmp = $self->findCreateEquivalentCompartment({
			modelcompartment => $inmdlcpd->modelcompartment(),
			create => 1
		});
		my $cpd = $self->biochemistry()->findCreateEquivalentCompound({
			compound => $inmdlcpd->compound(),
			create => 1
		});
		$outcpd = $self->addCompoundToModel({
			compound => $cpd,
			modelCompartment => $mdlcmp,
			charge => $inmdlcpd->charge(),
			formula => $inmdlcpd->formula()
		});
	}
	$inmdlcpd->mapped_uuid($outcpd->uuid());
	$outcpd->mapped_uuid($inmdlcpd->uuid());
	return $outcpd;
}

=head3 findCreateEquivalentReaction

Definition:
	void ModelSEED::MS::Model->findCreateEquivalentReaction({
		modelreaction => ModelSEED::MS::ModelReaction(REQ),
		create => 0/1(1)
	});
Description:
	Search for an equivalent reaction for the input model reaction

=cut

sub findCreateEquivalentReaction {
    my $self = shift;
    my $args = ModelSEED::utilities::args( ["modelreaction"], { create => 1 }, @_ );
	my $inmdlrxn = $args->{modelreaction};
	my $outrxn = $self->queryObject("modelreactions",{
		definition => $inmdlrxn->definition(),
	});
	if (!defined($outrxn) && $args->{create} == 1) {
		my $biorxn = $self->biochemistry()->findCreateEquivalentReaction({
			reaction => $inmdlrxn->reaction(),
			create => 1
		});
		my $mdlcmp = $self->findCreateEquivalentCompartment({
			modelcompartment => $inmdlrxn->modelcompartment()
		});
		$outrxn = $self->add("modelreactions",{
			reaction_uuid => $biorxn->uuid(),
			direction => $inmdlrxn->direction(),
			protons => $inmdlrxn->protons(),
			modelcompartment_uuid => $mdlcmp->uuid()
		});
		my $rgts = $inmdlrxn->modelReactionReagents();
		for (my $i=0; $i < @{$rgts}; $i++) {
			my $rgt = $rgts->[$i];
			my $mdlcpd = $self->findCreateEquivalentCompound({
				modelcompound => $rgt->modelcompound()
			});
			$outrxn->add("modelReactionReagents",{
				modelcompound_uuid => $mdlcpd->uuid(),
				coefficient => $rgt->coefficient()
			});
		}
		my $prots = $inmdlrxn->modelReactionProteins();
		for (my $i=0; $i < @{$prots}; $i++) {
			my $prot = $prots->[$i];
			$outrxn->add("modelReactionProteins",$prot->serializeToDB());
		}
	}
	$inmdlrxn->mapped_uuid($outrxn->uuid());
	$outrxn->mapped_uuid($inmdlrxn->uuid());
	return $outrxn;
}

=head3 findCreateEquivalentBiomass

Definition:
	void ModelSEED::MS::Model->findCreateEquivalentBiomass({
		biomass => ModelSEED::MS::Biomass(REQ),
		create => 0/1(1)
	});
Description:
	Search for an equivalent biomass for the input model biomass

=cut

sub findCreateEquivalentBiomass {
    my $self = shift;
    my $args = ModelSEED::utilities::args( ["biomass"], { create => 1 }, @_ );
	my $inmdlbio = $args->{biomass};
	my $outbio = $self->queryObject("biomasses",{
		definition => $inmdlbio->definition()
	});
	if (!defined($outbio) && $args->{create} == 1) {
		$outbio = $self->add("biomasses",{
			name => $inmdlbio->name(),
			dna => $inmdlbio->dna(),
			rna => $inmdlbio->rna(),
			protein => $inmdlbio->protein(),
			cellwall => $inmdlbio->cellwall(),
			lipid => $inmdlbio->lipid(),
			cofactor => $inmdlbio->cofactor(),
			energy => $inmdlbio->energy()
		});
		my $cpds = $inmdlbio->biomasscompounds();
		for (my $i=0; $i < @{$cpds}; $i++) {
			my $rgt = $cpds->[$i];
			my $mdlcpd = $self->findCreateEquivalentCompound({
				modelcompound => $rgt->modelcompound()
			});
			$outbio->add("biomasscompounds",{
				modelcompound_uuid => $mdlcpd->uuid(),
				coefficient => $rgt->coefficient()
			});
		}
	}
	$inmdlbio->mapped_uuid($outbio->uuid());
	$outbio->mapped_uuid($inmdlbio->uuid());
	return $outbio;
}

=head3 mergeModel

Definition:
	void ModelSEED::MS::Model->mergeModel({
		model => ModelSEED::MS::Model(REQ)
	});
Description:
	Merges in the input model with the current model, combining namespace and eliminating redundant compounds and reactions

=cut

sub mergeModel {
    my $self = shift;
    my $args = ModelSEED::utilities::args( ["model"], {}, @_ );
	my $mdl = $args->{model};
	my $cmps = $mdl->modelcompartments();
	for (my $i = 0; $i < @{$cmps}; $i++) {
		my $mdlcmp = $cmps->[$i];
		my $cmp = $self->findCreateEquivalentCompartment({modelcompartment => $mdlcmp,create => 1});
	}
	my $cpds = $mdl->modelcompounds();
	for (my $i = 0; $i < @{$cpds}; $i++) {
		my $mdlcpd = $cpds->[$i];
		my $cpd = $self->findCreateEquivalentCompound({modelcompound => $mdlcpd,create => 1});
	}
	my $rxns = $mdl->modelreactions();
	for (my $i = 0; $i < @{$rxns}; $i++) {
		my $mdlrxn = $rxns->[$i];
		my $rxn = $self->findCreateEquivalentReaction({modelreaction => $mdlrxn,create => 1});
	}
	my $bios = $mdl->biomasses();
	for (my $i = 0; $i < @{$bios}; $i++) {
		my $mdlbio = $bios->[$i];
		my $bio = $self->findCreateEquivalentBiomass({biomass => $mdlbio,create => 1});
	}
}

=head3 buildModelFromAnnotation
Definition:
	ModelSEED::MS::ModelReaction = ModelSEED::MS::Model->buildModelFromAnnotation({
		annotation => $self->annotation(),
		mapping => $self->mapping(),
	});
Description:
	Clears existing compounds, reactions, compartments, and biomass and rebuilds model from annotation

=cut

sub buildModelFromAnnotation {
    my $self = shift;
	my $args = ModelSEED::utilities::args([],{
		annotation => $self->annotation(),
		mapping => $self->mapping(),
		verbose => 0
					      }, @_);
	my $mapping = $args->{mapping};
	my $annotaton = $args->{annotation};
	my $biochem = $mapping->biochemistry();
	my $roleFeatures;
	my $features = $annotaton->features();
    warn "Processing " . scalar(@$features) . " features...\n" if($args->{verbose});
	for (my $i=0; $i < @{$features}; $i++) {
		my $ftr = $features->[$i];
		my $ftrroles = $ftr->featureroles();
		for (my $j=0; $j < @{$ftrroles}; $j++) {
			my $ftrrole = $ftrroles->[$j];
			push(@{$roleFeatures->{$ftrrole->role_uuid()}->{$ftrrole->compartment()}},$ftr);
		}
	}
    warn "Constructing reactions...\n" if($args->{verbose});
	my $complexes = $mapping->complexes();
	for (my $i=0; $i < @{$complexes};$i++) {
		my $cpx = $complexes->[$i];
		my $compartments;
		my $complexreactions = $cpx->reactions();
		my $complexroles = $cpx->complexroles();
		for (my $j=0; $j < @{$complexroles}; $j++) {
			my $cpxrole = $complexroles->[$j];
			if (defined($roleFeatures->{$cpxrole->role_uuid()})) {
				foreach my $compartment (keys(%{$roleFeatures->{$cpxrole->role_uuid()}})) {
					my $origcomp = $compartment;
					if ($compartment eq "u") {
						$compartment = "c";
					}
					if ($cpxrole->triggering() == 1) {
						$compartments->{$compartment}->{present} = 1;
					}
					$compartments->{$compartment}->{subunits}->{$cpxrole->role_uuid()}->{triggering} = $cpxrole->triggering();
					$compartments->{$compartment}->{subunits}->{$cpxrole->role_uuid()}->{optional} = $cpxrole->optional();
					foreach my $feature (@{$roleFeatures->{$cpxrole->role_uuid()}->{$origcomp}}) {
						$compartments->{$compartment}->{subunits}->{$cpxrole->role_uuid()}->{genes}->{$feature->uuid()} = $feature;	
					}
				}
			}
		}
		for (my $j=0; $j < @{$complexroles}; $j++) {
			my $cpxrole = $complexroles->[$j];
			if (!defined($roleFeatures->{$cpxrole->role_uuid()}) && $cpxrole->optional() == 0) {
				foreach my $cmp (keys(%{$compartments})) {
					if ($compartments->{$cmp}->{present} == 1) {
						$compartments->{$cmp}->{subunits}->{$cpxrole->role_uuid()}->{triggering} = $cpxrole->triggering();
						$compartments->{$cmp}->{subunits}->{$cpxrole->role_uuid()}->{optional} = $cpxrole->optional();
						$compartments->{$cmp}->{subunits}->{$cpxrole->role_uuid()}->{note} = "Complex-based-gapfilling";
					}
				}
			}
		}
		foreach my $cmp (keys(%{$compartments})) {
			if ($compartments->{$cmp}->{present} == 1) {
				for (my $j=0; $j < @{$complexreactions}; $j++) {
					my $cpxrxn = $complexreactions->[$j];
					my $override = undef;
					if ($cmp ne "c") {
						my $biocmp = $self->biochemistry()->queryObject("compartments",{id => $cmp});
						$override = $self->addCompartmentToModel({
							compartment => $biocmp
						});
					}
					my $mdlrxn = $self->addReactionToModel({
						reaction => $cpxrxn,
						direction => $cpxrxn->thermoReversibility(),
						overrideCompartment => $override
					});
					$mdlrxn->addModelReactionProtein({
						proteinDataTree => $compartments->{$cmp},
						complex_uuid => $cpx->uuid()
					});
				}
			}
		}
	}
	my $universalReactions = $mapping->universalReactions();
	foreach my $universalRxn (@{$universalReactions}) {
		my $mdlrxn = $self->addReactionToModel({
			reaction => $universalRxn->reaction(),
			direction => $universalRxn->reaction()->thermoReversibility()
		});
		$mdlrxn->addModelReactionProtein({
			proteinDataTree => {note => "Universal reaction"},
			complex_uuid => "00000000-0000-0000-0000-000000000000"
		});
	}
	my $bio = $self->createStandardFBABiomass({
		annotation => $self->annotation(),
		mapping => $self->mapping(),
		isplant => $args->{isplant},
	});
}

=head3 buildModelByLayers

Definition:
	void ModelSEED::MS::Model->buildModelByLayers({
		
	});
Description:
	
=cut

sub buildModelByLayers {
	my ($self,$args) = @_;
	my $bios = $self->biomasses();
	for (my $i=0; $i <@{$bios};$i++) {
		my $bio = $bios->[$i];
		print $bio->name();
	}
}

=head3 createStandardFBABiomass
Definition:
	ModelSEED::MS::Biomass = ModelSEED::MS::Annotation->createStandardFBABiomass({
		mapping => $self->mapping()
	});
Description:
	Creates a new biomass based on the annotation

=cut

sub createStandardFBABiomass {
    my $self = shift;
    my $args = ModelSEED::utilities::args([], {
		annotation => $self->annotation(),
		mapping => $self->mapping(),
		isplant => 0,
	}, @_);
	my $anno = $args->{annotation};
	my $mapping = $args->{mapping};
	my $biochem = $mapping->biochemistry();
	my $count = @{$self->biomasses()};
	my $bio = $self->add("biomasses",{
		name => $self->name()." auto biomass",
		id => "bio".($count+1)
	});
	my $phylum = "";
    if(!$args->{isplant}){
	$phylum=$anno->classifyGenomeFromAnnotation();
    }else{
	$phylum = "Plant";
    }

    my @templates=@{$mapping->biomassTemplates()};
	my $template = $mapping->queryObject("biomassTemplates",{class => $phylum});
	if (!defined($template)) {
		print "Could not find biomass template for type:".$phylum."\n";
		$template = $mapping->queryObject("biomassTemplates",{class => "Unknown"});
	}
	my $list = ["dna","rna","protein","lipid","cellwall","cofactor","energy"];
	for (my $i=0; $i < @{$list}; $i++) {
		my $function = $list->[$i];
		$bio->$function($template->$function());
	}
	$bio->energy(40);

	my $biomassComps;
	my $biomassCompByUUID;
	my $biomassTemplateComponents = $template->biomassTemplateComponents();
	my $coef;
	my $cpdHash;
	for (my $i=0; $i < @{$biomassTemplateComponents}; $i++) {
		my $tmpComp = $biomassTemplateComponents->[$i];
		$biomassCompByUUID->{$tmpComp->uuid()} = $tmpComp;
		if ($self->testBiomassCondition({
				condition => $tmpComp->condition(),
				annotation => $args->{annotation}
			}) == 1) {
			$biomassComps->{$tmpComp->class()}->{$tmpComp->uuid()} = $tmpComp->coefficient();
			$cpdHash->{$tmpComp->compound_uuid()} = $tmpComp->compound();
			$coef->{$tmpComp->compound_uuid()} = 0;
		}
	}
	my $gc = $anno->genomes()->[0]->gc();
	if ($gc > 1) {
		$gc = 0.01*$gc;	
	}

	#Setting fractions to appropriate levels
	foreach my $class (keys(%{$biomassComps})) {
		my $fractionTotal = 0;
		foreach my $templateCompUUID (keys(%{$biomassComps->{$class}})) {
			my $templateComp = $biomassCompByUUID->{$templateCompUUID};
			if ($templateComp->coefficientType() eq "FRACTION") {
				$fractionTotal++;
			}
		}
		my $totalMass = 0;
		foreach my $templateCompUUID (keys(%{$biomassComps->{$class}})) {
			my $templateComp = $biomassCompByUUID->{$templateCompUUID};
			if ($templateComp->coefficientType() eq "FRACTION") {
				$biomassComps->{$class}->{$templateCompUUID} = -1/$fractionTotal;
			} elsif ($class eq "dna") {
				if ($templateComp->compound()->id() eq "cpd00241" || $templateComp->compound()->id() eq "cpd00356") {
					$biomassComps->{$class}->{$templateCompUUID} = -1*$gc/2;
				} else {
					$biomassComps->{$class}->{$templateCompUUID} = -1*(1-$gc)/2;
				}
			}
			if ($class ne "energy" && $class ne "macromolecule") {
				my $mass = 0.001*$templateComp->compound()->mass();
				if (!defined($mass) || $mass == 0) {
					$mass = 0.001;
				}
				if ($biomassComps->{$class}->{$templateCompUUID} < 0) {
					$totalMass += -1*$mass*$biomassComps->{$class}->{$templateCompUUID};
				}
			}
		}
		if ($totalMass == 0) {
			$totalMass = 1;	
		}
		foreach my $templateCompUUID (keys(%{$biomassComps->{$class}})) {
			my $templateComp = $biomassCompByUUID->{$templateCompUUID};
			if ($class eq "energy") {
				$biomassComps->{$class}->{$templateCompUUID} = $biomassComps->{$class}->{$templateCompUUID}*$bio->energy();
			} elsif ($class ne "macromolecule") {
				$biomassComps->{$class}->{$templateCompUUID} = $biomassComps->{$class}->{$templateCompUUID}*$bio->$class()/$totalMass;
			}
			$coef->{$templateComp->compound_uuid()} += $biomassComps->{$class}->{$templateCompUUID};
		}
	}

	#Setting coefficients for dependant biomass components
	foreach my $class (keys(%{$biomassComps})) {
		foreach my $templateCompUUID (keys(%{$biomassComps->{$class}})) {
			my $templateComp = $biomassCompByUUID->{$templateCompUUID};
			if ($templateComp->coefficientType() ne "FRACTION" && $templateComp->coefficientType() ne "NUMBER") {
				my $array = [split(/,/,$templateComp->coefficientType())];
				$biomassComps->{$class}->{$templateCompUUID} = 0;
				for (my $i=0; $i < @{$array}; $i++) {
					if (defined($coef->{$array->[$i]})) {
						$biomassComps->{$class}->{$templateCompUUID} += -1*($coef->{$array->[$i]});
					}
				}
				$coef->{$templateComp->compound_uuid()} = $biomassComps->{$class}->{$templateCompUUID};
			}
		}
	}

	#Setting biomass components
	foreach my $cpd_uuid (keys(%{$coef})) {
		my $cmp = $biochem->queryObject("compartments",{id => "c"});
		my $mdlcmp = $self->addCompartmentToModel({compartment => $cmp,pH => 7,potential => 0,compartmentIndex => 0});
		my $mdlcpd = $self->addCompoundToModel({
			compound => $cpdHash->{$cpd_uuid},
			modelCompartment => $mdlcmp,
		});
		if ($coef->{$cpd_uuid} != 0) {
			$bio->add("biomasscompounds",{
				modelcompound_uuid => $mdlcpd->uuid(),
				coefficient => $coef->{$cpd_uuid}
			});
		}
	}
	return $bio;
}

=head3 testBiomassCondition

Definition:
	ModelSEED::MS::Model = ModelSEED::MS::Model->testBiomassCondition({
		condition => REQUIRED,
		annotation => $self->annotation()
	});
Description:
	Tests if the organism satisfies the conditions for inclusion of the compound in the model biomass reaction

=cut

sub testBiomassCondition {
    my $self = shift;
    my $args = ModelSEED::utilities::args(["condition"],{ annotation => $self->annotation() }, @_);
	if ($args->{condition} ne "UNIVERSAL") {
		my $Class = $args->{annotation}->genomes()->[0]->class();
		my $Name = $args->{annotation}->genomes()->[0]->name();
		my $RoleHash;
		my $features = $args->{annotation}->features();
		for (my $i=0; $i < @{$features}; $i++) {
			my $ftr = $features->[$i];
			my $featureroles = $ftr->featureroles();
			for (my $j=0; $j < @{$featureroles}; $j++) {
				$RoleHash->{$featureroles->[$j]->role()->name()} = 1;
			}
		}
		my $VariantHash;
		my $subsystemStates = $args->{annotation}->subsystemStates();
		for (my $i=0; $i < @{$subsystemStates}; $i++) {
			$VariantHash->{$subsystemStates->[$i]->name()} = $subsystemStates->[$i]->variant();
		}
		my $Criteria = $args->{condition};
		my $End = 0;
		while ($End == 0) {
			if ($Criteria =~ m/^(.+)(AND)\{([^{^}]+)\}(.+)$/ || $Criteria =~ m/^(AND)\{([^{^}]+)\}$/ || $Criteria =~ m/^(.+)(OR)\{([^{^}]+)\}(.+)$/ || $Criteria =~ m/^(OR)\{([^{^}]+)\}$/) {
				my $Start = "";
				my $End = "";
				my $Condition = $1;
				my $Data = $2;
				if ($1 ne "AND" && $1 ne "OR") {
					$Start = $1;
					$End = $4;
					$Condition = $2;
					$Data = $3;
				}
				my $Result = "YES";
				if ($Condition eq "OR") {
					$Result = "NO";
				}
				my @Array = split(/\|/,$Data);
				for (my $j=0; $j < @Array; $j++) {
					if ($Array[$j] eq "YES" && $Condition eq "OR") {
						$Result = "YES";
						last;
					} elsif ($Array[$j] eq "NO" && $Condition eq "AND") {
						$Result = "NO";
						last;
					} elsif ($Array[$j] =~ m/^COMPOUND:(.+)/) {
						$Result = "YES";
						last;
					} elsif ($Array[$j] =~ m/^NAME:(.+)/) {
						my $Comparison = $1;
						if ((!defined($Comparison) || !defined($Name) || $Name =~ m/$Comparison/) && $Condition eq "OR") {
							$Result = "YES";
							last;
						} elsif (defined($Comparison) && defined($Name) && $Name !~ m/$Comparison/ && $Condition eq "AND") {
							$Result = "NO";
							last;
						}
					} elsif ($Array[$j] =~ m/^!NAME:(.+)/) {
						my $Comparison = $1;
						if ((!defined($Comparison) || !defined($Name) || $Name !~ m/$Comparison/) && $Condition eq "OR") {
							$Result = "YES";
							last;
						} elsif (defined($Comparison) && defined($Name) && $Name =~ m/$Comparison/ && $Condition eq "AND") {
							$Result = "NO";
							last;
						}
					} elsif ($Array[$j] =~ m/^SUBSYSTEM:(.+)/) {
						my @SubsystemArray = split(/`/,$1);
						if (defined($VariantHash->{$SubsystemArray[0]}) && $VariantHash->{$SubsystemArray[0]} ne -1 && $Condition eq "OR") {
							$Result = "YES";
							last;
						} elsif ((!defined($VariantHash->{$SubsystemArray[0]}) || $VariantHash->{$SubsystemArray[0]} eq -1) && $Condition eq "AND") {
							$Result = "NO";
							last;
						}
					} elsif ($Array[$j] =~ m/^!SUBSYSTEM:(.+)/) {
						my @SubsystemArray = split(/`/,$1);
						if ((!defined($VariantHash->{$SubsystemArray[0]}) || $VariantHash->{$SubsystemArray[0]} eq -1) && $Condition eq "OR") {
							$Result = "YES";
							last;
						} elsif (defined($VariantHash->{$SubsystemArray[0]}) && $VariantHash->{$SubsystemArray[0]} ne -1 && $Condition eq "AND") {
							$Result = "NO";
							last;
						}
					} elsif ($Array[$j] =~ m/^ROLE:(.+)/) {
						if (defined($RoleHash->{$1}) && $Condition eq "OR") {
							$Result = "YES";
							last;
						} elsif (!defined($RoleHash->{$1}) && $Condition eq "AND") {
							$Result = "NO";
							last;
						}
					} elsif ($Array[$j] =~ m/^!ROLE:(.+)/) {
						if (!defined($RoleHash->{$1}) && $Condition eq "OR") {
							$Result = "YES";
							last;
						} elsif (defined($RoleHash->{$1}) && $Condition eq "AND") {
							$Result = "NO";
							last;
						}
					} elsif ($Array[$j] =~ m/^CLASS:(.+)/) {
						if ($Class eq $1 && $Condition eq "OR") {
							$Result = "YES";
							last;
						} elsif ($Class ne $1 && $Condition eq "AND") {
							$Result = "NO";
							last;
						}
					} elsif ($Array[$j] =~ m/^!CLASS:(.+)/) {
						if ($Class ne $1 && $Condition eq "OR") {
							$Result = "YES";
							last;
						} elsif ($Class eq $1 && $Condition eq "AND") {
							$Result = "NO";
							last;
						}
					}
				}
				$Criteria = $Start.$Result.$End;
			} else {
				$End = 1;
				last;
			}
		}
		if ($Criteria eq "YES") {
			return 1;	
		} else {
			return 0;	
		}
	}
	return 1;
}

=head3 addReactionToModel

Definition:
	ModelSEED::MS::ModelReaction = ModelSEED::MS::Model->addReactionToModel({
		reaction => REQUIRED,
		direction => undef (default value will be pulled from reaction instance),
		protons => undef (default value will be pulled from reaction instance),
		gpr => "UNKNOWN"
	});
Description:
	Converts the input reaction instance into a model reaction and adds the reaction and associated compounds to the model.

=cut

sub addReactionToModel {
    my $self = shift;
	my $args = ModelSEED::utilities::args(["reaction"],{
		direction => undef,
		protons => undef,
		overrideCompartment => undef
	}, @_);
	my $rxn = $args->{reaction};
	if (!defined($args->{direction})) {
		$args->{direction} = $rxn->direction();	
	}
	my $mdlcmp = $args->{overrideCompartment};
	if (!defined($mdlcmp->{overrideCompartment}) || $rxn->isTransport()) {
		$mdlcmp = $self->addCompartmentToModel({compartment => $rxn->compartment(),pH => 7,potential => 0,compartmentIndex => 0});
	}
	my $mdlrxn = $self->queryObject("modelreactions",{
		reaction_uuid => $rxn->uuid(),
		modelcompartment_uuid => $mdlcmp->uuid()
	});
	if (!defined($mdlrxn)) {
		$mdlrxn = $self->add("modelreactions",{
			reaction_uuid => $rxn->uuid(),
			direction => $args->{direction},
			protons => $rxn->defaultProtons(),
			modelcompartment_uuid => $mdlcmp->uuid(),
		});
		my $rgts = $rxn->reagents();
		for (my $i=0; $i < @{$rgts}; $i++) {
			my $rgt = $rgts->[$i];
			my $rgtcmp = $self->addCompartmentToModel({compartment => $rgt->compartment(),pH => 7,potential => 0,compartmentIndex => 0});
			my $coefficient = $rgt->coefficient();
			my $mdlcpd = $self->addCompoundToModel({
				compound => $rgt->compound(),
				modelCompartment => $rgtcmp,
			});
			$mdlrxn->addReagentToReaction({
				coefficient => $coefficient,
				modelcompound_uuid => $mdlcpd->uuid()
			});
		}
	}
	return $mdlrxn;
}

=head3 addCompartmentToModel

Definition:
	ModelSEED::MS::Model = ModelSEED::MS::Model->addCompartmentToModel({
		Compartment => REQUIRED,
		pH => 7,
		potential => 0,
		compartmentIndex => 0
	});
Description:
	Adds a compartment to the model after checking that the compartment isn't already there

=cut

sub addCompartmentToModel {
    my $self = shift;
    my $args = ModelSEED::utilities::args(["compartment"],{
		pH => 7,
		potential => 0,
		compartmentIndex => 0
	}, @_);
	my $mdlcmp = $self->queryObject("modelcompartments",{compartment_uuid => $args->{compartment}->uuid(),compartmentIndex => $args->{compartmentIndex}});
	if (!defined($mdlcmp)) {
		$mdlcmp = $self->add("modelcompartments",{
			compartment_uuid => $args->{compartment}->uuid(),
			label => $args->{compartment}->id()."0",
			pH => $args->{pH},
			compartmentIndex => $args->{compartmentIndex},
		});
	}
	return $mdlcmp;
}

=head3 addCompoundToModel

Definition:
	ModelSEED::MS::ModelCompound = ModelSEED::MS::Model->addCompoundToModel({
		compound => REQUIRED,
		modelCompartment => REQUIRED,
		charge => undef (default values will be pulled from input compound),
		formula => undef (default values will be pulled from input compound)
	});
Description:
	Adds a compound to the model after checking that the compound isn't already there

=cut

sub addCompoundToModel {
    my $self = shift;
	my $args = ModelSEED::utilities::args(["compound","modelCompartment"],{
		charge => undef,
		formula => undef
	}, @_);
	my $mdlcpd = $self->queryObject("modelcompounds",{compound_uuid => $args->{compound}->uuid(),modelcompartment_uuid => $args->{modelCompartment}->uuid()});
	if (!defined($mdlcpd)) {
		if (!defined($args->{charge})) {
			$args->{charge} = $args->{compound}->defaultCharge();
		}
		if (!defined($args->{formula})) {
			$args->{formula} = $args->{compound}->formula();
		}
		$mdlcpd = $self->add("modelcompounds",{
			modelcompartment_uuid => $args->{modelCompartment}->uuid(),
			compound_uuid => $args->{compound}->uuid(),
			charge => $args->{charge},
			formula => $args->{formula},
		});
	}
	return $mdlcpd;
}

=head3 adjustBiomassReaction

Definition:
	ModelSEED::MS::Model->adjustBiomassReaction({
		biomass => string
		compound => string,
		compartment => string,
		compartmentIndex => integer,
		coefficient => float
	});
Description:
	Modifies the biomass reaction to adjust a compound, add a compound, or remove a compound
	
=cut
sub adjustBiomassReaction {
    my $self = shift;
    my $args = ModelSEED::utilities::args(["compound","coefficient"],{
    	biomass => "bio1",
    	compartment => "c",
    	compartmentIndex => 0
    }, @_);
    my $bio = $self->searchForBiomass($args->{biomass});
    if (!defined($bio)) {
    	ModelSEED::utilities::error("Biomass ".$args->{biomass}." not found!");
    }
    my $mdlcpd = $self->searchForCompound($args->{compound},$args->{compartment},$args->{compartmentIndex});
    if (!defined($mdlcpd)) {
    	ModelSEED::utilities::error("ModelCompound ".$args->{compound}."_".$args->{compartment}.$args->{compartmentIndex}." not found!");
    }
    $bio->adjustBiomassReaction({
    	coefficient => $args->{coefficient},
		modelcompound => $mdlcpd
    });
}

=head3 manualReactionAdjustment

Definition:
	ModelSEED::MS::Model->manualReactionAdjustment({
		reaction => string,
    	direction => string,
    	compartment => string,
    	compartmentIndex => integer,
    	gpr => [[[]]],
    	removeReaction => 0/1(0),
    	addReaction => 0/1(0)
	});
Description:
	
		
=cut
sub manualReactionAdjustment {
    my $self = shift;
    my $args = ModelSEED::utilities::args(["reaction"],{
    	direction => undef,
    	compartment => "c",
    	compartmentIndex => 0,
    	gpr => undef,
    	removeReaction => 0,
    	addReaction => 0
    }, @_);
    if ($args->{reaction} =~ m/^(.+)\[([a-z]+)(\d*)]$/) {
    	$args->{reaction} = $1;
    	$args->{compartment} = $2;
    	$args->{compartmentIndex} = $3;
    }
    if (!defined($args->{compartment})) {
    	$args->{compartment} = "c";
    }
    if (!defined($args->{compartmentIndex})) {
    	$args->{compartmentIndex} = 0;
    }
    my $mdlrxn = $self->searchForReaction($args->{reaction},$args->{compartment},$args->{compartmentIndex});
    if (defined($mdlrxn)) {
    	if ($args->{addReaction} == 1) {
    		ModelSEED::utilities::error("Cannot add reaction ".$args->{reaction}."_".$args->{compartment}.$args->{compartmentIndex}.", reaction is already in model!");
    	} elsif ($args->{removeReaction} == 1) {
    		$self->remove("modelreactions",$mdlrxn);
    	} else {
    		if (defined($args->{direction})) {
    			$mdlrxn->direction($args->{direction});
    		}
    		if (defined($args->{gpr})) {
    			$mdlrxn->setGPRFromArray({gpr => $args->{gpr}});
    		}
    	}
    } else {
    	if ($args->{removeReaction} == 1) {
    		ModelSEED::utilities::error("Cannot remove reaction ".$args->{reaction}."_".$args->{compartment}.$args->{compartmentIndex}.", reaction is not in model!");
    	} elsif ($args->{addReaction} == 1) {
    		my $bio = $self->biochemistry();
    		my $rxn = $bio->searchForReaction($args->{reaction});
    		if (!defined($rxn)) {
		    	ModelSEED::utilities::error("Reaction ".$args->{reaction}." not found in biochemistry!");
		    }
			my $cmp = $bio->queryObject("compartments",{id => $args->{compartment}});
		    if (!defined($cmp)) {
		    	ModelSEED::utilities::error("Compartment ".$args->{compartment}." not found in biochemistry!");
		    }
		    my $mdlcmp = $self->queryObject("modelcompartments",{
		    	compartment_uuid => $cmp->uuid(),
		    	compartmentIndex => $args->{compartmentIndex}
		    });
		    if (!defined($mdlcmp)) {
		    	$mdlcmp = $self->addCompartmentToModel({
		    		compartment => $cmp,
		    		pH => 7,
		    		potential => 0,
		    		compartmentIndex => $args->{compartmentIndex}
		    	});
		    }
		    my $mdlrxn = $self->addReactionToModel({
		    	reaction => $rxn,
		    	direction => $args->{direction},
				protons => undef,
				overrideCompartment => $mdlcmp
		    });
		    if (defined($args->{gpr})) {
    			$mdlrxn->setGPRFromArray({gpr => $args->{gpr}});
    		}
    	} else {
    		ModelSEED::utilities::error("Cannot alter reaction ".$args->{reaction}."_".$args->{compartment}.$args->{compartmentIndex}.", reaction is not in model!");
    	}
    }
}

=head3 labelBiomassCompounds

Definition:
	void ModelSEED::MS::Model->labelBiomassCompounds();
Description:
	Labels all model compounds indicating whether or not they are biomass components

=cut

sub labelBiomassCompounds {
	my $self = shift;
	for (my $i=0; $i < @{$self->modelcompounds()}; $i++) {
		my $cpd = $self->modelcompounds()->[$i];
		$cpd->isBiomassCompound(0);
	}
	for (my $i=0; $i < @{$self->biomasses()}; $i++) {
		my $bio = $self->biomasses()->[$i];
		for (my $j=0; $j < @{$bio->biomasscompounds()}; $j++) {
			my $biocpd = $bio->biomasscompounds()->[$j];
			$biocpd->modelcompound()->isBiomassCompound(1);
		}
	}
}

=head3 printSBML

Definition:
	void ModelSEED::MS::Model->printSBML();
Description:
	Prints the model in SBML format

=cut

sub printSBML {
    my $self = shift;
	# convert ids to SIds
    my $idToSId = sub {
        my $id = shift @_;
        my $cpy = $id;
        # SIds must begin with a letter
        $cpy =~ s/^([^a-zA-Z])/A_$1/;
        # SIDs must only contain letters numbers or '_'
        $cpy =~ s/[^a-zA-Z0-9_]/_/g;
        return $cpy;
    };
    #clean names
    my $stringToString = sub {
		my ($name,$value) = @_;
		$value =~ s/[\[\]\(\)\+]//g;
		$value =~ s/[\s:,]/_/g;
		return $name.'="'.XML::LibXML::Document->new('1.0', 'UTF-8')->createTextNode($value)->toString .'"';
    };
	#Printing header to SBML file
	my $ModelName = $idToSId->($self->id());
	my $output;
	push(@{$output},'<?xml version="1.0" encoding="UTF-8"?>');
	push(@{$output},'<sbml xmlns="http://www.sbml.org/sbml/level2" level="2" version="1" xmlns:html="http://www.w3.org/1999/xhtml">');
	my $name = $self->name()." SEED model";
	$name =~ s/[\s\.]/_/g;
	push(@{$output},'<model id="'.$ModelName.'" name="'.$name.'">');

	#Printing the unit data
	push(@{$output},"<listOfUnitDefinitions>");
	push(@{$output},"\t<unitDefinition id=\"mmol_per_gDW_per_hr\">");
	push(@{$output},"\t\t<listOfUnits>");
	push(@{$output},"\t\t\t<unit kind=\"mole\" scale=\"-3\"/>");
	push(@{$output},"\t\t\t<unit kind=\"gram\" exponent=\"-1\"/>");
	push(@{$output},"\t\t\t<unit kind=\"second\" multiplier=\".00027777\" exponent=\"-1\"/>");
	push(@{$output},"\t\t</listOfUnits>");
	push(@{$output},"\t</unitDefinition>");
	push(@{$output},"</listOfUnitDefinitions>");

	#Printing compartments for SBML file
	push(@{$output},'<listOfCompartments>');
	for (my $i=0; $i < @{$self->modelcompartments()}; $i++) {
		my $cmp = $self->modelcompartments()->[$i];
    	push(@{$output},'<compartment '.$stringToString->("id",$cmp->label()).' '.$stringToString->("name",$cmp->label()).' />');
    }
	push(@{$output},'</listOfCompartments>');
	#Printing the list of metabolites involved in the model
	push(@{$output},'<listOfSpecies>');
	for (my $i=0; $i < @{$self->modelcompounds()}; $i++) {
		my $cpd = $self->modelcompounds()->[$i];
		push(@{$output},'<species '.$stringToString->("id",$cpd->id()).' '.$stringToString->("name",$cpd->name()).' '.$stringToString->("compartment",$cpd->modelCompartmentLabel()).' '.$stringToString->("charge",$cpd->charge()).' boundaryCondition="false"/>');
		if ($cpd->compound()->id() eq "cpd11416" || $cpd->compound()->id() eq "cpd15302" || $cpd->compound()->id() eq "cpd08636") {
			push(@{$output},'<species '.$stringToString->("id",$cpd->compound()->id()."_b").' '.$stringToString->("name",$cpd->compound()->name()."_b").' '.$stringToString->("compartment",$cpd->modelCompartmentLabel()).' '.$stringToString->("charge",$cpd->charge()).' boundaryCondition="true"/>');
		}
	}
	for (my $i=0; $i < @{$self->modelcompounds()}; $i++) {
		my $cpd = $self->modelcompounds()->[$i];
		if ($cpd->modelCompartmentLabel() =~ m/^e/) {
			push(@{$output},'<species '.$stringToString->("id",$cpd->compound()->id()."_b").' '.$stringToString->("name",$cpd->compound()->name()."_b").' '.$stringToString->("compartment",$cpd->modelCompartmentLabel()).' '.$stringToString->("charge",$cpd->charge()).' boundaryCondition="true"/>');
		}
	}
	push(@{$output},'</listOfSpecies>');
	push(@{$output},'<listOfReactions>');
	my $mdlrxns = $self->modelreactions();
	for (my $i=0; $i < @{$mdlrxns}; $i++) {
		my $rxn = $mdlrxns->[$i];
		my $reversibility = "true";
		my $lb = -1000;
		if ($rxn->direction() ne "=") {
			$lb = 0;
			$reversibility = "false";
		}
		push(@{$output},'<reaction '.$stringToString->("id",$rxn->id()).' '.$stringToString->("name",$rxn->name()).' '.$stringToString->("reversible",$reversibility).'>');
		push(@{$output},"<notes>");
		my $ec = $rxn->reaction->getAlias("Enzyme Class");
		my $keggID = $rxn->reaction->getAlias("KEGG");
		my $GeneAssociation = $rxn->gprString;
		my $ProteinAssociation = $rxn->gprString;
		push(@{$output},"<html:p>GENE_ASSOCIATION:".$GeneAssociation."</html:p>");
		push(@{$output},"<html:p>PROTEIN_ASSOCIATION:".$ProteinAssociation."</html:p>");
		if (defined($keggID)) {
			push(@{$output},"<html:p>KEGG_RID:".$keggID."</html:p>");
		}
		if (defined($ec)) {
			push(@{$output},"<html:p>PROTEIN_CLASS:".$ec."</html:p>");
		}
		push(@{$output},"</notes>");
		my $firstreact = 1;
		my $firstprod = 1;
		my $prodoutput = [];
		my $rgts = $rxn->modelReactionReagents();
		my $sign = 1;
		if ($rxn->direction() eq "<") {
			$sign = -1;
		}
		for (my $i=0; $i < @{$rgts}; $i++) {
			my $rgt = $rgts->[$i];
			if ($sign*$rgt->coefficient() < 0) {
				if ($firstreact == 1) {
					$firstreact = 0;
					push(@{$output},"<listOfReactants>");
				}
				push(@{$output},'<speciesReference '.$stringToString->("species",$rgt->modelcompound()->id()).' '.$stringToString->("stoichiometry",(-1*$sign*$rgt->coefficient())).'/>');	
			} else {
				if ($firstprod == 1) {
					$firstprod = 0;
					push(@{$prodoutput},"<listOfProducts>");
				}
				push(@{$prodoutput},'<speciesReference '.$stringToString->("species",$rgt->modelcompound()->id()).' '.$stringToString->("stoichiometry",$sign*$rgt->coefficient()).'/>');
			}
		}
		if ($firstreact != 1) {
			push(@{$output},"</listOfReactants>");
		}
		if ($firstprod != 1) {
			push(@{$prodoutput},"</listOfProducts>");
		}
		push(@{$output},@{$prodoutput});
		push(@{$output},"<kineticLaw>");
		push(@{$output},"\t<math xmlns=\"http://www.w3.org/1998/Math/MathML\">");
		push(@{$output},"\t\t\t<ci> FLUX_VALUE </ci>");
		push(@{$output},"\t</math>");
		push(@{$output},"\t<listOfParameters>");
		push(@{$output},"\t\t<parameter id=\"LOWER_BOUND\" value=\"".$lb."\" name=\"mmol_per_gDW_per_hr\"/>");
		push(@{$output},"\t\t<parameter id=\"UPPER_BOUND\" value=\"1000\" name=\"mmol_per_gDW_per_hr\"/>");
		push(@{$output},"\t\t<parameter id=\"OBJECTIVE_COEFFICIENT\" value=\"0\"/>");
		push(@{$output},"\t\t<parameter id=\"FLUX_VALUE\" value=\"0.0\" name=\"mmol_per_gDW_per_hr\"/>");
		push(@{$output},"\t</listOfParameters>");
		push(@{$output},"</kineticLaw>");
		push(@{$output},'</reaction>');
	}
	my $bios = $self->biomasses();
	for (my $i=0; $i < @{$bios}; $i++) {
		my $rxn = $bios->[$i];
		my $obj = 0;
		if ($i==0) {
			$obj = 1;
		}
		my $reversibility = "false";
		push(@{$output},'<reaction '.$stringToString->("id","biomass".$i).' '.$stringToString->("name",$rxn->name()).' '.$stringToString->("reversible",$reversibility).'>');
		push(@{$output},"<notes>");
		push(@{$output},"<html:p>GENE_ASSOCIATION: </html:p>");
		push(@{$output},"<html:p>PROTEIN_ASSOCIATION: </html:p>");
		push(@{$output},"<html:p>SUBSYSTEM: </html:p>");
		push(@{$output},"<html:p>PROTEIN_CLASS: </html:p>");
		push(@{$output},"</notes>");
		my $firstreact = 1;
		my $firstprod = 1;
		my $prodoutput = [];
		my $biocpds = $rxn->biomasscompounds();
		for (my $i=0; $i < @{$biocpds}; $i++) {
			my $rgt = $biocpds->[$i];
			if ($rgt->coefficient() < 0) {
				if ($firstreact == 1) {
					$firstreact = 0;
					push(@{$output},"<listOfReactants>");
				}
				push(@{$output},'<speciesReference '.$stringToString->("species",$rgt->modelcompound()->id()).' '.$stringToString->("stoichiometry",-1*$rgt->coefficient()).'/>');	
			} else {
				if ($firstprod == 1) {
					$firstprod = 0;
					push(@{$prodoutput},"<listOfProducts>");
				}
				push(@{$prodoutput},'<speciesReference '.$stringToString->("species",$rgt->modelcompound()->id()).' '.$stringToString->("stoichiometry",$rgt->coefficient()).'/>');
			}
		}
		if ($firstreact != 1) {
			push(@{$output},"</listOfReactants>");
		}
		if ($firstprod != 1) {
			push(@{$prodoutput},"</listOfProducts>");
		}
		push(@{$output},@{$prodoutput});
		push(@{$output},"<kineticLaw>");
		push(@{$output},"\t<math xmlns=\"http://www.w3.org/1998/Math/MathML\">");
		push(@{$output},"\t\t\t<ci> FLUX_VALUE </ci>");
		push(@{$output},"\t</math>");
		push(@{$output},"\t<listOfParameters>");
		push(@{$output},"\t\t<parameter id=\"LOWER_BOUND\" value=\"0.0\" name=\"mmol_per_gDW_per_hr\"/>");
		push(@{$output},"\t\t<parameter id=\"UPPER_BOUND\" value=\"1000\" name=\"mmol_per_gDW_per_hr\"/>");
		push(@{$output},"\t\t<parameter id=\"OBJECTIVE_COEFFICIENT\" value=\"".$obj."\"/>");
		push(@{$output},"\t\t<parameter id=\"FLUX_VALUE\" value=\"0.0\" name=\"mmol_per_gDW_per_hr\"/>");
		push(@{$output},"\t</listOfParameters>");
		push(@{$output},"</kineticLaw>");
		push(@{$output},'</reaction>');
	}
	my $cpds = $self->modelcompounds();
	for (my $i=0; $i < @{$cpds}; $i++) {
		my $cpd = $cpds->[$i];
		my $lb = -1000;
		my $ub = 1000;
		if ($cpd->modelCompartmentLabel() =~ m/^e/ || $cpd->compound()->id() eq "cpd08636" || $cpd->compound()->id() eq "cpd11416" || $cpd->compound()->id() eq "cpd15302") {
			push(@{$output},'<reaction '.$stringToString->("id",'EX_'.$cpd->id()).' '.$stringToString->("name",'EX_'.$cpd->name()).' reversible="true">');
			push(@{$output},"\t".'<notes>');
			push(@{$output},"\t\t".'<html:p>GENE_ASSOCIATION: </html:p>');
			push(@{$output},"\t\t".'<html:p>PROTEIN_ASSOCIATION: </html:p>');
			push(@{$output},"\t\t".'<html:p>PROTEIN_CLASS: </html:p>');
			push(@{$output},"\t".'</notes>');
			push(@{$output},"\t".'<listOfReactants>');
			push(@{$output},"\t\t".'<speciesReference '.$stringToString->("species",$cpd->id()).' stoichiometry="1.000000"/>');
			push(@{$output},"\t".'</listOfReactants>');
			push(@{$output},"\t".'<listOfProducts>');
			push(@{$output},"\t\t".'<speciesReference '.$stringToString->("species",$cpd->compound()->id()."_b").' stoichiometry="1.000000"/>');
			push(@{$output},"\t".'</listOfProducts>');
			push(@{$output},"\t".'<kineticLaw>');
			push(@{$output},"\t\t".'<math xmlns="http://www.w3.org/1998/Math/MathML">');
			push(@{$output},"\t\t\t\t".'<ci> FLUX_VALUE </ci>');
			push(@{$output},"\t\t".'</math>');
			push(@{$output},"\t\t".'<listOfParameters>');
			push(@{$output},"\t\t\t".'<parameter id="LOWER_BOUND" value="'.$lb.'" units="mmol_per_gDW_per_hr"/>');
			push(@{$output},"\t\t\t".'<parameter id="UPPER_BOUND" value="'.$ub.'" units="mmol_per_gDW_per_hr"/>');
			push(@{$output},"\t\t\t".'<parameter id="OBJECTIVE_COEFFICIENT" value="0"/>');
			push(@{$output},"\t\t\t".'<parameter id="FLUX_VALUE" value="0.000000" units="mmol_per_gDW_per_hr"/>');
			push(@{$output},"\t\t".'</listOfParameters>');
			push(@{$output},"\t".'</kineticLaw>');
			push(@{$output},'</reaction>');
		}	
	}
	#Closing out the file
	push(@{$output},'</listOfReactions>');
	push(@{$output},'</model>');
	push(@{$output},'</sbml>');
	return join("\n",@{$output});
}

=head3 printExchange

Definition:
	string:Exchange format = ModelSEED::MS::Model->printExchange();
Description:
	Returns a string with the model in Exchange format

=cut

sub printExchange {
    my $self = shift;
	my $output = "Model{";
	$output .= "attributes(id\tname\ttype\tannotation\tmapping\tbiochemistry){\n";
	$output .= $self->id()."\t".$self->name()."\t".$self->type()."\t".$self->annotation_uuid()."\t".$self->mapping_uuid()."\t".$self->biochemistry_uuid()."\n";
	$output .= "}\n";
	$output .= "compartments(id\tname\tph\tpotential){\n";
	my $comps = $self->modelcompartments();
	foreach my $comp (@{$comps}) {
		$output .= $comp->id()."\t".$comp->name()."\t".$comp->pH()."\t".$comp->potential()."\n";	
	}
	$output .= "}\n";
	$output .= "compounds(id\tname\tabbrev\tformula\tcharge){\n";
	my $compounds = $self->modelcompounds();
	foreach my $cpd (@{$compounds}) {
		$output .= $cpd->id()."\t".$cpd->name()."\t".$cpd->abbreviation()."\t".$cpd->formula()."\t".$cpd->charge()."\n";
	}
	$output .= "}\n";
	$output .= "reactions(id\tname\tabbrev\tequation\tgpr){\n";
	my $reactions = $self->modelreactions();
	foreach my $rxn (@{$reactions}) {
		$output .= $rxn->id()."\t".$rxn->name()."\t".$rxn->abbreviation()."\t".$rxn->equation()."\t".$rxn->exchangeGPRString()."\n";
	}
	$output .= "}\n";
	$output .= "biomasses(id\tname\tequation){\n";
	my $biomasses = $self->biomasses();
	foreach my $bio (@{$biomasses}) {
		$output .= $bio->id()."\t".$bio->name()."\t".$bio->modelequation()."\n";
	}
	$output .= "}\n";
	$output .= "}\n";
	return $output;
}

=head3 printModelSEED

Definition:
	string:Exchange format = ModelSEED::MS::Model->printModelSEED();
Description:
	Returns a string with the model in ModelSEED format

=cut

sub printModelSEED {
    my $self = shift;
	my $output = "REACTIONS\n";
	$output .= "LOAD;DIRECTIONALITY;COMPARTMENT;ASSOCIATED PEG;SUBSYSTEM;CONFIDENCE;REFERENCE;NOTES\n";
	my $reactions = $self->modelreactions();
	foreach my $rxn (@{$reactions}) {
		my $dir = $rxn->direction();
		if ($dir eq ">") {
			$dir = "=>";
		} elsif ($dir eq "<") {
			$dir = "<=";
		} elsif ($dir eq "=") {
			$dir = "<=>";
		}
		my $gpr = $rxn->gprString();
		$gpr =~ s/fig\|\d+\.\d+\.//g;
		$output .= $rxn->reaction()->id().";".$dir.";c;".$gpr.";none;1;none;none\n";
	}
	my $biomasses = $self->biomasses();
	$output .= "NAME\t".$biomasses->[0]->id()."\n";
	$output .= "DATABASE\t".$biomasses->[0]->name()."\n";
	my $equation = $biomasses->[0]->modelequation();
	$equation =~ s/_c0//g;
	$equation =~ s/\+/ + /g;
	$equation =~ s/=>/ => /g;
	$equation =~ s/\)/) /g;
	$output .= "EQUATION\t".$equation."\n";
	return $output;
}

sub htmlComponents {
	my $self = shift;
	my $args = ModelSEED::utilities::args([],{}, @_);
	my $data = $self->_createReadableData();
	my $output = {
		title => $self->_type()." Viewer",
		tablist => [],
		tabs => {
			main => {
				content => "",
				name => "Overview"
			}
		}
	};
	$output->{tabs}->{main}->{content} .= "<table>\n";
	for (my $i=0; $i < @{$data->{attributes}->{headings}}; $i++) {
		$output->{tabs}->{main}->{content} .= "<tr><th>".$data->{attributes}->{headings}->[$i]."</th><td style='font-size:16px;border: 1px solid black;'>".$data->{attributes}->{data}->[0]->[$i]."</td></tr>\n";
	}
	$output->{tabs}->{main}->{content} .= "</table>\n";
	my $id;
	my $name;
	foreach my $subobject (@{$data->{subobjects}}) {
		if ($subobject->{name} ne "biomasses") {
			if ($subobject->{name} eq "modelcompartments") {
				$id = "tab-2";
				$name = "Compartments";
			} elsif ($subobject->{name} eq "modelcompounds") {
				$id = "tab-3";
				$name = "Compounds";
			} elsif ($subobject->{name} eq "modelreactions") {
				$id = "tab-4";
				$name = "Reactions";
			}
			push(@{$output->{tablist}},$id);
			$output->{tabs}->{$id} = {
                                content => ModelSEED::utilities::PRINTHTMLTABLE( $subobject->{headings}, $subobject->{data}, 'data-table'),
				name => $name
			};
		}
	}
	push(@{$output->{tablist}},("tab-5","tab-6","tab-7"));
	my $headingsOne = ["Biomass","DNA","RNA","Protein","Cellwall","Lipid","Cofactor","Energy"];
	my $headingsTwo = ["Biomass","Model compound","Name","Compartment","Coefficient"];
        my $dataOne = [];
        my $dataTwo = [];
	my $biomasses = $self->biomasses();
	foreach my $bio (@{$biomasses}) {
                push(@$dataOne, [ $bio->id(), $bio->dna(), $bio->rna(), $bio->protein(), $bio->cellwall(), $bio->lipid(), $bio->cofactor(), $bio->energy() ]);
		my $biocpds = $bio->biomasscompounds();
		foreach my $biocpd (@{$biocpds}) {
			if ($biocpd->coefficient() < 0) {
                                push(@$dataTwo, [ $bio->id(), $biocpd->modelcompound()->id(), $biocpd->modelcompound()->name(), $biocpd->modelcompound()->modelcompartment()->id(), $biocpd->coefficient() ]);
			}
		}
		foreach my $biocpd (@{$biocpds}) {
			if ($biocpd->coefficient() >= 0) {
                                push(@$dataTwo, [ $bio->id(), $biocpd->modelcompound()->id(), $biocpd->modelcompound()->name(), $biocpd->modelcompound()->modelcompartment()->id(), $biocpd->coefficient() ]);
			}
		}
	}
	my $tableOne = ModelSEED::utilities::PRINTHTMLTABLE( $headingsOne, $dataOne, 'data-table' );
	my $tableTwo = ModelSEED::utilities::PRINTHTMLTABLE( $headingsTwo, $dataTwo, 'data-table' );
	$output->{tabs}->{"tab-5"} = {
		content => $tableOne."<br>".$tableTwo,
		name => "Biomass reactions"
	};
	$headingsOne = ["Integrated","Gapfill simulation","Media","Solution","Cost","Gapfilled reaction","Biomass removal","Media supplement"];
        $dataOne = [];
	foreach my $gf (@{$self->integratedGapfillings()}) {
		if (defined($gf->gapfillingSolutions()->[0])) {
			my $count = 0;
			foreach my $sol (@{$gf->gapfillingSolutions()}) {
				my $rxns = "";
				my $bios = "";
				my $medias = "";
				foreach my $rxn (@{$sol->gapfillingSolutionReactions()}) {
					if (length($rxns)) {
						$rxns .= "<br>";
					}
					$rxns .= $rxn->reaction()->id().":".$rxn->reaction()->definition();
				}
				foreach my $cpd (@{$sol->mediaSupplements()}) {
					if (length($medias)) {
						$medias .= "<br>";
					}
					$medias .= $cpd->id().":".$cpd->name();
				}
				foreach my $bio (@{$sol->biomassRemovals()}) {
					if (length($bios)) {
						$bios .= "<br>";
					}
					$bios .= $bio->id().":".$bio->name();
				}
				my $integrated = "No";
				if ($sol->integrated() == 1) {
					$integrated	= "Yes";
				}
                                push(@$dataOne, [ $integrated, $gf->uuid(), $gf->fbaFormulation()->media()->uuid(), $count, $sol->solutionCost(), $rxns, $bios, $medias ]);
				$count++;
			}
		} else {
                    push(@$dataOne, [ "No", $gf->uuid(), $gf->fbaFormulation()->media()->uuid(), "None", "None", "None", "None", "None" ]);
		}
	}
	foreach my $gf (@{$self->unintegratedGapfillings()}) {
		if (defined($gf->gapfillingSolutions()->[0])) {
			my $count = 0;
			foreach my $sol (@{$gf->gapfillingSolutions()}) {
				my $rxns = "";
				my $bios = "";
				my $medias = "";
				foreach my $rxn (@{$sol->gapfillingSolutionReactions()}) {
					if (length($rxns)) {
						$rxns .= "<br>";
					}
					$rxns .= $rxn->reaction()->id().":".$rxn->reaction()->definition();
				}
				foreach my $cpd (@{$sol->mediaSupplements()}) {
					if (length($medias)) {
						$medias .= "<br>";
					}
					$medias .= $cpd->id().":".$cpd->name();
				}
				foreach my $bio (@{$sol->biomassRemovals()}) {
					if (length($bios)) {
						$bios .= "<br>";
					}
					$bios .= $bio->id().":".$bio->name();
				}
                                push(@$dataOne, [ "No", $gf->uuid(), $gf->fbaFormulation()->media()->uuid(), $count, $sol->solutionCost(), $rxns, $bios, $medias ]);
				$count++;
			}
		} else {
                        push(@$dataOne, [ "No", $gf->uuid(), $gf->fbaFormulation()->media()->uuid(), "None", "None", "None", "None", "None" ]);
		}
	}
	$output->{tabs}->{"tab-6"} = {
		content => ModelSEED::utilities::PRINTHTMLTABLE( $headingsOne, $dataOne, 'data-table' ),
		name => "Gapfilling"
	};
	$headingsOne = ["Integrated","Gapgen simulation","Media","Solution","Cost","Removed reaction","Biomass addition","Media removal"];
        $dataOne = [];
	foreach my $gg (@{$self->integratedGapgens()}) {
		if (defined($gg->gapgenSolutions()->[0])) {
			my $count = 0;
			foreach my $sol (@{$gg->gapgenSolutions()}) {
				my $rxns = "";
				my $bios = "";
				my $medias = "";
				foreach my $rxn (@{$sol->gapgenSolutionReactions()}) {
					if (length($rxns)) {
						$rxns .= "<br>";
					}
					$rxns .= $rxn->modelreaction()->id().":".$rxn->reaction()->definition();
				}
				foreach my $cpd (@{$sol->mediaRemovals()}) {
					if (length($medias)) {
						$medias .= "<br>";
					}
					$medias .= $cpd->id().":".$cpd->name();
				}
				foreach my $bio (@{$sol->biomassSupplements()}) {
					if (length($bios)) {
						$bios .= "<br>";
					}
					$bios .= $bio->id().":".$bio->name();
				}
				my $integrated = "No";
				if ($sol->integrated() == 1) {
					$integrated	= "Yes";
				}
                                push(@$dataOne, [ $integrated, $gg->uuid(), $gg->fbaFormulation()->media()->uuid(), $count, $sol->solutionCost(), $rxns, $bios, $medias ]);
				$count++;
			}
		} else {
                        push(@$dataOne, [ "No", $gg->uuid(), $gg->fbaFormulation()->media()->uuid(), "None", "None", "None", "None", "None" ]);
		}
	}
	foreach my $gg (@{$self->unintegratedGapgens()}) {
		if (defined($gg->gapgenSolutions()->[0])) {
			my $count = 0;
			foreach my $sol (@{$gg->gapgenSolutions()}) {
				my $rxns = "";
				my $bios = "";
				my $medias = "";
				foreach my $rxn (@{$sol->gapgenSolutionReactions()}) {
					if (length($rxns)) {
						$rxns .= "<br>";
					}
					$rxns .= $rxn->modelreaction()->id().":".$rxn->reaction()->definition();
				}
				foreach my $cpd (@{$sol->mediaRemovals()}) {
					if (length($medias)) {
						$medias .= "<br>";
					}
					$medias .= $cpd->id().":".$cpd->name();
				}
				foreach my $bio (@{$sol->biomassSupplements()}) {
					if (length($bios)) {
						$bios .= "<br>";
					}
					$bios .= $bio->id().":".$bio->name();
				}
                                push(@$dataOne, [ "No", $gg->uuid(), $gg->fbaFormulation()->media()->uuid(), $count, $sol->solutionCost(), $rxns, $bios, $medias ]);
				$count++;
			}
		} else {
                        push(@$dataOne, [ "No", $gg->uuid(), $gg->fbaFormulation()->media()->uuid(), "None", "None", "None", "None", "None" ]);
		}
	}
	$output->{tabs}->{"tab-7"} = {
		content => ModelSEED::utilities::PRINTHTMLTABLE( $headingsOne, $dataOne, 'data-table' ),
		name => "Gapgen"
	};
	return $output;
}

=head3 export

Definition:
	string = ModelSEED::MS::Model->export();
Description:
	Exports model data to the specified format.

=cut

sub export {
    my $self = shift;
	my $args = ModelSEED::utilities::args(["format"], {}, @_);
	if (lc($args->{format}) eq "sbml") {
		return $self->printSBML();
	} elsif (lc($args->{format}) eq "exchange") {
		return $self->printExchange();
	} elsif (lc($args->{format}) eq "readable") {
		return $self->toReadableString();
	} elsif (lc($args->{format}) eq "html") {
		return $self->createHTML();
	} elsif (lc($args->{format}) eq "json") {
		return $self->toJSON({pp => 1});
	} elsif (lc($args->{format}) eq "cytoseed") {
		return $self->printCytoSEED();
	} elsif (lc($args->{format}) eq "modelseed") {
		return $self->printModelSEED();
	}
	ModelSEED::utilities::error("Unrecognized type for export: ".$args->{format});
}


=head3 printCytoSEED

Definition:
	void ModelSEED::MS::Model->printCytoSEED();
Description:
	Prints the model in CytoSEED format

=cut

sub printCytoSEED {
	my ($self,$args) = @_;

	sub compound_to_results {
	    my ($compound, $abstract_compounds, $modelid) = @_;
	   	my $abstractCpd;
	    if (defined($compound->abstractCompound_uuid) && $compound->abstractCompound_uuid =~ m/[A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12}/) {
	    	$abstractCpd = $compound->abstractCompound();
	    }
	    $abstract_compounds->{$abstractCpd->id()} = 1 if defined $abstractCpd;
	    my $keggids = $compound->getAliases("KEGG");
	    # make a copy to keep YAML happy
	    my @keggids = $keggids ? @$keggids : ();
	    my $msid = $compound->id();
	    return ($msid, { "ABBREV" => [$compound->abbreviation()],
			     "NAME" => [$compound->name()],
			     "DATABASE" => [$msid],
			     "FORMULA" => [$compound->formula()],
			     "GROUPING" => [], # FIX
			     "KEGGID" => \@keggids },
		    (defined $abstractCpd) ? [ $abstractCpd->id() ] : []);
	}

	sub reaction_to_results {
	    my ($reaction, $modelreaction, $abstract_reactions, $modelid) = @_;
	    my $abstractRxn;
	    if (defined($reaction->abstractReaction_uuid) && $reaction->abstractReaction_uuid =~ m/[A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12}/) {
	    	$abstractRxn = $reaction->abstractReaction();
	    }
	    $abstract_reactions->{$abstractRxn->id()} = 1 if defined $abstractRxn;
	    my $keggids = $reaction->getAliases("KEGG");
	    # make a copy to keep YAML happy
	    my @keggids = $keggids ? @$keggids : ();
	    my $ecs = $reaction->getAliases("Enzyme Class");
	    my $msid = $reaction->id();
	    my (@substrates, @products);
	    foreach my $reagent (@{$reaction->reagents()}) {
		my $compound = $reagent->compound();
		my $coeff = $reagent->coefficient();
		my $compartment = $reagent->compartment;
		my $cmsid = $compound->id();
		$cmsid = $cmsid."[".$compartment->id()."]" if $compartment->id() ne "c";
		if ($coeff < 0) {
		    if ($coeff == -1) {
			push @substrates, $cmsid;
		    }
		    else {
			push @substrates, "(".(abs $coeff).") ".$cmsid;
		    }
		}
		else {
		    if ($coeff == 1) {
			push @products, $cmsid;
		    }
		    else {
			push @products, "(".(abs $coeff).") ".$cmsid;
		    }
		}
	    }
#	    my $direction = $reaction->direction();
#	    if ($direction ne "=") {
#		print STDERR "$msid direction: $direction\n";
#	    }
	    my $equation = (join " + ", @substrates)." <=> ".(join " + ",  @products);

	    my $reversibility = $reaction->thermoReversibility();

	    if (! defined $reversibility) {
		print STDERR "No reversibility for $msid\n";
		$reversibility = "=";
	    }

	    $reversibility = "<=>" if $reversibility eq "=";
	    my $rdref = { "DATABASE" => [$msid],
			  "NAME" => [$reaction->name()],
			  "EQUATION" => [$equation],
			  "REVERSIBILITY" => [$reversibility],
			  "ENZYME" => $ecs,
			  "KEGG MAPS" => [], #FIX
			  "KEGGID" => \@keggids };

	    if (defined $modelreaction) {
		my %pegs;
		my %notes;
		foreach my $protein (@{$modelreaction->modelReactionProteins()}) {
		    $notes{$protein->note()} = 1 if defined $protein->note();
		    foreach my $subunit (@{$protein->modelReactionProteinSubunits()}) {
			$notes{$subunit->note()} = 1 if defined $protein->note();
			foreach my $gene (@{$subunit->modelReactionProteinSubunitGenes()}) {
			    my $feature = $gene->feature();
			    $pegs{$feature->id()} = 1 if defined $feature->id();
			}
		    }
		}
		my @pegs = keys %pegs;
		my @notes = keys %notes;
		# $modelid is a global variable
		$rdref->{$modelid} = { "SUBSYSTEM" => [],
				       "ASSOCIATED PEG" => \@pegs,
				       "NOTES" => \@notes };
	    }
	    
	    return ($msid, $rdref, (defined $abstractRxn) ? [ $abstractRxn->id() ] : []);
	}

	my $model = $self;
	my $modelid = $model->id();
	my (%abstract_compounds, %abstract_reactions);
	my $result = {};
	my $bc = $model->biochemistry();
	my $annotation = $model->annotation();
	my $genome = $annotation->genomes()->[0];

	$result->{"model_data"} = {"Genome" => "ID:".$genome->id(), 
				   "Id" => $modelid, 
				   "Name" => $genome->name(), 
				   "Media" => "Complete", # FIX
				   "Source" => $genome->source()};

	my $compounds = $model->modelcompounds();
	my $reactions = $model->modelreactions();

	foreach my $modelcompound (@$compounds) {
	    my $compound = $modelcompound->compound();
	    my ($msid, $cdref, $extra) = compound_to_results($compound, \%abstract_compounds, $modelid);
	    $cdref->{"ABSTRACT COMPOUND"} = $extra;
	    $result->{"compound_details"}->{$msid} = $cdref;
	}

# now the abstract compounds are loaded into the hash
	$result->{"abstract_compound_details"} = {};
	foreach my $abstract_cpd (keys %abstract_compounds) {
	    my $a_cpd = $bc->getObjectByAlias("compounds", $abstract_cpd, "ModelSEED");
	    my ($msid, $cdref) = compound_to_results($a_cpd, \%abstract_compounds, $modelid);
	    $cdref->{"GROUPING"} = []; # FIX
	    $result->{"abstract_compound_details"}->{$msid} = $cdref;
	}

	foreach my $modelreaction (@$reactions) {
	    my $reaction = $modelreaction->reaction();
	    my ($msid, $rdref, $extra) = reaction_to_results($reaction, $modelreaction, \%abstract_reactions, $modelid);
	    $rdref->{"ABSTRACT REACTION"} = $extra;
	    $result->{"reaction_details"}->{$msid} = $rdref;
	}

	$result->{"abstract_reaction_details"} = {};
	foreach my $abstract_rxn (keys %abstract_reactions) {
	    my $a_rxn = $bc->getObjectByAlias("reactions", $abstract_rxn, "ModelSEED");
	    my ($msid, $rdref) = reaction_to_results($a_rxn, undef, \%abstract_reactions, $modelid);
	    $rdref->{"GROUPING"} = []; # FIX
	    $result->{"abstract_reaction_details"}->{$msid} = $rdref;
	}

	my $biomasses = $model->biomasses();

	if (@$biomasses == 0) {
	    print STDERR "No biomass\n";
	    $result->{"biomass_reaction_details"} = {};
	}
	else {
	    my $biomass = $biomasses->[0];
	    if (@$biomasses != 1) {
		print STDERR "Multiple biomasses, using the first one\n";
	    }

	    my (@substrates, @products);
	    foreach my $bmcpd (@{$biomass->biomasscompounds()}) {
		my $modelcompound = $bmcpd->modelcompound();
		my $coeff = $bmcpd->coefficient();
		my $compound = $modelcompound->compound();
		my $cmsid = $compound->id();
		if ($coeff < 0) {
		    if ($coeff == -1) {
			push @substrates, $cmsid;
		    }
		    else {
			push @substrates, "(".(abs $coeff).") ".$cmsid;
		    }
		}
		else {
		    if ($coeff == 1) {
			push @products, $cmsid;
		    }
		    else {
			push @products, "(".(abs $coeff).") ".$cmsid;
		    }
		}
	    }
	    my $equation = (join " + ", @substrates)." <=> ".(join " + ",  @products);

	    $result->{"biomass_reaction_details"} = { 
		$modelid => {
		    "DATABASE" => ["bio00000"], # FIX
		    "EQUATION" => [$equation] 
		}
	    };
	}

	my $fba_results = [];
	my $reaction_classifications = {};

	foreach my $fbaFormulation (@{$model->fbaFormulations()}) {
	    if ($fbaFormulation->maximizeObjective()) {
		my @fbaFormulationResults = @{$fbaFormulation->fbaResults()};
		if (@fbaFormulationResults != 1) {
		    print STDERR "Expected 1 fbaResult, got: ", scalar @fbaFormulationResults, "\n";
		    next;
		}
		my $fbaResult = $fbaFormulationResults[0];
		my $fba = {};
		my $fluxes = [];
		$fba->{"fluxes"} = $fluxes;
		$fba->{"media"} = $fbaFormulation->media()->name();
		$fba->{"time"} = $fbaFormulation->modDate();
		$fba->{"growth"} = $fbaResult->objectiveValue();
		my @reactionVariables = @{$fbaResult->fbaReactionVariables()};
		next if @reactionVariables == 0; # FBA failed

		foreach my $rVar (@reactionVariables) {
		    my $flux = {};
		    my $modelreaction = $rVar->modelreaction();
		    my $reaction = $modelreaction->reaction();
		    $flux->{"reaction"} = $reaction->id();
		    $flux->{"flux"} = $rVar->value();
		    push @$fluxes, $flux;
		    if ($fbaFormulation->fva()) {
			my $class = $rVar->{"class"};
			my $min = $rVar->{"min"};
			my $max = $rVar->{"max"};
			my $dir;
			if ($class eq "Positive") {
			    $class = "essential";
			    $dir = "=>";
			}
			elsif ($class eq "Negative") {
			    $class = "essential";
			    $dir = "<=";
			}
			elsif ($class eq "Positive variable") {
			    $class = "active";
			    $dir = "=>";
			}
			elsif ($class eq "Negative variable") {
			    $class = "active";
			    $dir = "<=";
			}
			elsif ($class eq "Variable") {
			    $class = "active";
			    $dir = "<=>";
			}
			elsif ($class eq "Blocked") {
			    $class = "dead";
			    $dir = "NA";
			}
			else {
			    print STDERR "For reaction ", $reaction->id(), ", class is ", $class, "\n";
			    $class = "dead";
			    $dir = "NA";
			}
			push @{$reaction_classifications->{$reaction->id()}->{"class"}}, $class;
			push @{$reaction_classifications->{$reaction->id()}->{"class_directionality"}}, $dir;
			push @{$reaction_classifications->{$reaction->id()}->{"max_flux"}}, $max;
			push @{$reaction_classifications->{$reaction->id()}->{"min_flux"}}, $min;
			push @{$reaction_classifications->{$reaction->id()}->{"media"}}, $fbaFormulation->media()->name();
			push @{$reaction_classifications->{$reaction->id()}->{"reaction"}}, $reaction->id();
		    }
		}

		if (! $fbaFormulation->fva()) {
		    push @{$fba_results}, $fba;
		}
	    }    
	}

	$result->{"fba_results"} = { $modelid => $fba_results };
	$result->{"reaction_classifications"}->{$modelid} = [values %$reaction_classifications];

	return YAML::XS::Dump $result;
}

#***********************************************************************************************************
# ANALYSIS FUNCTIONS:
#***********************************************************************************************************

=head3 gapfillModel

Definition:
	ModelSEED::MS::GapfillingSolution ModelSEED::MS::Model->gapfillModel({
		gapfillingFormulation => ModelSEED::MS::GapfillingFormulation,
		fbaFormulation => ModelSEED::MS::FBAFormulation
	});
Description:
	Runs gapfilling on the model and integrates the output gapfilling solution

=cut

sub gapfillModel {
    my $self = shift;
	my $args = ModelSEED::utilities::args(["gapfillingFormulation"],{
		fbaFormulation => undef,integrateSolution => 1
	}, @_);
	my $solution = $args->{gapfillingFormulation}->runGapFilling({
		model => $self,
		fbaFormulation => $args->{fbaFormulation}
	});
	if (defined($solution)) {
		push(@{$self->fbaFormulation_uuids()},$args->{gapfillingFormulation}->fbaFormulation_uuid());
		push(@{$self->unintegratedGapfilling_uuids()},$args->{gapfillingFormulation}->uuid());
		return $solution;	
	}
	return;
}

=head3 integrateGapfillSolution

Definition:
	void ModelSEED::MS::Model->integrateGapfillSolution({
		solution => ModelSEED::MS::GapfillingFormulation*
	});
Description:
	Integrates a gapfilling solution into the model
	
=cut

sub integrateGapfillSolution {
    my $self = shift;
	my $args = ModelSEED::utilities::args(["gapfillingFormulation"], { solutionNum => 0 }, @_);
	ModelSEED::utilities::verbose("Now integrating gapfill solution into model");
	my $gf = $args->{gapfillingFormulation};
	my $num = $args->{solutionNum};
	my $gfss = $gf->gapfillingSolutions();
	if (@{$gfss} <= $num) {
		ModelSEED::utilities::error("Specified solution not found in gapfilling formulation!");
	}
	my $sol = $gfss->[$num];
	$sol->integrated(1);
	#Integrating biomass removals into model
	if (defined($sol->biomassRemovals()) && @{$sol->biomassRemovals()} > 0) {
		my $removals = $sol->biomassRemovals();
		foreach my $rem (@{$removals}) {
            my $biomass = $self->biomasses()->[0];
			my $biocpds = $biomass->biomasscompounds();
			foreach my $biocpd (@{$biocpds}) {
				if ($biocpd->modelcompound()->uuid() eq $rem) {
					ModelSEED::utilities::verbose(
						"Removing ".$biocpd->modelcompound()->id()." from model biomass."
					);
					$biomass->remove("biomasscompounds",$biocpd);
					last;
				}
			}
		}
	}	
	#Integrating new reactions into model
	my $rxns = $sol->gapfillingSolutionReactions();
	for (my $i=0; $i < @{$rxns}; $i++) {
		my $rxn = $rxns->[$i];
		my $mdlrxn = $self->queryObject("modelreactions",{reaction_uuid => $rxn->reaction_uuid()});
		if (defined($mdlrxn) && $rxn->direction() ne $mdlrxn->direction()) {
			ModelSEED::utilities::verbose(
				"Making ".$mdlrxn->id()." reversible."
			);
			$mdlrxn->direction("=");
		} else {
			ModelSEED::utilities::verbose(
				"Adding ".$rxn->reaction()->id()." to model in ".$rxn->direction()." direction."
			);
			$self->addReactionToModel({
				reaction => $rxn->reaction(),
				direction => $rxn->direction()
			});
		}
	}
	#Checking if gapfilling formulation is in the unintegrated list 
	$self->removeLinkArrayItem("unintegratedGapfillings",$gf);
	$self->addLinkArrayItem("integratedGapfillings",$gf);
	$self->integratedGapfillingSolutions()->{$gf->uuid()} = $num;
}

=head3 gapgenModel

Definition:
	ModelSEED::MS::GapgenSolution = ModelSEED::MS::Model->gapgenModel({
		gapgenFormulation => ModelSEED::MS::GapgenFormulation,
		fbaFormulation => ModelSEED::MS::FBAFormulation
	});
Description:
	Runs gapgeneration on the model and integrates the output gapgeneration solution

=cut

sub gapgenModel {
    my $self = shift;
	my $args = ModelSEED::utilities::args(["gapgenFormulation"], { fbaFormulation => undef,integrateSolution => 1 }, @_);
	my $solution = $args->{gapgenFormulation}->runGapGeneration({
		model => $self,
		fbaFormulation => $args->{fbaFormulation}
	});
	if (defined($solution)) {
		push(@{$self->fbaFormulation_uuids()},$args->{gapgenFormulation}->fbaFormulation_uuid());
		push(@{$self->gapgenFormulation_uuids()},$args->{gapgenFormulation}->uuid());
		return $solution;	
	}
	return;
}

=head3 integrateGapgenSolution

Definition:
	void ModelSEED::MS::Model->integrateGapgenSolution({
		solution => ModelSEED::MS::GapgenFormulation*
	});
Description:
	Integrates a gapgen solution into the model
	
=cut

sub integrateGapgenSolution {
	my $self = shift;
    my $args = ModelSEED::utilities::args(["gapgenFormulation"], { solutionNum => 0 }, @_);
	ModelSEED::utilities::verbose("Now integrating gapgen solution into model");
	my $gg = $args->{gapgenFormulation};
	my $num = $args->{solutionNum};
	my $ggss = $gg->gapgenSolutions();
	if (@{$ggss} <= $num) {
		ModelSEED::utilities::error("Specified solution not found in gapgen formulation!");
	}
	my $sol = $ggss->[$num];
	$sol->integrated(1);
	my $solrxns = $sol->gapgenSolutionReactions();
	for (my $m=0; $m < @{$solrxns}; $m++) {
		my $rxn = $solrxns->[$m];
        my $direction = $rxn->direction;
		if ($direction eq $rxn->modelreaction()->direction()) {
			ModelSEED::utilities::verbose("Reaction ".$rxn->modelreaction()->id()." removed.");
			$self->remove("modelreactions",$rxn->modelreaction());
		} elsif ($direction eq ">") {
			ModelSEED::utilities::verbose("Reaction ".$rxn->modelreaction()->id()." switched to <.");
			$rxn->modelreaction()->direction("<");
		} elsif ($direction eq "<") {
			ModelSEED::utilities::verbose("Reaction ".$rxn->modelreaction()->id()." switched to >.");
			$rxn->modelreaction()->direction(">");
		}
	}
	#Checking if gapfilling formulation is in the unintegrated list 
	$self->removeLinkArrayItem("unintegratedGapgens",$gg);
	$self->addLinkArrayItem("integratedGapgens",$gg);
	$self->integratedGapgenSolutions()->{$gg->uuid()} = $num;
}

sub printExchangeFormat {
	my ($self) = @_;
    my $textArray = [
    	"Attributes {",
    	"\tname:".$self->name(),
    	"\tdefaultNameSapce:".$self->defaultNameSpace(),
    	"}",
    	"Biomasses (biomassReaction	compound	coefficient	compartment) {"
	];
	my $bios = $self->biomasses();
	for (my $i=0; $i < @{$bios}; $i++) {
		my $biocpds = $bios->[$i]->biomasscompounds();
		for (my $j=0; $j < @{$biocpds}; $j++) {
			my $items = ["biomass".$i];
			$items->[1] = "Compound/".$self->defaultNameSpace()."/".$biocpds->[$j]->modelcompound()->compound()->id();
			$items->[2] = $biocpds->[$j]->coefficient();
			$items->[3] = $biocpds->[$j]->modelcompound()->compartmentLabel();
			push(@{$textArray},"\t".join("\t",@{$items}));
		}
	}
	push(@{$textArray},("}","Reactions (reaction	direction	compartment	gpr) {"));
    my $reactions = $self->modelreactions();
	my $rows;
	foreach my $reaction (@$reactions) {
        my $rxn_id = $reaction->reaction()->id;
        my $dir    = $reaction->direction;
        my $cmp_id = $reaction->modelcompartment->label;
        my $gpr    = $self->_make_GPR_string($reaction);
        push(@$rows, [$rxn_id, $dir, $cmp_id, $gpr]);
    }
   	push(@{$textArray},"}");
    return join("\n",@{$textArray});
}

=head3 buildGraph

Definition:
	Graph = ModelSEED::MS::Model->buildGraph();
Description:
	This command builds a graph object from the model

=cut

sub buildGraph {
    my $self = shift;
	my $args = ModelSEED::utilities::args([], {reactions => 0}, @_);
	my $graph = Graph::Directed->new;
	if ($args->{reactions} == 0) {
		my $cpds = $self->modelcompounds();
		for (my $i=0;$i < @{$cpds}; $i++) {
			my $v = $cpds->[$i]->id();
			$graph->add_vertex($v);
		}
	}
	my $rxns = $self->modelreactions();
	my $rxnStartHash;
	for (my $i=0; $i < @{$rxns}; $i++) {
		if ($args->{reactions} == 1) {
			$graph->add_vertex($rxns->[$i]->id());	
		}
		my $rgts = $rxns->[$i]->modelReactionReagents();
		for (my $j=0; $j < @{$rgts}; $j++) {
			my $rgt = $rgts->[$j];
			if (!$rgt->isCofactor() && $rgt->coefficient() < 0 && $rxns->[$i]->direction() ne "<") {
				if ($args->{reactions} == 1) {
					$rxnStartHash->{$rgt->modelcompound()->id()}->{$rxns->[$i]->id()} = 1;
				} else {
					for (my $k=0; $k < @{$rgts}; $k++) {
						my $prod = $rgts->[$k];
						if (!$prod->isCofactor() && $prod->coefficient() > 0) {
							$graph->add_edge($rgt->modelcompound()->id(),$prod->modelcompound()->id());
						}
					}
				}
			} elsif (!$rgt->isCofactor() && $rgt->coefficient() > 0 && $rxns->[$i]->direction() ne ">") {
				if ($args->{reactions} == 1) {
					$rxnStartHash->{$rgt->modelcompound()->id()}->{$rxns->[$i]->id()} = 1;
				} else {
					for (my $k=0; $k < @{$rgts}; $k++) {
						my $prod = $rgts->[$k];
						if (!$prod->isCofactor() && $prod->coefficient() < 0) {
							$graph->add_edge($rgt->modelcompound()->id(),$prod->modelcompound()->id());
						}
					}
				}
			}
		}
	}
	if ($args->{reactions} == 1) {
		for (my $i=0; $i < @{$rxns}; $i++) {
			my $rgts = $rxns->[$i]->modelReactionReagents();
			for (my $j=0; $j < @{$rgts}; $j++) {
				my $rgt = $rgts->[$j];
				if (!$rgt->isCofactor() && $rgt->coefficient() > 0 && $rxns->[$i]->direction() ne "<") {
					foreach my $rxnid (keys(%{$rxnStartHash->{$rgt->modelcompound()->id()}})) {
						$graph->add_edge($rxns->[$i]->id(),$rxnid);
					}
				} elsif (!$rgt->isCofactor() && $rgt->coefficient() < 0 && $rxns->[$i]->direction() ne ">") {
					foreach my $rxnid (keys(%{$rxnStartHash->{$rgt->modelcompound()->id()}})) {
						$graph->add_edge($rxns->[$i]->id(),$rxnid);
					}
				}
			}
		}
	}
	return $graph;
}

=head3 computeNetworkDistances

Definition:
	Table = ModelSEED::MS::Model->computeNetworkDistances();
Description:
	This command computes distances between all metabolites, reactions, and functional roles

=cut

sub computeNetworkDistances {
    my $self = shift;
	my $args = ModelSEED::utilities::args([], { reactions => 0, roles => 0 }, @_);
	my $input = {};
	my $tbl = {headings => ["Compounds"],data => []};
	if ($args->{roles} == 1 || $args->{reactions} == 1) {
		$input->{reactions} = 1;
		$tbl = {headings => ["Reactions"],data => []};
		if ($args->{roles} == 1) {
			$tbl = {headings => ["Roles"],data => []};
		}
	}
	print STDERR "Building graph!\n";
	my $graph = $self->buildGraph($input);
	print STDERR "Computing distances!\n";
	my $apsp = $graph->all_pairs_shortest_paths();
	print STDERR "Shortest paths computed!\n";
	if ($args->{roles} == 1 || $args->{reactions} == 1) {
		my ($roleHash,%rxn2roles);
		my $rxns = $self->modelreactions();
		$tbl->{headings}->[0] = "Reactions";
		if ($args->{roles} == 1) {
			$tbl->{headings}->[0] = "Roles";
			for (my $i=0; $i < @{$rxns}; $i++) {
			    my $modelrxn = $rxns->[$i];
			    my @roles;
			    foreach my $protein (@{$modelrxn->modelReactionProteins()}) {
				foreach my $subunit (@{$protein->modelReactionProteinSubunits()}) {
				    push @roles, $subunit->role();
				}
			    }
			    $rxn2roles{$rxns->[$i]->id()} = \@roles;
			    for (my $j=0;$j < @roles; $j++) {
				$roleHash->{$roles[$j]->name()} = 1;
			    }
			}
			my $count = 0;
			foreach my $role (sort(keys(%{$roleHash}))) {
				$roleHash->{$role} = $count;
				$count++;
			}
		}
		for (my $i=0; $i < @{$rxns}; $i++) {
			if ($args->{reactions} == 1) {
				$tbl->{headings}->[$i+1] = $rxns->[$i]->id();
				$tbl->{data}->[$i]->[0] = $rxns->[$i]->id();
			} else {
				my $count = 0;
				foreach my $role (sort(keys(%{$roleHash}))) {
					$tbl->{headings}->[$count+1] = $role;
					$tbl->{data}->[$count]->[0] = $role;
					$count++;
				}
			}
			for (my $j=0;$j < @{$rxns}; $j++) {
				if ($args->{reactions} == 1) {
				    if ($i == $j) {
					$tbl->{data}->[$i]->[$j+1] = 0;
				    } else {
					$tbl->{data}->[$i]->[$j+1] =  $apsp->path_length($rxns->[$i]->id(), $rxns->[$j]->id());
					if (!defined($tbl->{data}->[$i]->[$j+1])) {
						$tbl->{data}->[$i]->[$j+1] = -1;
					}
				    }
				} else {
				        my @roles1 = @{$rxn2roles{$rxns->[$i]->id()}};
					for (my $k=0;$k < @roles1; $k++) {
						my $indexOne = $roleHash->{$roles1[$k]->name()};

						my @roles2 = @{$rxn2roles{$rxns->[$j]->id()}};
						for (my $m=0;$m < @roles2; $m++) {
							my $indexTwo = $roleHash->{$roles2[$m]->name()}+1;
							if (defined($tbl->{data}->[$indexOne]->[$indexTwo])) {
							    if ($apsp->path_length($rxns->[$i]->id(), $rxns->[$j]->id()) < $tbl->{data}->[$indexOne]->[$indexTwo]) {
								$tbl->{data}->[$indexOne]->[$indexTwo] = $apsp->path_length($rxns->[$i]->id(), $rxns->[$j]->id());
							    }
							} else {
							    $tbl->{data}->[$indexOne]->[$indexTwo] = $apsp->path_length($rxns->[$i]->id(), $rxns->[$j]->id());
							}
							if (!defined($tbl->{data}->[$indexOne]->[$indexTwo])) {
							    $tbl->{data}->[$indexOne]->[$indexTwo] = -1;
							}
						}
					}
				}
			}
		}
	} else {
		my $cpds = $self->modelcompounds();
		$tbl->{headings}->[0] = "Cpd";
		for (my $i=0;$i < @{$cpds}; $i++) {
			$tbl->{headings}->[$i+1] = $cpds->[$i]->id();
			$tbl->{data}->[$i]->[0] = $cpds->[$i]->id();
			for (my $j=0;$j < @{$cpds}; $j++) {
				if ($i == $j) {
					$tbl->{data}->[$i]->[$j+1] = 0;
				} else {
					$tbl->{data}->[$i]->[$j+1] =  $apsp->path_length($cpds->[$i]->id(), $cpds->[$j]->id());
					if (!defined($tbl->{data}->[$i]->[$j+1])) {
						$tbl->{data}->[$i]->[$j+1] = -1;
					}
				}
			}
		}
	}
	return $tbl;
}

=head3 searchForCompound

Definition:
	ModelSEED::MS::ModelCompound ModelSEED::MS::Model->searchForCompound(string:id);
Description:
	Search for compound in model
	
=cut

sub searchForCompound {
    my $self = shift;
    my $id = shift;
    my $compartment = shift;
    my $index = shift;
    if ($id =~ m/^(.+)\[([a-z]+)(\d*)]$/) {
    	$id = $1;
    	$compartment = $2;
    	$index = $3;
    }
    if (!defined($compartment)) {
    	$compartment = "c";
    }
    if (!defined($index)) {
    	$index = 0;
    }
    my $cpd = $self->biochemistry()->searchForCompound($id);
    if (!defined($cpd)) {
    	return undef;
    }
    my $mdlcmp = $self->queryObject("modelcompartments",{label => $compartment.$index});
    if (!defined($mdlcmp)) {
    	return undef;
    }
    return $self->queryObject("modelcompounds",{
    	modelcompartment_uuid => $mdlcmp->uuid(),
    	compound_uuid => $cpd->uuid()
    });
}

=head3 searchForBiomass

Definition:
	ModelSEED::MS::Biomass ModelSEED::MS::Model->searchForBiomass(string:id);
Description:
	Search for biomass in model
	
=cut

sub searchForBiomass {
    my $self = shift;
    my $id = shift;
    my $obj = $self->queryObject("biomasses",{id => $id});
    if (!defined($obj)) {
    	$obj = $self->queryObject("biomasses",{name => $id});
    }
    return $obj;
}

=head3 searchForReaction

Definition:
	ModelSEED::MS::Biomass ModelSEED::MS::Model->searchForReaction(string:id);
Description:
	Search for reaction in model
	
=cut

sub searchForReaction {
    my $self = shift;
    my $id = shift;
    my $compartment = shift;
    my $index = shift;
    if ($id =~ m/^(.+)\[([a-z]+)(\d*)]$/) {
    	$id = $1;
    	$compartment = $2;
    	$index = $3;
    }
    if (!defined($compartment)) {
    	$compartment = "c";
    }
    if (!defined($index)) {
    	$index = 0;
    }
    my $reaction = $self->biochemistry()->searchForReaction($id);
    if (!defined($reaction)) {
    	return undef;
    }
    my $mdlcmp = $self->queryObject("modelcompartments",{label => $compartment.$index});
    if (!defined($mdlcmp)) {
    	return undef;
    }
    return $self->queryObject("modelreactions",{
    	modelcompartment_uuid => $mdlcmp->uuid(),
    	reaction_uuid => $reaction->uuid()
    });
}

sub __upgrade__ {
	my ($class,$version) = @_;
	if ($version eq "1") {
		return sub {
			my ($hash) = @_;
			if (defined($hash->{fbaFormulations})) {
				delete($hash->{fbaFormulations});
			}
			if (defined($hash->{gapfillingFormulations})) {
				delete($hash->{gapfillingFormulations});
			}
			if (defined($hash->{gapgenFormulations})) {
				delete($hash->{gapgenFormulations});
			}
			$hash->{__VERSION__} = 2;
			if (defined($hash->{parent}) && ref($hash->{parent}) eq "ModelSEED::Store") {#TODO KBaseStore
				my $parent = $hash->{parent};
				delete($hash->{parent});
				$parent->save_data("model/".$hash->{uuid},$hash,{schema_update => 1});
                $hash->{parent} = $parent;
			}
			return $hash;
		};
	} 
}

__PACKAGE__->meta->make_immutable;
1;
