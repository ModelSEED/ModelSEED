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
sub roleToReactions {
	my $self = shift;
	my $roleToRxn = [];
	my $complexes = {};
	my $rxns = $self->templateReactions();
	my $rolehash = {};
	for (my $i=0;$i<@{$rxns};$i++) {
		my $rxn = $rxns->[$i];
		my $cpxs = $rxn->complexes();
		for (my $j=0;$j < @{$cpxs};$j++) {
			my $cpx = $cpxs->[$j];
			if (!defined($complexes->{$cpx->uuid()})) {
				$complexes->{$cpx->uuid()} = {
					complex => $cpx->id(),
					name => $cpx->name(),
					reactions => []
				};
			}
			push(@{$complexes->{$cpx->uuid()}->{reactions}},{
				reaction => $rxn->reaction()->id(),
				direction => $rxn->direction(),
				compartment => $rxn->compartment()->id(),
				equation => $rxn->reaction()->definition()
			});	
			my $roles = $cpx->complexroles();
		    for (my $k=0; $k < @{$roles}; $k++) {
		    	my $role = $roles->[$k]->role();
		    	if (!defined($rolehash->{$role->uuid()})) {
		    		$rolehash->{$role->uuid()} = {
		    			role => $role->id(),
		    			name => $role->name(),
		    			complexes => []
		    		};
		    		push(@{$roleToRxn},$rolehash->{$role->uuid()});
		    	}
		    	my $found = 0;
		    	for (my $m=0; $m < @{$rolehash->{$role->uuid()}->{complexes}}; $m++) {
		    		if ($rolehash->{$role->uuid()}->{complexes}->[$m] eq $complexes->{$cpx->uuid()}) {
		    			$found = 1;
		    		}
		    	}
		    	if ($found == 0) {
		    		push(@{$rolehash->{$role->uuid()}->{complexes}},$complexes->{$cpx->uuid()});
		    	}
		    }
		}
	}
	return $roleToRxn;
}

sub adjustBiomass {
	my $self = shift;
    my $args = ModelSEED::utilities::args([], {
    	biomass => $self->templateBiomasses()->[0]->uuid(),
    	"new" => 0,
    	"delete" => 0,
		clearBiomassCompounds => 0,
		name => undef,
		type => undef,
		other => undef,
		protein => undef,
		dna => undef,
		rna => undef,
		cofactor => undef,
		energy => undef,
		cellwall => undef,
		lipid => undef,
		compoundsToAdd => [],
		compoundsToRemove => []
	});
	my $paramlist = [qw(name type other protein dna rna cofactor energy cellwall lipid compoundsToRemove compoundsToAdd)];
	my $bio;
	if (defined($args->{biomass})) {
		$bio = $self->searchForBiomass($args->{biomass});
	}
	if (!defined($bio)) {
		if ($args->{"new"} == 1) {
			$bio = $self->add("templateBiomasses",{
				name => $args->{name},
				type => $args->{type},
				other => $args->{other},
				protein => $args->{protein},
				dna => $args->{dna},
				rna => $args->{rna},
				cofactor => $args->{cofactor},
				energy => $args->{energy},
				cellwall => $args->{cellwall},
				lipid => $args->{lipid},
				templateBiomassComponents => []
			});
		} else {
			ModelSEED::utilities::error("Biomass ".$args->{biomass}." not found!");
		}	
	}
	if ($args->{"delete"} == 1) {
		$self->remove("templateBiomasses",$bio);
	}
	foreach my $param (@{$paramlist}) {
		$bio->$param($args->{$param});
	}
	
	
	


}

sub adjustReaction {
	my $self = shift;
    my $args = ModelSEED::utilities::args(["reaction"], {
    	compartment => "c",
    	direction => undef,
    	type => undef,
    	"new" => 0,
    	complexesToRemove => [],
    	complexesToAdd => [],
    	"delete" => 0,
    	clearComplexes => 0
    }, @_);
	my $bio = $self->biochemistry();
	my $rxn = $bio->searchForReaction($args->{reaction});
	ModelSEED::utilities::error("Specified reaction ".$args->{reaction}." not found!") unless(defined($rxn));
	my $cmp = $bio->searchForCompartment($args->{compartment});
	ModelSEED::utilities::error("Specified compartment ".$args->{compartment}." not found!") unless(defined($cmp));
	my $temprxn = $self->queryObjects("templateReactions",{
		compartment_uuid => $cmp->uuid(),
		reaction_uuid => $rxn->uuid()
	});
	if (!defined($temprxn)) {
		if (defined($args->{"new"}) && $args->{"new"} == 1) {
			$temprxn = ModelSEED::MS::TemplateReaction->new({
				compartment_uuid => $cmp->uuid(),
				reaction_uuid => $rxn->uuid()
			});
			$self->add("templateReactions",$temprxn);
		} else {
			ModelSEED::utilities::error("Specified template reaction not found and new reaction not specified!");
		}
	} elsif (defined($args->{"delete"}) && $args->{"delete"} == 1) {
		$self->remove("templateReactions",$temprxn);
		return $temprxn;
	}
	if (defined($args->{direction})) {
		$temprxn->direction($args->{direction});
	}
	if (defined($args->{type})) {
		$temprxn->type($args->{type});
	}
    if (defined($args->{clearComplexes}) && $args->{clearComplexes} == 1) {
		$temprxn->clearLinkArray("complexes");
	}
  	for (my $i=0; $i < @{$args->{complexesToRemove}}; $i++) {
  		my $cpx = $self->mapping()->searchForComplex($args->{complexesToRemove}->[$i]);
    	if (defined($cpx)) {
    		$temprxn->removeLinkArrayItem("complexes",$cpx);
    	}
   	}
    for (my $i=0; $i < @{$args->{complexesToAdd}}; $i++) {
    	my $cpx = $self->mapping()->searchForComplex($args->{complexesToAdd}->[$i]);
    	if (defined($cpx)) {
    		$temprxn->addLinkArrayItem("complexes",$cpx);
    	} else {
  			ModelSEED::utilities::error("Specified complex ".$args->{complexesToAdd}->[$i]." not found!");
  		}
   	}
   	return $temprxn;
}

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
	my $roleFeatures;
	my $features = $args->{annotation}->features();
	for (my $i=0; $i < @{$features}; $i++) {
		my $ftr = $features->[$i];
		my $ftrroles = $ftr->featureroles();
		for (my $j=0; $j < @{$ftrroles}; $j++) {
			my $ftrrole = $ftrroles->[$j];
			my $compartmentStr = $ftrrole->compartment();
			my $cmparray = [split(/[;\|]/,$compartmentStr)];
			for (my $k=0; $k < @{$cmparray}; $k++) {
				my $abbrev = $cmparray->[$k];
				if (length($cmparray->[$k]) > 1 && defined($cmpTranslation->{$cmparray->[$k]})) {
					$abbrev = $cmpTranslation->{$cmparray->[$k]};
				} elsif (length($cmparray->[$k]) > 1 && !defined($cmpTranslation->{$cmparray->[$k]})) {
					print STDERR "Compartment ".$cmparray->[$k]." not found!\n";
				}
				my $subroles = [split(/;/,$ftrrole->role()->searchname())];
				for (my $m=0; $m < @{$subroles}; $m++) {
					my $roles = $self->mapping()->searchForRoles($subroles->[$m]);
					for (my $n=0; $n < @{$roles};$n++) {
						push(@{$roleFeatures->{$roles->[$n]->uuid()}->{$abbrev}},$ftr);
					}
				}
			}
		}
	}
	for (my $i=0; $i < @{$rxns}; $i++) {
		my $rxn = $rxns->[$i];
		$rxn->addRxnToModel({
			role_features => $roleFeatures,
			model => $mdl
		});
	}
	my $bios = $self->templateBiomasses();
	for (my $i=0; $i < @{$bios}; $i++) {
		my $bio = $bios->[$i];
		$bio->addBioToModel({
			gc => $args->{annotation}->genomes()->[0]->gc(),
			model => $mdl
		});
	}
	return $mdl;
}

=head3 searchForBiomass

Definition:
	ModelSEED::MS::TemplateBiomass ModelSEED::MS::TemplateModel->searchForBiomass(string:id);
Description:
	Search for biomass in template model
	
=cut

sub searchForBiomass {
    my $self = shift;
    my $id = shift;
    my $obj = $self->queryObject("templateBiomasses",{uuid => $id});
    if (!defined($obj)) {
    	$obj = $self->queryObject("templateBiomasses",{name => $id});
    }
    return $obj;
}

__PACKAGE__->meta->make_immutable;
1;
