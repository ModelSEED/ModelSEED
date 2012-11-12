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

=head3 printDBFiles

	$biochemistry->printDBFiles(
		forceprint => boolean,
        directory  => string,
	);

Creates files with biochemistry data for use by the MFAToolkit.
C<forceprint> is a boolean which, if true, will cause the function
to always print the files, overwriting existing files if they exist.
C<directory> is the directory to save the tables into.

=cut

sub printDBFiles {
    my $self = shift;
    my $args = args([],{
        forceprint => 0,
        directory  => $self->dataDirectory."/fbafiles/",
    }, @_);
    my $path = $args->{directory};
    File::Path::mkpath($path) unless(-d $path);
    my $print_table = sub {
        my ($filename, $header, $attributes, $objects) = @_;
        open(my $fh, ">", $filename) || die "Could not open $filename: $!";
        print $fh join("\t", @$header) . "\n";
        foreach my $object (@$objects) {
            my @line;
            foreach my $attr (@$attributes) {
                my $value = $object->$attr();
                $value = "" unless defined $value;
                push(@line, $value);
            }
            print $fh join("\t", @line) . "\n";
        }
        close $fh;
    };
    my $compound_filename = $path.$self->uuid."-compounds.tbl";
    if (!-e $compound_filename || $args->{forceprint}) {
        my $header      = [ qw(abbrev charge deltaG deltaGErr formula id mass name) ];
        my $attributes  = [ qw(abbreviation defaultCharge deltaG deltaGErr formula id mass name) ];
        my $compounds   = $self->compounds;
        $print_table->($compound_filename, $header, $attributes, $compounds);
    }
    my $reaction_filename = $path.$self->uuid."-reactions.tbl";
    if (!-e $reaction_filename || $args->{forceprint}) {
        my $header      = [ qw(abbrev deltaG deltaGErr equation id name reversibility status thermoReversibility) ];
        my $attributes  = [ qw(abbreviation deltaG deltaGErr equation id name direction status thermoReversibility) ];
        my $reactions   = $self->reactions;
        $print_table->($reaction_filename, $header, $attributes, $reactions);
    }
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

=head3 export

Definition:
	string = ModelSEED::MS::Biochemistry->export({
		format => optfluxmedia/readable/html/json
	});
Description:
	Exports biochemistry data to the specified format.

=cut

sub export {
    my $self = shift;
	my $args = args(["format"], {}, @_);
	if (lc($args->{format}) eq "readable") {
		return $self->toReadableString();
	} elsif (lc($args->{format}) eq "html") {
		return $self->createHTML();
	} elsif (lc($args->{format}) eq "json") {
		return $self->toJSON({pp => 1});
	}
	error("Unrecognized type for export: ".$args->{format});
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

=head3 findReactionsWithReagent
Definition:
	void ModelSEED::MS::Biochemistry->findReactionsWithReagent();
Description:
	This command returns an arrayref of reactions that contain a specificed reagent uuid

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

=head3 addCompoundFromHash
Definition:
	ModelSEED::MS::Compound = ModelSEED::MS::Biochemistry->addCompoundFromHash({[]});
Description:
	This command adds a single compound from an input hash

=cut

sub addCompoundFromHash {
	my ($self,$arguments) = @_;
    $arguments = args(["names","id"],{
		namespace => $self->defaultNameSpace(),
		matchbyname => 1,
		mergeto => [],
		abbreviation => undef,
		formula => ["unknown"],
		mass => [10000000],
		charge => [10000000],
		deltag => [10000000],
		deltagerr => [10000000]
	}, $arguments);

	# Remove names that are too long
	$arguments->{names} = [ grep { length($_) < 255 } @{$arguments->{names}} ];
        $arguments->{names} = [$arguments->{id}->[0]] unless defined $arguments->{names}->[0];
	$arguments->{abbreviation} = [$arguments->{names}->[0]] unless defined $arguments->{abbreviation};

	# Checking for id uniqueness within scope of own aliasType
	my $cpd = $self->getObjectByAlias("compounds",$arguments->{id}->[0],$arguments->{namespace});
	if (defined($cpd)) {
	    verbose("Compound found with matching id ".$arguments->{id}->[0]." for namespace ".$arguments->{namespace});
	    foreach my $aliasType (@{$arguments->{mergeto}}){
		$self->addAlias({ attribute => "compounds",
				  aliasName => $aliasType,
				  alias => $arguments->{id}->[0],
				  uuid => $cpd->uuid()
				});
	    }
	    return $cpd;
	}
	# Checking for id uniqueness within scope of another aliasType, if passed
	foreach my $aliasType (@{$arguments->{mergeto}}) {
		$cpd = $self->getObjectByAlias("compounds",$arguments->{id}->[0],$aliasType);
		if (defined($cpd)) {
		    verbose("Compound found with matching id ".$arguments->{id}->[0]." for namespace ".$aliasType);
		    $self->addAlias({ attribute => "compounds",
				      aliasName => $arguments->{namespace},
				      alias => $arguments->{id}->[0],
				      uuid => $cpd->uuid()
				    });
		    foreach my $otherAliasType (@{$arguments->{mergeto}}){
			next if $otherAliasType eq $aliasType;
			$self->addAlias({ attribute => "compounds",
					  aliasName => $otherAliasType,
					  alias => $arguments->{id}->[0],
					  uuid => $cpd->uuid()
					});
		    }
		    return $cpd;
		}
	}
	#Checking for match by name if requested
	if (defined($arguments->{matchbyname}) && $arguments->{matchbyname} == 1) {
		foreach my $name (@{$arguments->{names}}) {
			my $searchname = ModelSEED::MS::Compound::nameToSearchname($name);
			$cpd = $self->queryObject("compounds",{searchnames => $name});
			if (defined($cpd)) {
				verbose("Compound matched based on name ".$name);
				$self->addAlias({
					attribute => "compounds",
					aliasName => $arguments->{namespace},
					alias => $arguments->{id}->[0],
					uuid => $cpd->uuid()
				});
				foreach my $aliasType (@{$arguments->{mergeto}}){
				    $self->addAlias({ attribute => "compounds",
						      aliasName => $aliasType,
						      alias => $arguments->{id}->[0],
						      uuid => $cpd->uuid()
						    });
				}
				return $cpd;
			}
		}
	}
	# Actually creating compound
	verbose("Creating compound ".$arguments->{id}->[0]);
	$cpd = $self->add("compounds",{
		name => $arguments->{names}->[0],
		abbreviation => $arguments->{abbreviation}->[0],
		formula => $arguments->{formula}->[0],
		mass => $arguments->{mass}->[0],
		defaultCharge => $arguments->{charge}->[0],
		deltaG => $arguments->{deltag}->[0],
		deltaGErr => $arguments->{deltagerr}->[0]
	});
	# Adding id as alias
	$self->addAlias({
		attribute => "compounds",
		aliasName => $arguments->{namespace},
		alias => $arguments->{id}->[0],
		uuid => $cpd->uuid()
	});
	foreach my $aliasType (@{$arguments->{mergeto}}){
	    $self->addAlias({ attribute => "compounds",
			      aliasName => $aliasType,
			      alias => $arguments->{id}->[0],
			      uuid => $cpd->uuid()
			    });
	}
	# Adding alternative names as aliases
	foreach my $name (@{$arguments->{names}}) {
		$self->addAlias({
			attribute => "compounds",
			aliasName => "name",
			alias => $name,
			uuid => $cpd->uuid()
		});
	}
	return $cpd;
}

=head3 addReactionFromHash
Definition:
	ModelSEED::MS::Compound = ModelSEED::MS::Biochemistry->addReactionFromHash({[]});
Description:
	This command adds a single reaction from an input hash

=cut

sub addReactionFromHash {
    my ($self,$arguments) = @_;
	$arguments = args(["equation","id"], {
		names => undef,
		equationAliasType => $self->defaultNameSpace(),
		reaciontIDaliasType => $self->defaultNameSpace(),
		direction => ["="],
		deltag => [10000000],
		deltagerr => [10000000],
		enzymes => []
	}, $arguments);

	# Remove names that are too long
	$arguments->{names} = [ grep { length($_) < 255 } @{$arguments->{names}} ];
        $arguments->{names} = [$arguments->{id}->[0]] unless defined $arguments->{names}->[0];
        $arguments->{abbreviation} = [$arguments->{id}->[0]] unless defined $arguments->{abbreviation};

	#Checking for id uniqueness
	my $rxn = $self->getObjectByAlias("reactions",$arguments->{id}->[0],$arguments->{reaciontIDaliasType});
	if (defined($rxn)) {
		verbose("Reaction found with matching id ".$arguments->{id}->[0]." for namespace ".$arguments->{reaciontIDaliasType});
		foreach my $aliasType (@{$arguments->{mergeto}}){
		    $self->addAlias({ attribute => "reactions",
				      aliasName => $aliasType,
				      alias => $arguments->{id}->[0],
				      uuid => $rxn->uuid()
				    });
		}
		return $rxn;
	}
	# Checking for id uniqueness within scope of another aliasType, if passed
        foreach my $aliasType (@{$arguments->{mergeto}}){
	    $rxn = $self->getObjectByAlias("reactions",$arguments->{id}->[0],$aliasType);
	    if( defined($rxn) ){
			verbose("Reaction found with matching id ".$arguments->{id}->[0]." for namespace ".$aliasType);
			#Alias needs to be created for original namespace if found in different namespace
			$self->addAlias({
			    attribute => "reactions",
			    aliasName => $arguments->{reaciontIDaliasType},
			    alias => $arguments->{id}->[0],
			    uuid => $rxn->uuid()
			});
			foreach my $otherAliasType (@{$arguments->{mergeto}}){
			    next if $otherAliasType eq $aliasType;
			    $self->addAlias({ attribute => "reactions",
					      aliasName => $otherAliasType,
					      alias => $arguments->{id}->[0],
					      uuid => $rxn->uuid()
					    });
			}
			return $rxn;
	    }
	}
    verbose($arguments->{id}->[0],"\t",$arguments->{names}->[0],"\n");
	# Creating reaction from equation
	$rxn = ModelSEED::MS::Reaction->new({
		name => $arguments->{names}->[0],
		abbreviation => $arguments->{abbreviation}->[0],
		direction => $arguments->{direction}->[0],
		deltaG => $arguments->{deltag}->[0],
		deltaGErr => $arguments->{deltagerr}->[0],
		status => "OK",
		thermoReversibility => "="
	});
	# Attach biochemistry object to reaction object
	$rxn->parent($self);
	# Parse the equation string to finish defining the reaction object
	# a return of zero indicates that the reaction was rejected
	if(!$rxn->loadFromEquation({
	    equation => $arguments->{equation}->[0],
	    aliasType => $arguments->{equationAliasType},
	})) {
	    verbose("Reaction ".$arguments->{id}->[0]." was rejected");
	    return undef;
	}
	# Generate equation search string and check to see if reaction not already in database
	my $code = $rxn->equationCode();
	my $searchRxn = $self->queryObject("reactions",{equationCode => $code});
	if (defined($searchRxn)) {
	    # Check to see if searchRxn has alias from same namespace
	    my $alias = $searchRxn->getAlias($arguments->{reaciontIDaliasType});
	    my $aliasSetName=$arguments->{reaciontIDaliasType};
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
	    verbose("Reaction ".$alias." (".$aliasSetName.") found with matching equation for Reaction ".$arguments->{id}->[0]);
	    $self->addAlias({ attribute => "reactions",
			      aliasName => $arguments->{reaciontIDaliasType},
			      alias => $arguments->{id}->[0],
			      uuid => $searchRxn->uuid()
			    });
	    foreach my $aliasType (@{$arguments->{mergeto}}){
		$self->addAlias({ attribute => "reactions",
				  aliasName => $aliasType,
				  alias => $arguments->{id}->[0],
				  uuid => $searchRxn->uuid()
				});
		}
	    return $searchRxn;
	}
	# Attach reaction to biochemistry
	$self->add("reactions", $rxn);
	$self->addAlias({
		attribute => "reactions",
		aliasName => $arguments->{reaciontIDaliasType},
		alias => $arguments->{id}->[0],
		uuid => $rxn->uuid()
	});
        foreach my $aliasType (@{$arguments->{mergeto}}){
	    $self->addAlias({ attribute => "reactions",
			      aliasName => $aliasType,
			      alias => $arguments->{id}->[0],
			      uuid => $rxn->uuid()
			    });
	}
	for (my $i=0;$i < @{$arguments->{names}}; $i++) {
		$self->addAlias({
			attribute => "reactions",
			aliasName => "name",
			alias => $arguments->{names}->[$i],
			uuid => $rxn->uuid()
		});
	}
	for (my $i=0;$i < @{$arguments->{enzymes}}; $i++) {
		$self->addAlias({
			attribute => "reactions",
			aliasName => "Enzyme Class",
			alias => $arguments->{enzymes}->[$i],
			uuid => $rxn->uuid()
		});
	}
	return $rxn;
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
