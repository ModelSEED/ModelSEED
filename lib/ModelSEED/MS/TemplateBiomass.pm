########################################################################
# ModelSEED::MS::TemplateBiomass - This is the moose object corresponding to the TemplateBiomass object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2013-04-26T05:53:23
########################################################################
use strict;
use ModelSEED::MS::DB::TemplateBiomass;
package ModelSEED::MS::TemplateBiomass;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::DB::TemplateBiomass';
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
sub addBioToModel {
    my $self = shift;
	my $args = ModelSEED::utilities::args(["annotation","model"],{}, @_);
	my $mdl = $args->{model};
	my $anno = $args->{annotation};
	my $biochem = $mdl->biochemistry();
	my $gc = $anno->genomes()->[0]->gc();
	if ($gc > 1) {
		$gc = 0.01*$gc;	
	}
	if ($gc > 1) {
		$gc = 0.5;	
	} 
	my $count = @{$mdl->biomasses()};
	my $bio = $mdl->add("biomasses",{
		name => $self->name()." auto biomass",
		id => "bio".($count+1)
	});
	my $list = ["dna","rna","protein","lipid","cellwall","cofactor","energy","other"];
	for (my $i=0; $i < @{$list}; $i++) {
		my $function = $list->[$i];
		$bio->$function($self->$function());
	}
	my $comps = $self->templateBiomassComponents();
	my $classifiers;
	my $compoundHash;
	#Calculating the mols of nucleotides present based on gc
	my $includedComps = [];
	my $classCounts = {};
	my $classMol = {};
	my $classMW = {};
	my $classMassSplitMol = {};
	my $classMassFractionMoles = {};
	my $classMolSplitMW = {};
	my $classMassSplitFraction = {};
	my $classMolSplitFraction = {};
	my $classMassSplitCount = {};
	my $classMolSplitCount = {};
	my $classMassFraction = {};
	my $classMolFraction = {};
	my $classHash = {};
	#Identifying included compounds and adding up components and mass in each class
	for (my $i=0; $i < @{$comps}; $i++) {
		my $comp = $comps->[$i];
		my $include = 0;
		if ($comp->universal() == 1) {
			$include = 1;
		} else {	
			if (!defined($classifiers->{$comp->classifier_uuid()})) {
				my $class = $comp->classifier()->classifyAnnotation({
					annotation => $args->{annotation}
				});
				$classifiers->{$comp->classifier_uuid()} = $class->uuid();
			}
			if ($classifiers->{$comp->classifier_uuid()} eq $comp->classifierClassification_uuid()) {
				$include = 1;	
			}
		}
		if ($include == 1) {
			$classHash->{$comp->class()} = 1;
			push(@{$includedComps},$comp);
			if ($comp->coefficientType() eq "MOLFRACTION") {
				if (!defined($classMolFraction->{$comp->class()})) {
					$classMolFraction->{$comp->class()} = 0;
				}
				$classMolFraction->{$comp->class()} += -1*$comp->coefficient();
				if (defined($comp->compound()->mass()) && $comp->compound()->mass() > 0) {
					if (!defined($classMW->{$comp->class()})) {
						$classMW->{$comp->class()} = 0;
					}
					$classMW->{$comp->class()} += -1*$comp->compound()->mass()*$comp->coefficient();
				}
			} elsif ($comp->coefficientType() eq "MASSFRACTION") {
				if (!defined($comp->compound()->mass()) || $comp->compound()->mass() == 0) {
					ModelSEED::utilities::error("Biomass template with MASSFRACTION of compound with no mass.");
				}
				if (!defined($classMassFraction->{$comp->class()})) {
					$classMassFraction->{$comp->class()} = 0;
				}
				$classMassFraction->{$comp->class()} += -1*$comp->coefficient();
				my $class = $comp->class();
				if (!defined($classMassFractionMoles->{$comp->class()})) {
					$classMassFractionMoles->{$comp->class()} = 0;
				}
				$classMassFractionMoles->{$comp->class()} += -1*$comp->coefficient()*$self->$class()/$comp->compound()->mass();
			} elsif ($comp->coefficientType() eq "AT") {
				if (!defined($classMolFraction->{$comp->class()})) {
					$classMolFraction->{$comp->class()} = 0;
				}
				$classMolFraction->{$comp->class()} += (1-$gc)/2;
				if (defined($comp->compound()->mass()) && $comp->compound()->mass() > 0) {
					if (!defined($classMW->{$comp->class()})) {
						$classMW->{$comp->class()} = 0;
					}
					$classMW->{$comp->class()} += $comp->compound()->mass()*(1-$gc)/2;
				}
			} elsif ($comp->coefficientType() eq "GC") {
				if (!defined($classMolFraction->{$comp->class()})) {
					$classMolFraction->{$comp->class()} = 0;
				}
				$classMolFraction->{$comp->class()} += $gc/2;
				if (defined($comp->compound()->mass()) && $comp->compound()->mass() > 0) {
					if (!defined($classMW->{$comp->class()})) {
						$classMW->{$comp->class()} = 0;
					}
					$classMW->{$comp->class()} += $comp->compound()->mass()*$gc/2;
				}
			} elsif ($comp->coefficientType() eq "MULTIPLIER") {
				#DO NOTHING
			} elsif ($comp->coefficientType() eq "EXACT") {
				#DO NOTHING
			} elsif ($comp->coefficientType() eq "MOLSPLIT") {
				if (!defined($classMolSplitCount->{$comp->class()})) {
					$classMolSplitCount->{$comp->class()} = 0;
				}
				$classMolSplitCount->{$comp->class()}++;
				if (defined($comp->compound()->mass()) && $comp->compound()->mass() > 0) {
					if (!defined($classMolSplitMW->{$comp->class()})) {
						$classMolSplitMW->{$comp->class()} = 0;
					}
					$classMolSplitMW->{$comp->class()} += $comp->compound()->mass();
				}
			} elsif ($comp->coefficientType() eq "MASSSPLIT") {
				if (!defined($comp->compound()->mass()) || $comp->compound()->mass() == 0) {
					ModelSEED::utilities::error("Biomass template with MASSFRACTION of compound with no mass.");
				}
				if (!defined($classMassSplitCount->{$comp->class()})) {
					$classMassSplitCount->{$comp->class()} = 0;
				}
				$classMassSplitCount->{$comp->class()}++;
				my $class = $comp->class();
				if (!defined($classMassSplitMol->{$comp->class()})) {
					$classMassSplitMol->{$comp->class()} = 0;
				}
				$classMassSplitMol->{$comp->class()} += $self->$class()/$comp->compound()->mass();
			}
		}
	}
	foreach my $class (keys(%{$classHash})) {
		if (!defined($classMassFraction->{$class})) {
			$classMassFraction->{$class} = 0;
		}
		if (!defined($classMolFraction->{$class})) {
			$classMolFraction->{$class} = 0;
		}
		if (!defined($classMW->{$class})) {
			$classMW->{$class} = 0;
		}
		if (!defined($classMol->{$class})) {
			$classMol->{$class} = 0;
		}
		if (!defined($classMolSplitCount->{$class})) {
			$classMolSplitCount->{$class} = 0;
			$classMolSplitMW->{$class} = 0;
		}
		if (!defined($classMassSplitCount->{$class})) {
			$classMassSplitCount->{$class} = 0;
			$classMassSplitMol->{$class} = 0;
		}
		my $totalSplt = $classMolSplitCount->{$class}+$classMassSplitCount->{$class};
		my $mass = (1-$classMassFraction->{$class})*$self->$class();
		if ($mass > 0) {
			my $remainingMolFraction = (1-$classMolFraction->{$class});
			if ($totalSplt > 0) {
				my $massSplitMolFraction = $remainingMolFraction*$classMassSplitCount->{$class}/$totalSplt;
				my $molSplitMolFraction = $remainingMolFraction*$classMolSplitCount->{$class}/$totalSplt;
				$classMW->{$class} += $molSplitMolFraction*$classMolSplitMW->{$class}/$classMolSplitCount->{$class};
				if ($classMassSplitCount->{$class} > 0) {
					$classMW->{$class} += $massSplitMolFraction*$self->$class()/($classMassSplitMol->{$class}/$classMassSplitCount->{$class});
				}
				$classMassSplitFraction->{$class} = $massSplitMolFraction;
				$classMolSplitFraction->{$class} = $molSplitMolFraction;
			}
			if ($classMW->{$class} > 0) {
				$classMol->{$class} = $mass/$classMW->{$class};
			} else {
				$classMol->{$class} = 1;
			}
		}
	}
	#Computing actual coefficients	
	for (my $i=0; $i < @{$includedComps}; $i++) {
		my $comp = $includedComps->[$i];
		my $coef = $comp->coefficient();
		my $class = $comp->class();
		if ($comp->coefficientType() eq "MOLFRACTION") {
			$coef = $coef*$classMol->{$comp->class()}*1000;
		} elsif ($comp->coefficientType() eq "MASSFRACTION") {
			my $class = $comp->class();
			$coef = $coef*$self->$class()/$comp->compound()->mass()*1000;
		} elsif ($comp->coefficientType() eq "AT") {
			$coef = $coef*$classMol->{$comp->class()}*(1-$gc)/2*1000;
		} elsif ($comp->coefficientType() eq "GC") {
			$coef = $coef*$gc*$classMol->{$comp->class()}/2*1000;
		} elsif ($comp->coefficientType() eq "MULTIPLIER") {
			$coef = $coef*$self->$class();
		} elsif ($comp->coefficientType() eq "EXACT") {
			$coef = $coef;
		} elsif ($comp->coefficientType() eq "MOLSPLIT") {
			$coef = $coef*$classMol->{$comp->class()}*$classMolSplitFraction->{$comp->class()}*1000/$classMolSplitCount->{$comp->class()};			
		} elsif ($comp->coefficientType() eq "MASSSPLIT") {
			$coef = $coef*$self->$class()*$classMassSplitFraction->{$comp->class()}/$classMassSplitCount->{$comp->class()}/$comp->compound()->mass()*1000;
		}
		#Adding compound to total biomass compound hash
		my $cpd = $comp->compound();
		if (!defined($compoundHash->{$cpd->uuid()}->{$comp->compartment_uuid()})) {
			$compoundHash->{$cpd->uuid()}->{$comp->compartment_uuid()} = 0;
		}
		$compoundHash->{$cpd->uuid()}->{$comp->compartment_uuid()} += $coef;
		#Adding linked compounds to total biomass compound hash
		my $cpds = $comp->linkedCompounds();
		for (my $j=0; $j < @{$cpds}; $j++) {
			$cpd = $cpds->[$j];
			if (!defined($compoundHash->{$cpd->uuid()}->{$comp->compartment_uuid()})) {
				$compoundHash->{$cpd->uuid()}->{$comp->compartment_uuid()} = 0;
			}
			$compoundHash->{$cpd->uuid()}->{$comp->compartment_uuid()} += $coef*$comp->linkCoefficients()->[$j];
		}
	}
	#Setting biomass components
	foreach my $cpd_uuid (keys(%{$compoundHash})) {
		foreach my $cmp_uuid (keys(%{$compoundHash->{$cpd_uuid}})) {
			if ($compoundHash->{$cpd_uuid}->{$cmp_uuid} != 0) {
				my $cpd = $biochem->getObject("compounds",$cpd_uuid);
				my $cmp = $biochem->getObject("compartments",$cmp_uuid);
				my $mdlcmp = $mdl->addCompartmentToModel({compartment => $cmp,pH => 7,potential => 0,compartmentIndex => 0});
				my $mdlcpd = $mdl->addCompoundToModel({
					compound => $cpd,
					modelCompartment => $mdlcmp,
				});
				$bio->add("biomasscompounds",{
					modelcompound_uuid => $mdlcpd->uuid(),
					coefficient => $compoundHash->{$cpd_uuid}->{$cmp_uuid}
				});
			}
		}
	}
}

__PACKAGE__->meta->make_immutable;
1;
