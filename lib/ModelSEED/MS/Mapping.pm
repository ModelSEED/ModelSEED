########################################################################
# ModelSEED::MS::Mapping - This is the moose object corresponding to the Mapping object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-03-26T23:22:35
########################################################################
use strict;
use LWP::Simple qw(getstore);
use File::Temp qw(tempfile);
use ModelSEED::MS::Classifier;
use ModelSEED::MS::DB::Mapping;
package ModelSEED::MS::Mapping;
use Class::Autouse qw(
    ModelSEED::Client::SAP
);
use ModelSEED::MS::RoleSet;
use Moose;
use ModelSEED::utilities;
use namespace::autoclean;
extends 'ModelSEED::MS::DB::Mapping';
#***********************************************************************************************************
# ADDITIONAL ATTRIBUTES:
#***********************************************************************************************************
has roleReactionHash => ( is => 'rw', isa => 'HashRef',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildroleReactionHash' );
has typeClassifier => ( is => 'rw', isa => 'ModelSEED::MS::Classifier',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildtypeClassifier' );
has roleComplexHash => ( is => 'rw', isa => 'HashRef',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildroleComplexHash' );

#***********************************************************************************************************
# BUILDERS:
#***********************************************************************************************************
sub _buildroleReactionHash {
	my ($self) = @_;
	my $roleReactionHash;
	my $complexes = $self->complexes();
	for (my $i=0; $i < @{$complexes}; $i++) {
		my $complex = $complexes->[$i];
		my $cpxroles = $complex->complexroles();
		my $cpxrxns = $complex->reactions();
		for (my $j=0; $j < @{$cpxroles}; $j++) {
			my $role = $cpxroles->[$j]->role();
			for (my $k=0; $k < @{$cpxrxns}; $k++) {
				$roleReactionHash->{$role->uuid()}->{$cpxrxns->[$k]->uuid()} = $cpxrxns->[$k];
			}
		}
	}
	return $roleReactionHash;
}
sub _buildroleComplexHash {
	my ($self) = @_;
	my $roleComplexHash = {};
	my $complexes = $self->complexes();
	for (my $i=0; $i < @{$complexes}; $i++) {
		my $complex = $complexes->[$i];
		my $cpxroles = $complex->complexroles();
		for (my $j=0; $j < @{$cpxroles}; $j++) {
			my $role = $cpxroles->[$j]->role();
			$roleComplexHash->{$role->uuid()}->{$complex->uuid()} = $complex;
		}
	}
	return $roleComplexHash;
}
sub _buildtypeClassifier {
    my ($self) = @_;
    my $class = $self->queryObject("mappingClassifiers",{
		name => "GramStain",
		type => "Bayesian"
	});
	if (defined($class)) {
		return $class->classifier();
	}
    my ($fh1, $classifierFile) = File::Temp::tempfile();
    close($fh1);
    my $status = LWP::Simple::getstore("http://bioseed.mcs.anl.gov/~chenry/ModelSEED/classifier.txt", $classifierFile);
    die "Unable to fetch from model_seed\n" unless($status == 200);        
	my $exchange_factory = ModelSEED::MS::Factories::ExchangeFormatFactory->new();
	my ($classifier,$mapping) = $exchange_factory->buildClassifier({
		filename => $classifierFile,
		name => "GramStrain",
		mapping => $self
	});
	return $classifier;
}

#***********************************************************************************************************
# CONSTANTS:
#***********************************************************************************************************

#***********************************************************************************************************
# FUNCTIONS:
#***********************************************************************************************************
=head3 mappingToTemplateModel
Definition:
	ModelSEED::MS::ModelTemplate = ModelSEED::MS::Mapping->mappingToTemplateModel();
Description:
	Generates a model template from the mapping data

=cut

sub mappingToTemplateModel {
	my ($self,$args) = @_;
	$args = ModelSEED::utilities::args(["name"], {
		type => "GenomeScale",
		domain => "Bacteria"
	}, $args);
	my $ModelTemplate = ModelSEED::MS::ModelTemplate->new({
		name => $args->{name},
		modelType => $args->{type},
		domain => $args->{domain},
		mapping_uuid => $self->uuid()
	});
	my $cpxs = $self->complexes();
	my $rxnHash;
	my $cmp = $self->biochemistry()->queryObject("compartments",{
		id => "c"
	});
	for (my $i=0; $i < @{$cpxs}; $i++) {
		my $cpx = $cpxs->[$i];
		my $rxns = $cpx->reactions();
		for (my $j=0; $j < @{$rxns}; $j++) {
			my $rxn = $rxns->[$j];
			if (!defined($rxnHash->{$rxn->uuid()})) {
				$rxnHash->{$rxn->uuid()} = {
					reaction_uuid => $rxn->uuid(),
					compartment_uuid => $cmp->uuid(),
					complex_uuids => [],
					direction => $rxn->thermoReversibility(),
					type => "conditional"
				};
			}
			push(@{$rxnHash->{$rxn->uuid()}->{complex_uuids}},$cpx->uuid());
		}
	}
	my $rxns = $self->universalReactions();
	for (my $i=0; $i < @{$rxns}; $i++) {
		my $rxn = $rxns->[$i]->reaction();
		if ($rxns->[$i]->type() eq "spontaneous") {
			if (!defined($rxnHash->{$rxn->uuid()})) {
				$rxnHash->{$rxn->uuid()} = {
					reaction_uuid => $rxn->uuid(),
					compartment_uuid => $cmp->uuid(),
					complex_uuids => [],
					direction => $rxn->thermoReversibility(),
					type => "spontaneous"
				};
			} else {
				$rxnHash->{$rxn->uuid()}->{type} = "spontaneous";
			}
		} else {
			if (!defined($rxnHash->{$rxn->uuid()})) {
				$rxnHash->{$rxn->uuid()} = {
					reaction_uuid => $rxn->uuid(),
					compartment_uuid => $cmp->uuid(),
					complex_uuids => [],
					direction => $rxn->thermoReversibility(),
					type => "universal"
				};
			} else {
				$rxnHash->{$rxn->uuid()}->{type} = "universal";
			}
		}
	}
	foreach my $rxnuuid (keys(%{$rxnHash})) {
		$ModelTemplate->add("templateReactions",$rxnHash->{$rxnuuid});
	}
	my $bios = $self->biomassTemplates();
	for (my $i=0; $i < @{$bios}; $i++) {
		my $bio = $bios->[$i];
		my $biomass = {
			name => "bio".($i+1),
			type => $bio->class(),
			other => 0,
			dna => $bio->dna(),
			rna => $bio->rna(),
			protein => $bio->protein(),
			lipid => $bio->cofactor(),
			cellwall => $bio->cofactor(),
			cofactor => $bio->cofactor(),
			energy => $bio->energy(),
			templateBiomassComponents => []
		};
		my $biocpds = $bio->biomassTemplateComponents();
		for (my $j=0; $j < @{$biocpds};$j++) {
			my $biocpd = $biocpds->[$j];
			push(@{$biomass->{templateBiomassComponents}},{
				class => $biocpd->class(),
				universal => 1,
				compound_uuid => $biocpd->compound_uuid(),
				compartment_uuid => $cmp->uuid(),
				coefficientType => $biocpd->coefficientType(),
				coefficient => $biocpd->coefficient(),
				linkCoefficients => [],
				linkedCompound_uuids => []
			});
		}
		$ModelTemplate->add("templateBiomasses",$biomass);
	}
	return $ModelTemplate;
}

=head3 searchForComplex
Definition:
	ModelSEED::MS::Complex = ModelSEED::MS::Mapping->searchForComplex(string);
Description:
	Searches for a complex by ID, name, or alias.

=cut

sub searchForComplex {
	my ($self,$id) = @_;
	#First search by exact alias match
	my $cpxobj = $self->getObjectByAlias("complexes",$id);
	#Next, search by name
	if (!defined($cpxobj)) {
		$cpxobj = $self->queryObject("complexes",{name => $id});
	}
	return $cpxobj;
}

=head3 searchForRole
Definition:
	ModelSEED::MS::Role = ModelSEED::MS::Mapping->searchForRole(string);
Description:
	Searches for a role by ID, name, or alias.

=cut

sub searchForRole {
	my ($self,$id) = @_;
	#First search by exact alias match
	my $roleobj = $self->getObjectByAlias("roles",$id);
	#Next, search by name
	if (!defined($roleobj)) {
		$roleobj = $self->queryObject("roles",{name => $id});
	}
	if (!defined($roleobj)) {
		$roleobj = $self->queryObject("roles",{searchname => $id});
	}
	return $roleobj;
}

=head3 searchForRoleSet
Definition:
	ModelSEED::MS::RoleSet = ModelSEED::MS::Mapping->searchForRoleSet(string);
Description:
	Searches for a roleset by ID, name, or alias.

=cut

sub searchForRoleSet {
	my ($self,$id) = @_;
	#First search by exact alias match
	my $ssobj = $self->getObjectByAlias("rolesets",$id);
	#Next, search by name
	if (!defined($ssobj)) {
		$ssobj = $self->queryObject("rolesets",{name => $id});
	}
	return $ssobj;
}

=head3 buildSubsystemRoleSets

=cut

sub buildSubsystemRoleSets {
    my ($self) = @_;
    # get subsystems
    my $SAP = ModelSEED::Client::SAP->new();

}

=head3 buildSubsystemReactionSets

Definition:
	void ModelSEED::MS::Mapping->buildSubsystemReactionSets({});
Description:
	Uses the reaction->role mappings to place reactions into reactions sets based on subsystem

=cut

sub buildSubsystemReactionSets {
    my $self = shift;
    my $args = ModelSEED::utilities::args([], {}, @_);
	my $subsystemHash;
	my $subsystemRoles;
	#First, placing all roles in subsystems into a hash
	for (my $i=0; $i < @{$self->rolesets()}; $i++) {
		my $roleset = $self->rolesets()->[$i];
		if ($roleset->type() eq "Subsystem") {
			for (my $j=0; $j < @{$roleset->roles()}; $j++) {
				my $role = $roleset->roles()->[$j];
				$subsystemRoles->{$role->name()}->{$roleset->name()} = 1;
			}
		}
	}
	#Next, placing reactions in subsystems based on the roles they are mapped to
	for (my $i=0; $i < @{$self->complexes()}; $i++) {
		my $cpx = $self->complexes()->[$i];
		#Identifying all subsystems that each complex is involved in
		my $cpxsubsys;
		for (my $j=0; $j < @{$cpx->complexroles()}; $j++) {
			my $role = $cpx->complexroles()->[$j]->role();
			if (defined($subsystemRoles->{$role->name()})) {
				foreach my $ss (keys(%{$subsystemRoles->{$role->name()}})) {
					$cpxsubsys->{$ss} = 1;
				}
			}
		}
	}
}

sub adjustComplex {
	my $self = shift;
    my $args = ModelSEED::utilities::args(["id"], {
    	name => undef,
    	clearRoles => 0,
    	rolesToRemove => [],
    	rolesToAdd => [],
    	"delete" => 0
    }, @_);
	my $cpx;
	if ($args->{id} eq "new") {
		my $id = ModelSEED::utilities::get_new_id("mscpx.");
		$cpx = ModelSEED::MS::Complex->new({
			name => $id
		});
		$self->addAlias({
  			attribute => "complexes",
  			aliasName => "ModelSEED",
  			alias => $id,
  			uuid => $cpx->uuid()
  		});
  		$self->add("complexes",$cpx);
	} else {
		$cpx = $self->searchForComplex($args->{id});
	}
	ModelSEED::utilities::error("Specified complex not found!") unless(defined($cpx));
	if (defined($args->{"delete"}) && $args->{"delete"} == 1) {
		$self->remove("complexes",$cpx);
		return $cpx;
	}
	if (defined($args->{name})) {
		$cpx->name($args->{name});
	}
    if (defined($args->{clearRoles}) && $args->{clearRoles} == 1) {
		$cpx->complexroles([]);
	}
  	for (my $i=0; $i < @{$args->{rolesToRemove}}; $i++) {
  		my $role = $args->{rolesToRemove}->[$i];
   		my $roleobj = $self->searchForRole($role);
   		if (defined($roleobj)) {
   			my $cpxroles = $cpx->complexroles();
   			for (my $i=0; $i < @$cpxroles; $i++) {
   				if ($cpxroles->[$i]->role_uuid() eq $roleobj->uuid()) {
   					$cpx->remove("complexroles",$cpxroles->[$i]);
   					$cpxroles = $cpx->complexroles();
   					$i--;
   				}
   			}
   		}
   	}
    for (my $i=0; $i < @{$args->{rolesToAdd}}; $i++) {
    	my $role = $args->{rolesToAdd}->[$i]->[0];
    	my $roleobj = $self->searchForRole($role);
    	if (defined($roleobj)) {
    		my $cpxroles = $cpx->complexroles();
   			my $cpxrole;
   			for (my $i=0; $i < @$cpxroles; $i++) {
    			if ($cpxroles->[$i]->role_uuid() eq $roleobj->uuid()) {
    				$cpxrole = $cpxroles->[$i];
    				last;
    			}
   			}
   			if (!defined($cpxrole)) {
   				my $newCpxRole = {
	    			role_uuid => $roleobj->uuid()
	    		};
	    		$cpxrole = $cpx->add("complexroles",$newCpxRole);
   			}
   			if (defined($args->{rolesToAdd}->[$i]->[1])) {
   				$cpxrole->optional($args->{rolesToAdd}->[$i]->[1]);
   			}
    		if (defined($args->{rolesToAdd}->[$i]->[3])) {
   				$cpxrole->type($args->{rolesToAdd}->[$i]->[3]);
   			}
    		if (defined($args->{rolesToAdd}->[$i]->[1])) {
   				$cpxrole->triggering($args->{rolesToAdd}->[$i]->[1]);
   			}
    	} else {
  			print "Role ".$args->{rolesToAdd}->[$i]." not found!\n";
  		}
   	}
   	return $cpx;
}

sub adjustRole {
	my $self = shift;
    my $args = ModelSEED::utilities::args(["id"], {
    	name => undef,
    	seedfeature => undef,
    	aliasToAdd => [],
    	aliasToRemove => [],
    	"delete" => 0
    }, @_);
	my $role;
	if ($args->{id} eq "new") {
		my $id = ModelSEED::utilities::get_new_id("msfr.");
		$role = ModelSEED::MS::Role->new({
			name => $id
		});
		$self->addAlias({
  			attribute => "roles",
  			aliasName => "ModelSEED",
  			alias => $id,
  			uuid => $role->uuid()
  		});
  		$self->add("roles",$role);
	} else {
		$role = $self->searchForRole($args->{id});
	}
	ModelSEED::utilities::error("Specified role not found!") unless(defined($role));
	if (defined($args->{"delete"}) && $args->{"delete"} == 1) {
		$self->remove("roles",$role);
		return $role;
	}
	if (defined($args->{name})) {
		$role->name($args->{name});
	}
	if (defined($args->{seedfeature})) {
		$role->seedfeature($args->{seedfeature});
	}
  	for (my $i=0; $i < @{$args->{aliasToAdd}}; $i++) {
  		$self->addAlias({
  			attribute => "roles",
  			aliasName => "name",
  			alias => $args->{aliasToAdd}->[$i],
  			uuid => $role->uuid()
  		});
   	}
   	for (my $i=0; $i < @{$args->{aliasToRemove}}; $i++) {
  		$self->removeAlias({
  			attribute => "roles",
  			aliasName => "name",
  			alias => $args->{aliasToRemove}->[$i],
  			uuid => $role->uuid()
  		});
   	}
   	return $role;
}

sub adjustRoleset {
	my $self = shift;
    my $args = ModelSEED::utilities::args(["id"], {
    	name => undef,
    	class => undef,
    	subclass => undef,
    	type => undef,
    	rolesToAdd => [],
    	rolesToRemove => [],
    	clearRoles => 0,
    	"delete" => 0
    }, @_);
	my $ss;
	if ($args->{id} eq "new") {
		my $id = ModelSEED::utilities::get_new_id("msrs.");
		$ss = ModelSEED::MS::RoleSet->new({
			name => $id
		});
		$self->addAlias({
  			attribute => "rolesets",
  			aliasName => "ModelSEED",
  			alias => $id,
  			uuid => $ss->uuid()
  		});
  		$self->add("rolesets",$ss);
	} else {
		$ss = $self->searchForRoleSet($args->{id});
	}
	ModelSEED::utilities::error("Specified roleset not found!") unless(defined($ss));
	if (defined($args->{"delete"}) && $args->{"delete"} == 1) {
		$self->remove("rolesets",$ss);
		return $ss;
	}
	if (defined($args->{name})) {
		$ss->name($args->{name});
	}
	if (defined($args->{class})) {
		$ss->class($args->{class});
	}
	if (defined($args->{subclass})) {
		$ss->subclass($args->{subclass});
	}
	if (defined($args->{type})) {
		$ss->type($args->{type});
	}
	if (defined($args->{clearRoles}) && $args->{clearRoles} == 1) {
		$ss->clearLinkArray("roles");
	}
  	for (my $i=0; $i < @{$args->{rolesToAdd}}; $i++) {
  		my $role = $self->searchForRole($args->{rolesToAdd}->[$i]);
  		if (defined($role)) {
  			$ss->addLinkArrayItem("roles",$role);
  		} else {
  			print "Role ".$args->{rolesToAdd}->[$i]." not found!\n";
  		}
   	}
   	for (my $i=0; $i < @{$args->{rolesToRemove}}; $i++) {
  		my $role = $self->searchForRole($args->{rolesToRemove}->[$i]);
  		if (defined($role)) {
  			$ss->removeLinkArrayItem("roles",$role);
  		}
   	}
   	return $ss;
}


sub __upgrade__ {
	my ($class,$version) = @_;
	if ($version == 1) {
		return sub {
			my ($hash) = @_;
			print "Upgrading mapping from v1 to v2!\n";
			if (defined($hash->{rolesets})) {
				foreach my $roleset (@{$hash->{rolesets}}) {
					if (defined($roleset->{rolesetroles})) {
						foreach my $rolesetrole (@{$roleset->{rolesetroles}}) {
							if (defined($rolesetrole->{role_uuid})) {
								push(@{$roleset->{role_uuids}},$rolesetrole->{role_uuid});
							}
						}
					}
				}
			}
			if (defined($hash->{complexes})) {
				foreach my $complex (@{$hash->{complexes}}) {
					if (defined($complex->{complexreactions})) {
						foreach my $complexreaction (@{$complex->{complexreactions}}) {
							if (defined($complexreaction->{reaction_uuid})) {
								push(@{$complex->{reaction_uuids}},$complexreaction->{reaction_uuid});
							}
						}
					}
				}
			}
			$hash->{__VERSION__} = 2;
			if (defined($hash->{parent}) && ref($hash->{parent}) eq "ModelSEED::Store") {#TODO KBaseStore
				my $parent = $hash->{parent};
				delete($hash->{parent});
				$parent->save_data("mapping/".$hash->{uuid},$hash,{schema_update => 1});
				$hash->{parent} = $parent;
			}
			return $hash;
		};
	}
	
}

__PACKAGE__->meta->make_immutable;
1;
