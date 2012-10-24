########################################################################
# ModelSEED::MS::Biochemistry - This is the moose object corresponding to the Biochemistry object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-03-26T23:22:35
########################################################################
use strict;
use ModelSEED::MS::DB::Biochemistry;
use ModelSEED::MS::BiochemistryStructures;
package ModelSEED::MS::Biochemistry;
use Moose;
use ModelSEED::utilities qw ( args verbose );
use namespace::autoclean;
extends 'ModelSEED::MS::DB::Biochemistry';
#***********************************************************************************************************
# ADDITIONAL ATTRIBUTES:
#***********************************************************************************************************
has definition => ( is => 'rw', isa => 'Str',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_builddefinition' );
has dataDirectory => ( is => 'rw', isa => 'Str',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_builddataDirectory' );
has reactionRoleHash => ( is => 'rw', isa => 'HashRef',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildreactionRoleHash' );

#***********************************************************************************************************
# BUILDERS:
#***********************************************************************************************************
sub _builddefinition {
	my ($self) = @_;
	return $self->createEquation({format=>"name",hashed=>0});
}
sub _builddataDirectory {
	my ($self) = @_;
	my $config = ModelSEED::Configuration->new();
	if (defined($config->user_options()->{MFATK_CACHE})) {
		return $config->user_options()->{MFATK_CACHE}."/";
	}
	return ModelSEED::utilities::MODELSEEDCORE()."/data/";
}
sub _buildreactionRoleHash {
	my ($self) = @_;
	my $hash;
	my $complexes = $self->mapping()->complexes();
	for (my $i=0; $i < @{$complexes}; $i++) {
		my $complex = $complexes->[$i];
		my $cpxroles = $complex->complexroles();
		my $cpxrxns = $complex->reaction_uuids();
		for (my $j=0; $j < @{$cpxroles}; $j++) {
			my $role = $cpxroles->[$j]->role();
			for (my $k=0; $k < @{$cpxrxns}; $k++) {
				$hash->{$cpxrxns->[$k]}->{$role->uuid()} = $role;
			}
		}
	}
	return $hash;
}

#***********************************************************************************************************
# CONSTANTS:
#***********************************************************************************************************

#***********************************************************************************************************
# FUNCTIONS:
#***********************************************************************************************************

=head3 printDBFiles

Definition:
	void ModelSEED::MS::Biochemistry->printDBFiles({
		forceprint => 0
	});
Description:
	Creates files with biochemistry data for use by the MFAToolkit

=cut

sub printDBFiles {
    my $self = shift;
    my $args = args([],{ forceprint => 0 }, @_);
	my $path = $self->dataDirectory()."/fbafiles/";
	if (!-d $path) {
		File::Path::mkpath ($path);
	}
	if (-e $path.$self->uuid()."-compounds.tbl" && $args->{forceprint} eq "0") {
		return;	
	}
	my $output = ["abbrev	charge	deltaG	deltaGErr	formula	id	mass	name"];
	my $columns = ["abbreviation","defaultCharge","deltaG","deltaGErr","formula","id","mass","name"];
	my $cpds = $self->compounds();
	for (my $i=0; $i < @{$cpds}; $i++) {
		my $cpd = $cpds->[$i];
		my $line = "";
		foreach my $column (@{$columns}) {
			if (length($line) > 0) {
				$line .= "\t";
			}
			if (defined($cpd->$column())) {
				$line .= $cpd->$column();
			}
		}
		push(@{$output},$line);
	}
	ModelSEED::utilities::PRINTFILE($path.$self->uuid()."-compounds.tbl",$output);
	$output = ["abbrev	deltaG	deltaGErr	equation	id	name	reversibility	status	thermoReversibility"];
	$columns = ["abbreviation","deltaG","deltaGErr","equation","id","name","direction","status","thermoReversibility"];
	my $rxns = $self->reactions();
	for (my $i=0; $i < @{$rxns}; $i++) {
		my $rxn = $rxns->[$i];
		my $line = "";
		foreach my $column (@{$columns}) {
			if (length($line) > 0) {
				$line .= "\t";
			}
			if (defined($rxn->$column())) {
				$line .= $rxn->$column();
			}
		}
		push(@{$output},$line);
	}
	ModelSEED::utilities::PRINTFILE($path.$self->uuid()."-reactions.tbl",$output);
}

=head3 makeDBModel
Definition:
	ModelSEED::MS::ModelReaction = ModelSEED::MS::Biochemistry->makeDBModel({
		balancedOnly => 1,
		gapfillingFormulation => undef
		annotation_uuid => "00000000-0000-0000-0000-000000000000",
		mapping_uuid => "00000000-0000-0000-0000-000000000000",
	});
Description:
	Creates a model that has every reaction instance in the database that pass through the specified filters

=cut

sub makeDBModel {
    my $self = shift;
    my $args = args([],{
		balancedOnly => 1,
		gapfillingFormulation => undef,
		annotation_uuid => "00000000-0000-0000-0000-000000000000",
		mapping_uuid => "00000000-0000-0000-0000-000000000000",
	}, @_);
	my $mdl = ModelSEED::MS::Model->new({
		id => $self->name().".model",
		version => 0,
		type => "dbmodel",
		name => $self->name().".model",
		growth => 0,
		status => "Built from database",
		current => 1,
		mapping_uuid => $args->{mapping_uuid},
		biochemistry_uuid => $self->uuid(),
		biochemistry => $self,
		annotation_uuid => $args->{annotation_uuid}
	});
	my $hashes = {blacklist => {},guaranteed => {}};
	if (defined($args->{gapfillingFormulation})) {
		my $blacklist = $args->{gapfillingFormulation}->blacklistedReactions();
		for (my $i=0; $i < @{$blacklist}; $i++) {
			$hashes->{forbidden}->{$blacklist->[$i]->uuid()} = 1;
		}
		my $guaranteed = $args->{gapfillingFormulation}->guaranteedReactions();
		for (my $i=0; $i < @{$guaranteed}; $i++) {
			$hashes->{guaranteed}->{$guaranteed->[$i]->uuid()} = 1;
		}
		my $allowedcompartments = $args->{gapfillingFormulation}->allowableCompartments();
		for (my $i=0; $i < @{$allowedcompartments}; $i++) {
			$hashes->{allowcomp}->{$allowedcompartments->[$i]->uuid()} = 1;
		}
	} else {
		my $comps = $self->compartments();
		foreach my $comp (@{$comps}) {
			$hashes->{allowcomp}->{$comp->uuid()} = 1;
		}	
	}
	my $reactions = $self->reactions();
	for (my $i=0; $i < @{$reactions}; $i++) {
		my $rxn = $reactions->[$i];
		if (!defined($hashes->{forbidden}->{$rxn->uuid()})) {
			my $add = 1;
			if (!defined($hashes->{guaranteed}->{$rxn->uuid()})) {
				if (!defined($hashes->{allowcomp}->{$rxn->compartment()->uuid()})) {
					$add = 0;
				}
				if ($add == 1) {
#					my $transports = $rxn->transports();
#					for (my $j=0; $j < @{$transports};$j++) {
#						if (!defined($hashes->{allowcomp}->{$transports->[$j]->compartment_uuid()})) {
#							$add = 0;
#							last;
#						}
#					}
				}
				if ($add == 1 && $args->{balancedOnly} == 1 && $rxn->balanced() == 0) {
					$add = 0;
				}
			}
			if ($add == 1) {
				$mdl->addReactionToModel({
					reaction => $rxn,
				});
			}
		}
	}
	return $mdl;
}

=head3 findCreateEquivalentCompartment
Definition:
	void ModelSEED::MS::Biochemistry->findCreateEquivalentCompartment({
		compartment => ModelSEED::MS::Compartment(REQ),
		create => 0/1(1)
	});
Description:
	Search for an equivalent comparment for the input biochemistry compartment

=cut

sub findCreateEquivalentCompartment {
    my $self = shift;
	my $args = args(["compartment"], {create => 1}, @_);
	my $incomp = $args->{compartment};
	my $outcomp = $self->queryObject("compartments",{
		name => $incomp->name()
	});
	if (!defined($outcomp) && $args->{create} == 1) {
		$outcomp = $self->biochemistry()->add("compartments",{
			id => $incomp->id(),
			name => $incomp->name(),
			hierarchy => $incomp->hierarchy()
		});
	}
	$incomp->mapped_uuid($outcomp->uuid());
	$outcomp->mapped_uuid($incomp->uuid());
	return $outcomp;
}

=head3 findCreateEquivalentCompound
Definition:
	void ModelSEED::MS::Biochemistry->findCreateEquivalentCompound({
		compound => ModelSEED::MS::Compound(REQ),
		create => 0/1(1)
	});
Description:
	Search for an equivalent compound for the input biochemistry compound

=cut

sub findCreateEquivalentCompound {
    my $self = shift;
	my $args = args(["compound"], {create => 1}, @_);
	my $incpd = $args->{compound};
	my $outcpd = $self->queryObject("compounds",{
		name => $incpd->name()
	});
	if (!defined($outcpd) && $args->{create} == 1) {
		$outcpd = $self->biochemistry()->add("compounds",{
			name => $incpd->name(),
			abbreviation => $incpd->abbreviation(),
			unchargedFormula => $incpd->unchargedFormula(),
			formula => $incpd->formula(),
			mass => $incpd->mass(),
			defaultCharge => $incpd->defaultCharge(),
			deltaG => $incpd->deltaG(),
			deltaGErr => $incpd->deltaGErr(),
		});
		for (my $i=0; $i < @{$incpd->structures()}; $i++) {
			my $cpdstruct = $incpd->structures()->[$i];
			$outcpd->add("structures",$cpdstruct->serializeToDB());
		}
		for (my $i=0; $i < @{$incpd->pks()}; $i++) {
			my $cpdpk = $incpd->pks()->[$i];
			$outcpd->add("pks",$cpdpk->serializeToDB());
		}
	}
	$incpd->mapped_uuid($outcpd->uuid());
	$outcpd->mapped_uuid($incpd->uuid());
	return $outcpd;
}

=head3 findCreateEquivalentReaction
Definition:
	void ModelSEED::MS::Biochemistry->findCreateEquivalentReaction({
		reaction => ModelSEED::MS::Reaction(REQ),
		create => 0/1(1)
	});
Description:
	Search for an equivalent reaction for the input biochemistry reaction

=cut

sub findCreateEquivalentReaction {
    my $self = shift;
	my $args = args(["reaction"], {create => 1}, @_);
	my $inrxn = $args->{reaction};
	my $outrxn = $self->queryObject("reactions",{
		definition => $inrxn->definition()
	});
	if (!defined($outrxn) && $args->{create} == 1) { 
		$outrxn = $self->biochemistry()->add("reactions",{
			name => $inrxn->name(),
			abbreviation => $inrxn->abbreviation(),
			direction => $inrxn->direction(),
			thermoReversibility => $inrxn->thermoReversibility(),
			defaultProtons => $inrxn->defaultProtons(),
			status => $inrxn->status(),
			deltaG => $inrxn->deltaG(),
			deltaGErr => $inrxn->deltaGErr(),
		});
		my $rgts = $inrxn->reagents(); 
		for (my $i=0; $i < @{$rgts}; $i++) {
			my $rgt = $rgts->[$i];
			my $cpd = $self->biochemistry()->findCreateEquivalentCompound({
				compound => $rgt->compound(),
				create => 1
			});
			my $cmp = $self->findCreateEquivalentCompartment({
				compartment => $rgt->compartment(),
				create => 1
			});
			$outrxn->add("reagents",{
				compound_uuid => $cpd->uuid(),
				compartment_uuid => $cmp->uuid(),
				coefficient => $rgt->coefficient(),
				isCofactor => $rgt->isCofactor(),
			});
		}
	}	
	$inrxn->mapped_uuid($outrxn->uuid());
	$outrxn->mapped_uuid($inrxn->uuid());
	return $outrxn;
}

=head3 validate
Definition:
	void ModelSEED::MS::Biochemistry->validate();
Description:
	This command runs a series of tests on the biochemistry data to ensure that it is valid

=cut

sub findReactionsWithReagent {
    my ($self, $cpd_uuid) = @_;
    my $reactions = $self->reactions();
    my $found_reactions = [];
    foreach my $rxn (@$reactions){
	push(@$found_reactions, $rxn) if $rxn->hasReagent($cpd_uuid);
    }
    return $found_reactions;
}

sub validate {
	my ($self) = @_;
	my $errors = [];
	#Check uniqueness of compound names and abbreviations
	my $cpds = $self->compounds();
	my $nameHash;
	my $abbrevHash;
	foreach my $cpd (@{$cpds}) {
		if (defined($nameHash->{$cpd->name()})) {
			push(@{$errors},"Compound names match: ".$cpd->name().": ".$cpd->uuid()."(".$cpd->id().")\t".$nameHash->{$cpd->name()}->uuid()."(".$nameHash->{$cpd->name()}->id().")");
		} else {
			$nameHash->{$cpd->name()} = $cpd;
		}
		if (defined($abbrevHash->{$cpd->abbreviation()})) {
			push(@{$errors},"Compound abbreviations match: ".$cpd->abbreviation().": ".$cpd->uuid()."(".$cpd->id().")\t".$abbrevHash->{$cpd->abbreviation()}->uuid()."(".$abbrevHash->{$cpd->abbreviation()}->id().")");
		} else {
			$abbrevHash->{$cpd->abbreviation()} = $cpd;
		}
	}
	return $errors;
}

=head3 addCompoundFromHash
Definition:
	ModelSEED::MS::Compound = ModelSEED::MS::Biochemistry->addCompoundFromHash({[]});
Description:
	This command adds a single compound from an input hash

=cut

sub addCompoundFromHash {
    my ($self,$args,$mergeto) = @_;

    # Remove names that are too long
    $args->{names} = [ grep { length($_) < 255 } @{$args->{names}} ];
    # In case all the names were too long, use the id as the name
    push(@{$args->names}, $args->{id}->[0]) unless(@{$args->{names}});

    $args = ModelSEED::utilities::ARGS($args,["names","id"],{
	aliasType => $self->defaultNameSpace(),
	abbreviation => [$args->{names}->[0]],
	formula => ["unknown"],
	mass => [10000000],
	charge => [10000000],
	deltag => [10000000],
	deltagerr => [10000000]
				       });

	# Checking for id uniqueness within scope of own aliasType
	my $cpd = $self->getObjectByAlias("compounds",$args->{id}->[0],$args->{aliasType});
	if (defined($cpd)) {
	    verbose("Compound found with matching id ".$args->{id}->[0]." for namespace ".$args->{aliasType});
	    if(defined($mergeto) && !$cpd->getAlias($mergeto)){
		$self->addAlias({ attribute => "compounds",
				  aliasName => $mergeto,
				  alias => $args->{id}->[0],
				  uuid => $cpd->uuid()
				});
	    }
	    return $cpd;
	}
	# Checking for id uniqueness within scope of another aliasType, if passed
	if($mergeto){
	    $cpd = $self->getObjectByAlias("compounds",$args->{id}->[0],$mergeto);
	    if (defined($cpd)) {
		verbose("Compound found with matching id ".$args->{id}->[0]." for namespace ".$mergeto);
		#Alias needs to be created for original namespace if found in different namespace
		$self->addAlias({
		    attribute => "compounds",
		    aliasName => $args->{aliasType},
		    alias => $args->{id}->[0],
		    uuid => $cpd->uuid()
				});
		return $cpd;
	    }
	}
	# Disabled, attempting to check names ahead of chemical structure is not recommended
	# For metabolic models, every compound is assumed to be unique anyway
	# Checking for name uniqueness
	#foreach my $name (@{$args->{names}}) {
	#	my $searchname = ModelSEED::MS::Compound::nameToSearchname($name);
	#	$cpd = $self->queryObject("compounds",{searchnames => $name});
	#	if (defined($cpd)) {
	#		print STDERR "Compound added with matching name ".$name."!\n";
	#		$self->addAlias({
	#			attribute => "compounds",
	#			aliasName => $args->{aliasType},
	#			alias => $args->{id}->[0],
	#			uuid => $cpd->uuid()
	#		});
	#		return $cpd;
	#	}
	#}

	# Actually creating compound
	$cpd = $self->add("compounds",{
		name => $args->{names}->[0],
		abbreviation => $args->{abbreviation}->[0],
		formula => $args->{formula}->[0],
		mass => $args->{mass}->[0],
		defaultCharge => $args->{charge}->[0],
		deltaG => $args->{deltag}->[0],
		deltaGErr => $args->{deltagerr}->[0]
	});
	# Adding id as alias
	$self->addAlias({
		attribute => "compounds",
		aliasName => $args->{aliasType},
		alias => $args->{id}->[0],
		uuid => $cpd->uuid()
	});
	if(defined($mergeto)){
	    $self->addAlias({
		attribute => "compounds",
		aliasName => $mergeto,
		alias => $args->{id}->[0],
		uuid => $cpd->uuid()
			    });
	}
	# Adding alternative names as aliases
	foreach my $name (@{$args->{names}}) {
		$self->addAlias({
			attribute => "compounds",
			aliasName => "name",
			alias => $name,
			uuid => $cpd->uuid()
		});
	}
	return $cpd;
	# TODO: allow user option to merge based on InChI strings (if included) and/or names
}

=head3 addReactionFromHash
Definition:
	ModelSEED::MS::Compound = ModelSEED::MS::Biochemistry->addReactionFromHash({[]});
Description:
	This command adds a single reaction from an input hash

=cut

sub addReactionFromHash {
    my ($self,$args,$mergeto) = @_;

    # Remove names that are too long
    $args->{names} = [ grep { length($_) < 255 } @{$args->{names}} ];
    # In case all the names were too long, use the id as the name
    push(@{$args->{names}}, $args->{id}->[0]) unless @{$args->{names}};

    $args = ModelSEED::utilities::ARGS($args,["equation","id"],{
	aliasType => $self->defaultNameSpace(),
	names => [$args->{id}->[0]],
	abbreviation => [$args->{id}->[0]],
	direction => ["="],
	deltag => [10000000],
	deltagerr => [10000000],
	enzymes => []
		 });

	#Checking for id uniqueness
	my $rxn = $self->getObjectByAlias("reactions",$args->{id}->[0],$args->{aliasType});
	if (defined($rxn)) {
		verbose("Reaction found with matching id ".$args->{id}->[0]." for namespace ".$args->{aliasType}."\n");
		if(defined($mergeto) && !$rxn->getAlias($mergeto)){
		    $self->addAlias({ attribute => "reactions",
				      aliasName => $mergeto,
				      alias => $args->{id}->[0],
				      uuid => $rxn->uuid()
				    });
		}
		return $rxn;
	}

	#Checking for id uniqueness within scope of another aliasType, if passed
	if($mergeto){
	    $rxn = $self->getObjectByAlias("reactions",$args->{id}->[0],$mergeto);
	    if( defined($rxn) ){
		verbose("Reaction found with matching id ".$args->{id}->[0]." for namespace ".$mergeto."\n");
		#Alias needs to be created for original namespace if found in different namespace
		$self->addAlias({
		    attribute => "reactions",
		    aliasName => $args->{aliasType},
		    alias => $args->{id}->[0],
		    uuid => $rxn->uuid()
				});
		return $rxn;
	    }
	}
	# Creating reaction from equation
	$rxn = ModelSEED::MS::Reaction->new({
		name => $args->{names}->[0],
		abbreviation => $args->{abbreviation}->[0],
		direction => $args->{direction}->[0],
		deltaG => $args->{deltag}->[0],
		deltaGErr => $args->{deltagerr}->[0],
		status => "OK",
		thermoReversibility => "="
	});
	# Attach biochemistry object to reaction object
	$rxn->parent($self);

	# Parse the equation string to finish defining the reaction object
    my $noduplicates = $rxn->loadFromEquation({equation => $args->{equation}->[0],
					       aliasType => $args->{aliasType},
					      });

    if(!$noduplicates){
	verbose("Reaction ".$args->{id}->[0]." was rejected on account of their being duplicates"."\n");
	return undef;
    }

    # Generate equation search string and check to see if reaction not already in database
    my $searchRxn = $self->checkForDuplicateReaction($rxn);
    if (defined($searchRxn)){

	# Check to see if searchRxn has alias from same namespace
	my $alias = $searchRxn->getAlias($args->{aliasType});
	my $aliasSetName=$args->{aliasType};
	# If not, need to find any alias to use (avoiding names for now)
	if(!$alias){
	    foreach my $set ( grep { $_->name() ne "name" || $_->name() ne "searchname" || $_->name() ne "Enzyme Class"} @{$self->aliasSets()}){
		$aliasSetName=$set->name();
		$alias=$searchRxn->getAlias($aliasSetName);
		last if $alias;
	    }
	    # Fall back onto name
	    if(!$alias){
		$alias=$searchRxn->name();
		$aliasSetName="could not find ID";
	    }
	}
	verbose("Reaction ".$alias." (".$aliasSetName.") found with matching equation for Reaction ".$args->{id}->[0]."\n");
	$self->addAlias({ attribute => "reactions",
			  aliasName => $args->{aliasType},
			  alias => $args->{id}->[0],
			  uuid => $searchRxn->uuid()
			});
	return $searchRxn;
    }

        # Attach reaction to biochemistry
	$self->add("reactions", $rxn);
	$self->addAlias({
		attribute => "reactions",
		aliasName => $args->{aliasType},
		alias => $args->{id}->[0],
		uuid => $rxn->uuid()
	});
	if(defined($mergeto)){
	    $self->addAlias({
		attribute => "reactions",
		aliasName => $mergeto,
		alias => $args->{id}->[0],
		uuid => $rxn->uuid()
			    });
	}
	for (my $i=0;$i < @{$args->{names}}; $i++) {
		$self->addAlias({
			attribute => "reactions",
			aliasName => "name",
			alias => $args->{names}->[$i],
			uuid => $rxn->uuid()
		});
	}
	for (my $i=0;$i < @{$args->{enzymes}}; $i++) {
		$self->addAlias({
			attribute => "reactions",
			aliasName => "Enzyme Class",
			alias => $args->{enzymes}->[$i],
			uuid => $rxn->uuid()
		});
	}
	return $rxn;
}

=head3 mergeBiochemistry
Definition:
	void mergeBiochemistry(ModelSEED::MS::Biochemistry,{});
Description:
	This command merges the input biochemistry into the current biochemistry

=cut

sub mergeBiochemistry {
    my ($self,$bio,$opts) = @_;
    my $typelist = [
	        "cues",
		"compartments",
		"compounds",
		"reactions",
		"media",
		"compoundSets",
		"reactionSets",
    ];
    my $types = {
    	"cues" => "checkForDuplicateCue",
    	"compartments" => "checkForDuplicateCompartment",
    	"compounds" => "checkForDuplicateCompound",
    	"reactions" => "checkForDuplicateReaction",
    	"media" => "checkForDuplicateMedia",
    	"compoundSets" => "checkForDuplicateCompoundSet",
    	"reactionSets" => "checkForDuplicateReactionSet"
    };
    foreach my $type (@{$typelist}) {
    	my $func = $types->{$type};
    	my $objs = $bio->$type();
    	my $uuidTranslation = {};
	verbose("Merging ".scalar(@$objs)." ".$type."\n");
    	for (my $j=0; $j < @{$objs}; $j++) {
		    my $obj = $objs->[$j];
		    my $aliases={};
		    if(!defined($opts->{noaliastransfer})){
			foreach my $set ( grep { $_->attribute() eq $type } @{$self->aliasSets()} ){
			    $aliases->{$set->name()}{$obj->getAlias($set->name())}=1 if $obj->getAlias($set->name());
			}
		    }
		    my $objId = (defined($opts->{namespace}) && defined($aliases->{$opts->{namespace}})) ? (keys %{$aliases->{$opts->{namespace}}})[0] : $obj->id();

		    if ($type eq "reactions") {
				$obj->parent($self);
		    }

		    my $dupObj = $self->$func($obj,$opts);
		    if (defined($dupObj)) {
				verbose("Duplicate ".substr($type,0,-1)." found; ".$objId." merged to ".$dupObj->id()."\n");
				foreach my $aliasName (keys %$aliases){
				    foreach my $alias (keys %{$aliases->{$aliasName}}){
					$self->addAlias({attribute=>$type,aliasName=>$aliasName,alias=>$alias,uuid=>$dupObj->uuid()});
				    }
				}
				$uuidTranslation->{$obj->uuid()} = $dupObj->uuid();
				$obj->uuid($dupObj->uuid());
		    } else {
			foreach my $aliasName (keys %$aliases){
			    foreach my $alias (keys %{$aliases->{$aliasName}}){
				$self->addAlias({attribute=>$type,aliasName=>$aliasName,alias=>$alias,uuid=>$obj->uuid()});
			    }
			}
			$self->add($type,$obj);
		    }
    	}
    	$bio->updateLinks($type,$uuidTranslation,1,1);
    	$bio->_clearIndex();
    	$self->updateLinks($type,$uuidTranslation,1,1);
    	$self->_clearIndex();
    }
}

=head3 checkForDuplicateAliasSet
Definition:
	void checkForDuplicateAliasSet(ModelSEED::MS::AliasSet);
Description:
	This command checks if the input aliasSet is a duplicate for an existing aliasSet

=cut

sub checkForDuplicateAliasSet {
    my ($self,$obj,$opts) = @_;
    return $self->queryObject("aliasSets",{
    	name => $obj->name(),
    	class => $obj->class(),
    	attribute => $obj->attribute()
    });
}

=head3 checkForDuplicateReactionSet
Definition:
	void checkForDuplicateReactionSet(ModelSEED::MS::Media);
Description:
	This command checks if the input media is a duplicate for an existing media

=cut

sub checkForDuplicateReactionSet {
    my ($self,$obj,$opts) = @_;
    return $self->queryObject("reactionSets",{reactionCodeList => $obj->reactionCodeList()});
}

=head3 checkForDuplicateCompoundSet
Definition:
	void checkForDuplicateCompoundSet(ModelSEED::MS::Media);
Description:
	This command checks if the input media is a duplicate for an existing media

=cut

sub checkForDuplicateCompoundSet {
    my ($self,$obj,$opts) = @_;
    return $self->queryObject("compoundSets",{compoundListString => $obj->compoundListString()});
}

=head3 checkForDuplicateMedia
Definition:
	void checkForDuplicateMedia(ModelSEED::MS::Media);
Description:
	This command checks if the input media is a duplicate for an existing media

=cut

sub checkForDuplicateMedia {
    my ($self,$obj,$opts) = @_;
    return $self->queryObject("media",{compoundListString => $obj->compoundListString()});
}

=head3 checkForDuplicateReaction
Definition:
	void checkForDuplicateReaction(ModelSEED::MS::Reaction);
Description:
	This command checks if the input reaction is a duplicate for an existing reaction

=cut

sub checkForDuplicateReaction {
    my ($self,$obj,$opts) = @_;
    return $self->queryObject("reactions",{equationCode => $obj->equationCode()});
}

=head3 checkForDuplicateCompound
Definition:
	void checkForDuplicateCompound(ModelSEED::MS::Compound);
Description:
	This command checks if the input compound is a duplicate for an existing compound

=cut

sub checkForDuplicateCompound {
    my ($self,$obj,$opts) = @_;
    if(defined($opts->{namespace})){
	return undef if !$obj->getAlias($opts->{mergevia});
	return $self->getObjectByAlias("compounds",$obj->getAlias($opts->{mergevia}),$opts->{mergevia});
    }
    return undef if !$obj->name();
    return $self->queryObject("compounds",{name => $obj->name()});
}

=head3 checkForDuplicateCompartment
Definition:
	void checkForDuplicateCompartment(ModelSEED::MS::Cue);
Description:
	This command checks if the input compartment is a duplicate for an existing compartment

=cut

sub checkForDuplicateCompartment {
    my ($self,$obj,$opts) = @_;
    return $self->queryObject("compartments",{name => $obj->name()});
}

=head3 checkForDuplicateCue
Definition:
	void checkForDuplicateCue(ModelSEED::MS::Cue);
Description:
	This command checks if the input cue is a duplicate for an existing cue

=cut

sub checkForDuplicateCue {
    my ($self,$obj,$opts) = @_;
    return $self->queryObject("cues",{name => $obj->name()});
}

sub __upgrade__ {
	my ($class,$version) = @_;
	if ($version == 1) {
		return sub {
			my ($hash) = @_;
			my $bioStruct = ModelSEED::MS::BiochemistryStructures->new({});
			if (defined($hash->{compounds})) {
				foreach my $cpd (@{$hash->{compounds}}) {
					if (defined($cpd->{compoundCues})) {
						foreach my $cpdcues (@{$cpd->{compoundCues}}) {
							$cpd->{cues}->{$cpdcues->{cue_uuid}} = $cpdcues->{count};
						}
						delete($cpd->{compoundCues});
					}
					if (defined($cpd->{pks})) {
						foreach my $pk (@{$cpd->{pks}}) {
							if ($pk->{type} eq "pKa") {
								push(@{$cpd->{pkas}->{$pk->{atom}}},$pk->{pk});
							} else {
								push(@{$cpd->{pkbs}->{$pk->{atom}}},$pk->{pk});
							}	
						}
						delete($cpd->{pks});
					}
					if (defined($cpd->{structures})) {
						foreach my $struct (@{$cpd->{structures}}) {
							my $newStruct = $bioStruct->add("structures",{
								data => $struct->{structure},
								type => $struct->{type}
							});
							push(@{$cpd->{structure_uuids}},$newStruct->uuid());
						}
						delete($cpd->{structures});
					}
				}
				if (defined($hash->{parent}) && ref($hash->{parent}) eq "ModelSEED::Store") {
					$hash->{parent}->save_object("biochemistryStructures/".$hash->{uuid},$bioStruct);
				}
				$hash->{biochemistryStructures_uuid} = $bioStruct->uuid();
			}
			if (defined($hash->{compoundSets})) {
				foreach my $set (@{$hash->{compoundSets}}) {
					foreach my $setcpd (@{$hash->{compounds}}) {
						push(@{$set->{compound_uuids}},$setcpd->{compound_uuid});
					}
					delete($set->{compounds});
				}
			}
			if (defined($hash->{reactionSets})) {
				foreach my $set (@{$hash->{reactionSets}}) {
					foreach my $setrxn (@{$hash->{reactions}}) {
						push(@{$set->{reaction_uuids}},$setrxn->{reaction_uuid});
					}
					delete($set->{reactions});
				}
			}
			if (defined($hash->{reactions})) {
				my $rxncomp;
				foreach my $cmp (@{$hash->{compartments}}) {
					if ($cmp->{id} eq "c") {
						$rxncomp = $cmp->{uuid};
					}
				}
				foreach my $rxn (@{$hash->{reactions}}) {
					if (defined($rxn->{reactionCues})) {
						foreach my $rxncues (@{$rxn->{reactionCues}}) {
							$rxn->{cues}->{$rxncues->{cue_uuid}} = $rxncues->{count};
						}
						delete($rxn->{reactionCues});
					}
					if (defined($rxn->{reagents})) {
						my $newReagents = [];
						my $reagentHash = {};
						my $cofactorHash = {};
						foreach my $reagent (@{$rxn->{reagents}}) {
							if (!defined($reagentHash->{$reagent->{compound_uuid}}->{$reagent->{destinationCompartment_uuid}})) {
								$reagentHash->{$reagent->{compound_uuid}}->{$reagent->{destinationCompartment_uuid}} = 0;
								$cofactorHash->{$reagent->{compound_uuid}}->{$reagent->{destinationCompartment_uuid}} = $reagent->{isCofactor};
							}
							if ($reagent->{isTransport} == 0) {
								$reagentHash->{$reagent->{compound_uuid}}->{$rxncomp} += $reagent->{coefficient};
							} else {
								$reagentHash->{$reagent->{compound_uuid}}->{$reagent->{destinationCompartment_uuid}} += $reagent->{coefficient};
								$reagentHash->{$reagent->{compound_uuid}}->{$rxncomp} += (-1*$reagent->{coefficient});
							}
						}
						foreach my $cpd (keys(%{$reagentHash})) {
							foreach my $cmp (keys(%{$reagentHash->{$cpd}})) {
								if ($reagentHash->{$cpd}->{$cmp} != 0) {
									push(@{$newReagents},{
										compound_uuid => $cpd,
										compartment_uuid => $cmp,
										coefficient => $reagentHash->{$cpd}->{$cmp},
										isCofactor => $cofactorHash->{$cpd}->{$cmp},
									});
								}
							}
						}
						$rxn->{reagents} = $newReagents;
					}
				}
			}
			if (defined($hash->{cues})) {
				foreach my $cue (@{$hash->{cues}}) {
					if (defined($cue->{structures})) {
						foreach my $struct (@{$cue->{structures}}) {
							my $newStruct = $bioStruct->add("structures",{
								data => $struct->{structure},
								types => $struct->{type}
							});
							$cue->{structure_uuid} = $newStruct->uuid();
						}
						delete($cue->{structures});
					}
				}
			}
			$hash->{__VERSION__} = 2;
			if ( defined($hash->{parent}) && ref($hash->{parent}) eq "ModelSEED::Store" && defined($hash->{uuid}) ) {
				my $parent = $hash->{parent};
				delete($hash->{parent});
				$parent->save_data("biochemistry/".$hash->{uuid},$hash,{schema_update => 1});
                $hash->{parent} = $parent;
			}
			return $hash;
		};
	}
}

__PACKAGE__->meta->make_immutable;
1;
