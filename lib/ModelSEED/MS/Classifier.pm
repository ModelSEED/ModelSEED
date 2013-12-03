########################################################################
# ModelSEED::MS::Classifier - This is the moose object corresponding to the Classifier object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-11-15T18:17:11
########################################################################
use strict;
use ModelSEED::MS::DB::Classifier;
package ModelSEED::MS::Classifier;
use Moose;
use namespace::autoclean;
use ModelSEED::utilities;
extends 'ModelSEED::MS::DB::Classifier';
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

=head3 classifyAnnotation

Definition:
	string ModelSEED::MS::Classifier->classifyAnnotation({
		annotation => ModelSEED::MS::Annotation
	});
Description:
	Classifies the input annotation object

=cut

sub classifyAnnotation {
    my $self = shift;
	my $args = ModelSEED::utilities::args(["annotation"],{},@_);
	my $anno = $args->{annotation};
	my $features = $anno->features();
	my $scores = {};
	my $classes = $self->classifierClassifications();
	my $sum = 0;
	foreach my $class (@{$classes}) {
		$scores->{$class->uuid()} = 0;
		$sum += $class->populationProbability();
	}
	for (my $i=0; $i < @{$features}; $i++) {
		my $feature = $features->[$i];
		my $roles = $feature->featureroles();
		foreach my $role (@{$roles}) {
			my $classrole = $self->queryObject("classifierRoles",{role_uuid => $role->role()->uuid()});
			if (defined($classrole)) {
				my $roleclasses = $classrole->classifications();
				foreach my $roleclass (@{$roleclasses}) {
					$scores->{$roleclass->uuid()} += $classrole->classificationProbabilities()->{$roleclass->uuid()};
				}
			}
		}
	}
	my $largest;
	my $largestClass;
	foreach my $class (@{$classes}) {
		$scores->{$class->uuid()} += log($class->populationProbability()/$sum);
		if (!defined($largest)) {
			$largest = $scores->{$class->uuid()};
			$largestClass = $class;
		} elsif ($largest > $scores->{$class->uuid()}) {
			$largest = $scores->{$class->uuid()};
			$largestClass = $class;
		}
	}
	return $largestClass;
}

=head3 classifyRoles

Definition:
	string ModelSEED::MS::Classifier->classifyRoles({
		functions => {}
	});
Description:
	Classifies based on input functions with relative abundance

=cut

sub classifyRoles {
    my $self = shift;
	my $args = ModelSEED::utilities::args(["functions"],{},@_);
	my $scores = {};
	my $classes = $self->classifierClassifications();
	my $sum = 0;
	foreach my $class (@{$classes}) {
		$scores->{$class->uuid()} = 0;
		$sum += $class->populationProbability();
	}
	foreach my $function (keys(%{$args->{functions}})) {
		my $searchrole = ModelSEED::MS::Utilities::GlobalFunctions::convertRoleToSearchRole($function);
		my $subroles = [split(/;/,$searchrole)];
		for (my $m=0; $m < @{$subroles}; $m++) {
			my $roles = $self->mapping()->searchForRoles($subroles->[$m]);
			for (my $n=0; $n < @{$roles};$n++) {
				my $classrole = $self->queryObject("classifierRoles",{role_uuid => $roles->[$n]->uuid()});
				if (defined($classrole)) {
					my $roleclasses = $classrole->classifications();
					foreach my $roleclass (@{$roleclasses}) {
						$scores->{$roleclass->uuid()} += $args->{functions}->{$function}*$classrole->classificationProbabilities()->{$roleclass->uuid()};
					}
				}
			}
		}		
	}
	my $largest;
	my $largestClass;
	foreach my $class (@{$classes}) {
		$scores->{$class->uuid()} += log($class->populationProbability()/$sum);
		if (!defined($largest)) {
			$largest = $scores->{$class->uuid()};
			$largestClass = $class;
		} elsif ($largest > $scores->{$class->uuid()}) {
			$largest = $scores->{$class->uuid()};
			$largestClass = $class;
		}
	}
	return $largestClass;
}

__PACKAGE__->meta->make_immutable;
1;
