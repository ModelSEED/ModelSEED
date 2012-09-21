########################################################################
# ModelSEED::MS::Factories - This is the factory for producing the moose objects from the SEED data
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-03-15T16:44:01
########################################################################
package ModelSEED::MS::Factories::TableFileFactory;
use common::sense;
use ModelSEED::utilities;
use ModelSEED::MS::Utilities::GlobalFunctions;
use Class::Autouse qw(
	ModelSEED::MS::BiochemistryStructures
    ModelSEED::MS::Biochemistry
    ModelSEED::MS::Mapping
    ModelSEED::MS::Model
    ModelSEED::MS::Factories::Annotation
    ModelSEED::Table
);
use Moose;
use namespace::autoclean;

#***********************************************************************************************************
# ATTRIBUTES:
#***********************************************************************************************************
has namespace => ( is => 'rw', isa => 'Str', required => 1 );
has filepath => ( is => 'rw', isa => 'Str', required => 1 );
has modelTbl => ( is => 'rw', isa => 'ModelSEED::Table', lazy => 1, builder => '_buildmodelTbl' );
has bofTbl => ( is => 'rw', isa => 'ModelSEED::Table', lazy => 1, builder => '_buildbofTbl' );
has compoundTbl => ( is => 'rw', isa => 'ModelSEED::Table', lazy => 1, builder => '_buildcompoundTbl' );
has reactionTbl => ( is => 'rw', isa => 'ModelSEED::Table', lazy => 1, builder => '_buildreactionTbl' );
has cpdalsTbl => ( is => 'rw', isa => 'ModelSEED::Table', lazy => 1, builder => '_buildcpdalsTbl' );
has rxnalsTbl => ( is => 'rw', isa => 'ModelSEED::Table', lazy => 1, builder => '_buildrxnalsTbl' );
has mediaTbl => ( is => 'rw', isa => 'ModelSEED::Table', lazy => 1, builder => '_buildmediaTbl' );
has mediacpdTbl => ( is => 'rw', isa => 'ModelSEED::Table', lazy => 1, builder => '_buildmediacpdTbl' );
has roleTbl => ( is => 'rw', isa => 'ModelSEED::Table', lazy => 1, builder => '_buildroleTbl' );
has subsystemTbl => ( is => 'rw', isa => 'ModelSEED::Table', lazy => 1, builder => '_buildsubsystemTbl' );
has ssroleTbl => ( is => 'rw', isa => 'ModelSEED::Table', lazy => 1, builder => '_buildssroleTbl' );
has complexTbl => ( is => 'rw', isa => 'ModelSEED::Table', lazy => 1, builder => '_buildcomplexTbl' );
has cpxroleTbl => ( is => 'rw', isa => 'ModelSEED::Table', lazy => 1, builder => '_buildcpxroleTbl' );
has rxncpxTbl => ( is => 'rw', isa => 'ModelSEED::Table', lazy => 1, builder => '_buildrxncpxTbl' );
has cueTbl => ( is => 'rw', isa => 'ModelSEED::Table', lazy => 1, builder => '_buildcueTbl' );

#***********************************************************************************************************
# BUILDERS:
#***********************************************************************************************************
sub _buildmodelTbl {
	my ($self) = @_;
	return ModelSEED::Table->new({filename => $self->filepath()."/model.tbl",rows_return_as => "ref"});
}
sub _buildcueTbl {
	my ($self) = @_;
	return ModelSEED::Table->new({filename => $self->filepath()."/cue.tbl",rows_return_as => "ref"});
}
sub _buildbofTbl {
	my ($self) = @_;
	return ModelSEED::Table->new({filename => $self->filepath()."/bof.tbl",rows_return_as => "ref"});
}
sub _buildcompoundTbl {
	my ($self) = @_;
	return ModelSEED::Table->new({filename => $self->filepath()."/compound.tbl",rows_return_as => "ref"});
}
sub _buildreactionTbl {
	my ($self) = @_;
	return ModelSEED::Table->new({filename => $self->filepath()."/reaction.tbl",rows_return_as => "ref"});
}
sub _buildcpdalsTbl {
	my ($self) = @_;
	return ModelSEED::Table->new({filename => $self->filepath()."/cpdals.tbl",rows_return_as => "ref"});
}
sub _buildrxnalsTbl {
	my ($self) = @_;
	return ModelSEED::Table->new({filename => $self->filepath()."/rxnals.tbl",rows_return_as => "ref"});
}
sub _buildmediaTbl {
	my ($self) = @_;
	return ModelSEED::Table->new({filename => $self->filepath()."/media.tbl",rows_return_as => "ref"});
}
sub _buildmediacpdTbl {
	my ($self) = @_;
	return ModelSEED::Table->new({filename => $self->filepath()."/mediacpd.tbl",rows_return_as => "ref"});
}
sub _buildroleTbl {
	my ($self) = @_;
	return ModelSEED::Table->new({filename => $self->filepath()."/role.tbl",rows_return_as => "ref"});
}
sub _buildsubsystemTbl {
	my ($self) = @_;
	return ModelSEED::Table->new({filename => $self->filepath()."/subsystem.tbl",rows_return_as => "ref"});
}
sub _buildssroleTbl {
	my ($self) = @_;
	return ModelSEED::Table->new({filename => $self->filepath()."/ssroles.tbl",rows_return_as => "ref"});
}
sub _buildcomplexTbl {
	my ($self) = @_;
	return ModelSEED::Table->new({filename => $self->filepath()."/complex.tbl",rows_return_as => "ref"});
}
sub _buildcpxroleTbl {
	my ($self) = @_;
	return ModelSEED::Table->new(filename => $self->filepath()."/cpxrole.tbl");
}
sub _buildrxncpxTbl {
	my ($self) = @_;
	return ModelSEED::Table->new(filename => $self->filepath()."/rxncpx.tbl");
}


#***********************************************************************************************************
# FUNCTIONS:
#***********************************************************************************************************
sub createModel {
	my ($self,$args) = @_;
	$args = ModelSEED::utilities::ARGS($args,["id", "annotation"],{
        verbose => 0,
	});
	$args->{biochemistry} = $args->{annotation}->mapping->biochemistry;
    $args->{mapping} = $args->{annotation}->mapping;
	# Retrieving model data
    print "Getting model metadata...\n" if($args->{verbose});
    my $id = $args->{id};
	my $mdltbl = $self->modelTbl();
	my $boftbl = $self->bofTbl();
	my $rowMdl = $mdltbl->get_row({id => $id});
	unless(defined($rowMdl)) {
        die "Unable to find model with id ". $id."\n";
    }
	print "Loading linked objects...\n" if($args->{verbose});
	#Creating the model
	my $model = ModelSEED::MS::Model->new({
		locked => 0,
		public => $rowMdl->public(),
		id => $id,
		name => $rowMdl->name(),
		version => $rowMdl->version(),
		type => "Singlegenome",
		status => "Model loaded into new database",
		reactions => $rowMdl->reactions(),
		compounds => $rowMdl->compounds(),
		annotations => $rowMdl->associatedGenes(),
		growth => $rowMdl->growth(),
		current => 1,
		mapping_uuid => $args->{mapping}->uuid(),
		biochemistry_uuid => $args->{biochemistry}->uuid(),
		annotation_uuid => $args->{annotation}->uuid(),
	});
    my $biochemistry = $model->biochemistry;
	my $biomassIndex = 1;
	#Adding reactions
    print "Getting model reactions...\n" if($args->{verbose});
	my $rxntbl = ModelSEED::Table->new(filename => $self->filepath().$id.".tbl");
	for (my $i=0; $i < @{$rxntbl->size()}; $i++) {
		#Adding biomass reaction
        my $old_rxn = $rxntbl->row($i);
        my $id  = $old_rxn->REACTION();
		if ($id =~ m/bio\d+/) {
			my $bioobj = $model->add("biomasses",{
				name => "bio0000".$biomassIndex
			});
			my $biorxn = $boftbl->get_row({id => $id});
			if (defined($biorxn)) {
				$bioobj->loadFromEquation({
					equation => $biorxn->equation(),
					aliasType => "ModelSEED"
				});
			}
			$biomassIndex++;
		} else {
			my $rxn = $biochemistry->getObjectByAlias("reactions",$id,"ModelSEED");
            unless(defined($rxn)) {
                print "Unable to find reaction $id, skipping...\n" if($args->{verbose});
                next;
            }
			my $direction = "=";
			if ($old_rxn->directionality() eq "=>") {
				$direction = ">";
			} elsif ($old_rxn->directionality() eq "<=") {
				$direction = "<";
			}
            $model->addReactionToModel({
                reaction  => $rxn,
                direction => $direction,
                gpr       => $old_rxn->pegs()
            });
		}
	}
	return $model;
}

sub createBiochemistry {
	my ($self,$args) = @_;
	$args = ModelSEED::utilities::ARGS($args,[],{
		name => $self->namespace()."/primary.biochemistry",
		addAliases => 1,
		addStructuralCues => 1,
		addStructure => 1,
		addPK => 1,
        verbose => 0
	});
	#Creating the biochemistry
	my $bioStruct = ModelSEED::MS::BiochemistryStructures->new({});
	my $biochemistry = ModelSEED::MS::Biochemistry->new({
		biochemistryStructures_uuid => $bioStruct->uuid(),
		biochemistrystructures => $bioStruct,
		name=>$args->{name},
		public => 1
	});
	#Adding compartments to biochemistry
    my $comps = [
        { id => "e", name => "Extracellular",         hierarchy => 0 },
        { id => "w", name => "Cell Wall",             hierarchy => 1 },
        { id => "p", name => "Periplasm",             hierarchy => 2 },
        { id => "c", name => "Cytosol",               hierarchy => 3 },
        { id => "g", name => "Golgi",                 hierarchy => 4 },
        { id => "r", name => "Endoplasmic Reticulum", hierarchy => 4 },
        { id => "l", name => "Lysosome",              hierarchy => 4 },
        { id => "n", name => "Nucleus",               hierarchy => 4 },
        { id => "h", name => "Chloroplast",           hierarchy => 4 },
        { id => "m", name => "Mitochondria",          hierarchy => 4 },
        { id => "x", name => "Peroxisome",            hierarchy => 4 },
        { id => "v", name => "Vacuole",               hierarchy => 4 },
        { id => "d", name => "Plastid",               hierarchy => 4 }
    ];
	for (my $i=0; $i < @{$comps}; $i++) {
		my $comp = $biochemistry->add("compartments",{
			locked => "0",
			id => $comps->[$i]->{id},
			name => $comps->[$i]->{name},
			hierarchy => $comps->[$i]->{hierarchy}
		});
	}
	#Adding structural cues to biochemistry
	if ($args->{addStructuralCues} == 1) {
		my $data = ModelSEED::utilities::LOADFILE($self->filepath()."/cueTable.txt");
		my $priorities = ModelSEED::utilities::LOADFILE($self->filepath()."/FinalGroups.txt");
		my $cuePriority;
		for (my $i=2;$i < @{$priorities}; $i++) {
			my $array = [split(/_/,$priorities->[$i])];
			$cuePriority->{$array->[1]} = ($i-1);
		}
		for (my $i=1;$i < @{$data}; $i++) {
			my $array = [split(/\t/,$data->[$i])];
			my $priority = -1;
			if (defined($cuePriority->{$array->[0]})) {
				$priority = $cuePriority->{$array->[0]};
			}		
			$biochemistry->add("cues",{
				locked => "0",
				name => $array->[0],
				abbreviation => $array->[0],
				formula => $array->[5],
				defaultCharge => $array->[3],
				deltaG => $array->[3],
				deltaGErr => $array->[3],
				smallMolecule => $array->[1],
				priority => $priority
			});
		}
	}
	#Adding compounds to biochemistr
	my $cpds = $self->compoundTbl();
    print "Handling compounds!\n" if($args->{verbose});
	for (my $i=0; $i < $cpds->size(); $i++) {
		my $cpdRow = $cpds->row($i);
		my $cpdData = {
			name => $cpdRow->name(),
			abbreviation => $cpdRow->abbrev(),
			unchargedFormula => "",
			formula => $cpdRow->formula(),
			mass => $cpdRow->mass(),
			defaultCharge => $cpdRow->charge(),
			deltaG => $cpdRow->deltaG(),
			deltaGErr => $cpdRow->deltaGErr()
		};
		foreach my $key (keys(%{$cpdData})) {
			if (!defined($cpdData->{$key}) || $cpdData->{$key} eq "") {
				delete $cpdData->{$key};
			}
		}
		my $cpd = $biochemistry->add("compounds",$cpdData);
		$biochemistry->addAlias({
			attribute => "compounds",
			aliasName => "ModelSEED",
			alias => $cpdRow->id(),
			uuid => $cpd->uuid()
		});
		if ($args->{addStructure} == 1) {
			#Adding stringcode as structure 
			if (defined($cpdRow->stringcode()) && length($cpdRow->stringcode()) > 0) {
				$cpd->addStructure({
					data => $cpdRow->stringcode(),
					type => "smiles",
				});
			}
		}
		#Adding structural cues
		if ($args->{addStructuralCues} == 1) {
            my $cueListString = $cpdRow->structuralCues();
			if(defined($cueListString) && length($cueListString) > 0) {
                # PPO uses different delmiter from Model flat-files
                my $delimiterRegex = $self->_getDelimiterRegex($cueListString);
                my $list = [split($delimiterRegex,$cueListString)];
                for (my $j=0;$j < @{$list}; $j++) {
                    my ($name, $count) = split(/:/,$list->[$j]);
                    if ($name eq "nogroups" && !defined($count)) {
                    	$count = 1;
                    }
                    unless(defined $name && defined $count) {
                        warn "Bad cue: " . $list->[$j] . " for " . $cpdRow->id . "\n";
                        next;
                    }
                    my $cue = $biochemistry->queryObject("cues",{name => $name});
                    if (!defined($cue)) {
                        $cue = $biochemistry->add("cues",{
                            locked => "0",
                            name => $name,
                            abbreviation => $name,
                            smallMolecule => 0,
                            priority => -1
                        });
                    }
                    $cpd->cues()->{$cue->uuid()} = $count;
                }
            }
		}
		#Adding pka and pkb
		if ($args->{addPK} == 1) {
            my $pka = $cpdRow->pKa();
            my $pkb = $cpdRow->pKb();
            if(defined $pka && length $pka > 0) {
                my $delimiterRegex = $self->_getDelimiterRegex($pka);
			 	my $list = [ split($delimiterRegex,$pka) ];
			 	for (my $j=0;$j < @$list; $j++) {
			 		my ($pk, $atom) = split(/:/,$list->[$j]);
                    unless(defined $pk && defined $atom) {
                        warn "Bad pKa: " . $list->[$j] . " for " . $cpdRow->id . "\n";
                        next;
                    }
                    push(@{$cpd->pkas()->{$atom}},$pk);
			 	}
			 }
            if(defined $pkb && length $pkb > 0) {
                my $delimiterRegex = $self->_getDelimiterRegex($pkb);
			 	my $list = [ split($delimiterRegex,$pkb) ];
			 	for (my $j=0;$j < @$list; $j++) {
			 		my ($pk, $atom) = split(/:/,$list->[$j]);
                    unless(defined $pk && defined $atom) {
                        warn "Bad pKb: " . $list->[$j] . " for " . $cpdRow->id . "\n";
                        next;
                    }
                    push(@{$cpd->pkbs()->{$atom}},$pk);
			 	}
			 }
		}
	}
	print "Handling media formulations!\n" if($args->{verobse});
	#Adding media formulations
	my $medias = $self->mediaTbl();
	my $mediacpdstbl = $self->mediacpdTbl();
	for (my $i=0; $i < $medias->size(); $i++) {
		my $mediaRow = $medias->row($i);
		my $type = "unknown";
		if ($mediaRow->id() =~ m/^Carbon/ || $mediaRow->id() =~ m/^Nitrogen/ || $mediaRow->id() =~ m/^Sulfate/ || $mediaRow->id() =~ m/^Phosphate/) {
			$type = "biolog";
		}
		my $defined = "1";
		if ($mediaRow->id() =~ m/LB/ || $mediaRow->id() =~ m/BHI/) {
			$defined = "0";
		}
		my $media = $biochemistry->add("media",{
			locked => "0",
			id => $mediaRow->id(),
			name => $mediaRow->id(),
			isDefined => $defined,
			isMinimal => 0,
			type => $type,
		});
		my $rowHash = {};
		for (my $j=0; $j < $mediacpdstbl->size(); $j++) {
			my $mediacpdRow = $mediacpdstbl->row($i);
			push(@{$rowHash->{$mediacpdRow->MEDIA()}},$mediacpdRow);
		}
		if (defined($rowHash->{$mediaRow->id()})) {
			my $mediacpds = $rowHash->{$mediaRow->id()};
			for (my $j=0; $j < @{$mediacpds}; $j++) {
				my $mediacpdRow = $mediacpds->[$j];
				if ($mediacpdRow->type() eq "COMPOUND") {
					my $cpd = $biochemistry->getObjectByAlias("compounds",$mediacpdRow->entity(),"ModelSEED");
					if (defined($cpd)) {
						$media->add("mediacompounds",{
							compound_uuid => $cpd->uuid(),
							concentration => $mediacpdRow->concentration(),
							maxFlux => $mediacpdRow->maxFlux(),
							minFlux => $mediacpdRow->minFlux(),
						});
					}
				}
			}
		}
	}
	print "Handling reactions!\n" if($args->{verbose});
	#Adding reactions to biochemistry
	my $rxns = $self->reactionTbl();	
	my $directionTranslation = {"<=>" => "=","<=" => "<","=>" => ">"};
	for (my $i=0; $i < $rxns->size(); $i++) {
		my $rxnRow = $rxns->row($i);
		my $data = {
			name => $rxnRow->name(),
			abbreviation => $rxnRow->abbrev(),
			reversibility => $directionTranslation->{$rxnRow->reversibility()},
			thermoReversibility => $directionTranslation->{$rxnRow->thermoReversibility()},
			defaultProtons => 0,
			deltaG => $rxnRow->deltaG(),
			deltaGErr => $rxnRow->deltaGErr(),
			status => $rxnRow->status(),
		};
		foreach my $key (keys(%{$data})) {
			if (!defined($data->{$key})) {
				delete $data->{$key};
			}
		}
		my $rxn = ModelSEED::MS::Reaction->new($data);
		$rxn->parent($biochemistry);
		$rxn->loadFromEquation({
			equation => $rxnRow->equation(),
			aliasType => "ModelSEED",
		});
        $biochemistry->add("reactions", $rxn);
		print $rxnRow->id()."\n";
		$biochemistry->addAlias({
			attribute => "reactions",
			aliasName => "ModelSEED",
			alias => $rxnRow->id(),
			uuid => $rxn->uuid()
		});
		#Adding ModelSEED ID and EC numbers as aliases
		my $ecnumbers = [];
		if (defined($rxnRow->enzyme()) && length($rxnRow->enzyme()) > 0) {
		 	my $list = [split(/\|/,$rxnRow->enzyme())];
		 	for (my $j=0;$j < @{$list}; $j++) {
		 		if (length($list->[$j]) > 0) {
			 		push(@{$ecnumbers},$list->[$j]);
		 		}
		 	}
		}
		for (my $j=0; $j < @{$ecnumbers}; $j++) {
			$biochemistry->addAlias({
				attribute => "reactions",
				aliasName => "Enzyme Class",
				alias => $ecnumbers->[$j],
				uuid => $rxn->uuid()
			});
		}
		#Adding structural cues
		if ($args->{addStructuralCues} == 1) {
            my $cueListString = $rxnRow->structuralCues();
			next unless(defined($cueListString) && length($cueListString) > 0 && @{$rxn->reactionCues} == 0 );
            # PPO uses different delmiter from Model flat-files
            my $cueDelimiter = $self->_getDelimiterRegex($cueListString);
            my $list = [split(/$cueDelimiter/, $rxnRow->structuralCues)];
            for (my $j=0;$j < @{$list}; $j++) {
                my ($name, $count) = split(/:/, $list->[$j]);
                if( defined $name && defined $count ) {
	                my $cue = $biochemistry->queryObject("cues",{name => $name} );
	                if (!defined($cue)) {
	                    $cue = $biochemistry->add("cues",{
	                        locked => "0",
	                        name => $name,
	                        abbreviation => $name,
	                        smallMolecule => 0,
	                        priority => -1
	                    });
	                }
	                $rxn->cues()->{$cue->uuid()} = $count;
                } else {
                	warn "Bad cue: " . $list->[$j] . " for " . $rxnRow->id . "\n";
                }
            }
        }
	}
	if ($args->{addAliases} == 1) {
		$self->addAliases({
			biochemistry => $biochemistry,
			database => $args->{database}
		});
	}
	return $biochemistry;
}

sub addAliases {
	my ($self,$args) = @_;
	$args = ModelSEED::utilities::ARGS($args,["biochemistry"],{});
	my $biochemistry = $args->{biochemistry};
	#Adding compound aliases
	print "Handling compound aliases!\n" if($args->{verbose});
	my $cpdals = $self->cpdalsTbl();
	for (my $i=0; $i < $cpdals->size(); $i++) {
		my $row = $cpdals->row($i);
		my $cpd = $biochemistry->getObjectByAlias("compounds",$row->COMPOUND(),"ModelSEED");
		if (defined($cpd)) {
			$biochemistry->addAlias({
				attribute => "compounds",
				aliasName => $row->type(),
				alias => $row->alias(),
				uuid => $cpd->uuid()
			});
		} else {
			print $row->COMPOUND()." not found!\n" if($args->{verobose});
		}
	}
	#Adding reaction aliases
	my $rxnals = $self->rxnalsTbl();
	for (my $i=0; $i < $rxnals->size(); $i++) {
		my $row = $rxnals->row($i);
		my $rxn = $biochemistry->getObjectByAlias("reactions",$row->REACTION(),"ModelSEED");
		if (defined($rxn)) {
			$biochemistry->addAlias({
				attribute => "reactions",
				aliasName => $row->type(),
				alias => $row->alias(),
				uuid => $rxn->uuid()
			});
		}
	}
}

sub createMapping {
	my ($self,$args) = @_;
	$args = ModelSEED::utilities::ARGS($args,["biochemistry"],{
		name => $self->namespace()."/primary.mapping",
        verbose => 0,
	});
	my $mapping = ModelSEED::MS::Mapping->new({
		name=>$args->{name},
		biochemistry_uuid => $args->{biochemistry}->uuid(),
		biochemistry => $args->{biochemistry}
	});
    my $biochemistry = $mapping->biochemistry;
	my $spontaneousRxn = [ qw(
		rxn00062 rxn01208 rxn04132 rxn04133 rxn05319 rxn05467 rxn05468 rxn02374 rxn05116 rxn03012 rxn05064 rxn02666 rxn04457 rxn04456 rxn01664 rxn02916 rxn05667
	) ];
	for (my $i=0; $i < @{$spontaneousRxn}; $i++) {
		my $rxn = $biochemistry->getObjectByAlias("reactions",$spontaneousRxn->[$i],"ModelSEED");
		if (defined($rxn)) {
			$mapping->add("universalReactions",{
				type => "SPONTANEOUS",
				reaction_uuid => $rxn->uuid()	
			});
		}
	}
	my $universalRxn = [ qw(
		rxn05651 rxn10473 rxn10571 rxn05195 rxn05555
	)];
	for (my $i=0; $i < @{$universalRxn}; $i++) {
		my $rxn = $biochemistry->getObjectByAlias("reactions",$universalRxn->[$i],"ModelSEED");
		if (defined($rxn)) {
			$mapping->add("universalReactions",{
				type => "UNIVERSAL",
				reaction_uuid => $rxn->uuid()	
			});
		}
	}
    my $biomassTempComp = {
        "Gram positive" => {
            rna => {
                cpd00002 => -0.262,
                cpd00012 => 1,
                cpd00038 => -0.323,
                cpd00052 => -0.199,
                cpd00062 => -0.215
            },
            protein => {
                cpd00001 => 1,
                cpd00023 => -0.0637,
                cpd00033 => -0.0999,
                cpd00035 => -0.0653,
                cpd00039 => -0.0790,
                cpd00041 => -0.0362,
                cpd00051 => -0.0472,
                cpd00053 => -0.0637,
                cpd00054 => -0.0529,
                cpd00060 => -0.0277,
                cpd00065 => -0.0133,
                cpd00066 => -0.0430,
                cpd00069 => -0.0271,
                cpd00084 => -0.0139,
                cpd00107 => -0.0848,
                cpd00119 => -0.0200,
                cpd00129 => -0.0393,
                cpd00132 => -0.0362,
                cpd00156 => -0.0751,
                cpd00161 => -0.0456,
                cpd00322 => -0.0660
            }
        },
        "Gram negative" => {
            rna => {
                cpd00002 => -0.262,
                cpd00012 => 1,
                cpd00038 => -0.322,
                cpd00052 => -0.2,
                cpd00062 => -0.216
            },
            protein => {
                cpd00001 => 1,
                cpd00023 => -0.0492,
                cpd00033 => -0.1145,
                cpd00035 => -0.0961,
                cpd00039 => -0.0641,
                cpd00041 => -0.0451,
                cpd00051 => -0.0554,
                cpd00053 => -0.0492,
                cpd00054 => -0.0403,
                cpd00060 => -0.0287,
                cpd00065 => -0.0106,
                cpd00066 => -0.0347,
                cpd00069 => -0.0258,
                cpd00084 => -0.0171,
                cpd00107 => -0.0843,
                cpd00119 => -0.0178,
                cpd00129 => -0.0414,
                cpd00132 => -0.0451,
                cpd00156 => -0.0791,
                cpd00161 => -0.0474,
                cpd00322 => -0.0543
            }
        },
        "Unknown" => {
            rna => {
                cpd00002 => -0.262,
                cpd00012 => 1,
                cpd00038 => -0.322,
                cpd00052 => -0.2,
                cpd00062 => -0.216
            },
            protein => {
                cpd00001 => 1,
                cpd00023 => -0.0492,
                cpd00033 => -0.1145,
                cpd00035 => -0.0961,
                cpd00039 => -0.0641,
                cpd00041 => -0.0451,
                cpd00051 => -0.0554,
                cpd00053 => -0.0492,
                cpd00054 => -0.0403,
                cpd00060 => -0.0287,
                cpd00065 => -0.0106,
                cpd00066 => -0.0347,
                cpd00069 => -0.0258,
                cpd00084 => -0.0171,
                cpd00107 => -0.0843,
                cpd00119 => -0.0178,
                cpd00129 => -0.0414,
                cpd00132 => -0.0451,
                cpd00156 => -0.0791,
                cpd00161 => -0.0474,
                cpd00322 => -0.0543
            }
        }
    };
	my $universalBiomassTempComp = [
		["cofactor","cpd00010","FRACTION"],
		["cofactor","cpd11493","FRACTION"],
		["cofactor","cpd00003","FRACTION"],
		["cofactor","cpd00006","FRACTION"],
		["cofactor","cpd00205","FRACTION"],
		["cofactor","cpd00254","FRACTION"],
		["cofactor","cpd10516","FRACTION"],
		["cofactor","cpd00063","FRACTION"],
		["cofactor","cpd00009","FRACTION"],
		["cofactor","cpd00099","FRACTION"],
		["cofactor","cpd00149","FRACTION"],
		["cofactor","cpd00058","FRACTION"],
		["cofactor","cpd00015","FRACTION"],
		["cofactor","cpd10515","FRACTION"],
		["cofactor","cpd00030","FRACTION"],
		["cofactor","cpd00048","FRACTION"],
		["cofactor","cpd00034","FRACTION"],
		["cofactor","cpd00016","FRACTION"],
		["cofactor","cpd00220","FRACTION"],
		["cofactor","cpd00017","FRACTION"],
		["macromolecule","cpd11416","1"],
		["macromolecule","cpd17041","-1"],
		["macromolecule","cpd17042","-1"],
		["macromolecule","cpd17043","-1"],
		["energy","cpd00002",-1],
		["energy","cpd00001",-1],
		["energy","cpd00008",1],
		["energy","cpd00009",1],
		["energy","cpd00067",1],
		["dna","cpd00012",1],
		["dna","cpd00115",-0.5],
		["dna","cpd00241",-0.5],
		["dna","cpd00356",-0.5],
		["dna","cpd00357",-0.5],
		["cofactor","cpd12370","cpd11493"],
	];	
	my $conditionedBiomassTempComp = [
		["cofactor","cpd00201","FRACTION","AND{SUBSYSTEM:One-carbon_metabolism_by_tetrahydropterines|SUBSYSTEM:Folate_Biosynthesis|!SUBSYSTEM:One-carbon_metabolism_by_tetrahydropterines`H}"],
		["cofactor","cpd00087","FRACTION","AND{SUBSYSTEM:One-carbon_metabolism_by_tetrahydropterines|SUBSYSTEM:Folate_Biosynthesis|!SUBSYSTEM:One-carbon_metabolism_by_tetrahydropterines`H}"],
		["cofactor","cpd00345","FRACTION","AND{SUBSYSTEM:One-carbon_metabolism_by_tetrahydropterines|SUBSYSTEM:Folate_Biosynthesis|!SUBSYSTEM:One-carbon_metabolism_by_tetrahydropterines`H}"],
		["cofactor","cpd00042","FRACTION","OR{SUBSYSTEM:Glutathione:_Biosynthesis_and_gamma-glutamyl_cycle`A`B|SUBSYSTEM:Glutathione:_Non-redox_reactions`A|SUBSYSTEM:Glutathione:_Redox_cycle`A`B}"],
		["cofactor","cpd00028","FRACTION","AND{SUBSYSTEM:Heme_and_Siroheme_Biosynthesis`A`B`F}"],
		["cofactor","cpd00557","FRACTION","AND{SUBSYSTEM:Heme_and_Siroheme_Biosynthesis`A`F}"],
		["cofactor","cpd00264","FRACTION","AND{SUBSYSTEM:Polyamine_Metabolism}"],
		["cofactor","cpd00118","FRACTION","AND{SUBSYSTEM:Polyamine_Metabolism`A`B`C`D`E`F`G}"],
		["cofactor","cpd00056","FRACTION","AND{SUBSYSTEM:Thiamin_biosynthesis}"],
		["cofactor","cpd15560","FRACTION","AND{SUBSYSTEM:Ubiquinone_Biosynthesis}"],
		["cofactor","cpd15352","FRACTION","AND{SUBSYSTEM:Menaquinone_and_Phylloquinone_Biosynthesis}"],
		["cofactor","cpd15500","FRACTION","AND{SUBSYSTEM:Menaquinone_and_Phylloquinone_Biosynthesis|ROLE:Ubiquinone/menaquinone biosynthesis methyltransferase UbiE (EC 2.1.1.-)}"],
		["cofactor","cpd00166","FRACTION","AND{SUBSYSTEM:Coenzyme_B12_biosynthesis}"],
		["lipid","cpd15793","FRACTION","AND{ROLE:Cardiolipin synthetase (EC 2.7.8.-)|SUBSYSTEM:Fatty_Acid_Biosynthesis_FASII}"],
		["lipid","cpd15794","FRACTION","AND{ROLE:Cardiolipin synthetase (EC 2.7.8.-)|SUBSYSTEM:Fatty_Acid_Biosynthesis_FASII}"],
		["lipid","cpd15795","FRACTION","AND{ROLE:Cardiolipin synthetase (EC 2.7.8.-)|SUBSYSTEM:Fatty_Acid_Biosynthesis_FASII}"],
		["lipid","cpd15722","FRACTION","AND{OR{ROLE:Phosphatidylglycerophosphatase B (EC 3.1.3.27)|ROLE:Phosphatidylglycerophosphatase A (EC 3.1.3.27)}|SUBSYSTEM:Fatty_Acid_Biosynthesis_FASII}"],
		["lipid","cpd15723","FRACTION","AND{OR{ROLE:Phosphatidylglycerophosphatase B (EC 3.1.3.27)|ROLE:Phosphatidylglycerophosphatase A (EC 3.1.3.27)}|SUBSYSTEM:Fatty_Acid_Biosynthesis_FASII}"],
		["lipid","cpd15540","FRACTION","AND{OR{ROLE:Phosphatidylglycerophosphatase B (EC 3.1.3.27)|ROLE:Phosphatidylglycerophosphatase A (EC 3.1.3.27)}|SUBSYSTEM:Fatty_Acid_Biosynthesis_FASII}"],
		["lipid","cpd15533","FRACTION","AND{ROLE:Phosphatidylserine decarboxylase (EC 4.1.1.65)|SUBSYSTEM:Fatty_Acid_Biosynthesis_FASII}"],
		["lipid","cpd15695","FRACTION","AND{ROLE:Phosphatidylserine decarboxylase (EC 4.1.1.65)|SUBSYSTEM:Fatty_Acid_Biosynthesis_FASII}"],
		["lipid","cpd15696","FRACTION","AND{ROLE:Phosphatidylserine decarboxylase (EC 4.1.1.65)|SUBSYSTEM:Fatty_Acid_Biosynthesis_FASII}"],
		["cellwall","cpd15748","FRACTION","AND{CLASS:Gram positive|SUBSYSTEM:Fatty_Acid_Biosynthesis_FASII}"],
		["cellwall","cpd15757","FRACTION","AND{CLASS:Gram positive|SUBSYSTEM:Fatty_Acid_Biosynthesis_FASII}"],
		["cellwall","cpd15766","FRACTION","AND{CLASS:Gram positive|SUBSYSTEM:Fatty_Acid_Biosynthesis_FASII}"],
		["cellwall","cpd15775","FRACTION","AND{CLASS:Gram positive|SUBSYSTEM:Fatty_Acid_Biosynthesis_FASII}"],
		["cellwall","cpd15749","FRACTION","AND{CLASS:Gram positive|SUBSYSTEM:Fatty_Acid_Biosynthesis_FASII}"],
		["cellwall","cpd15758","FRACTION","AND{CLASS:Gram positive|SUBSYSTEM:Fatty_Acid_Biosynthesis_FASII}"],
		["cellwall","cpd15767","FRACTION","AND{CLASS:Gram positive|SUBSYSTEM:Fatty_Acid_Biosynthesis_FASII}"],
		["cellwall","cpd15776","FRACTION","AND{CLASS:Gram positive|SUBSYSTEM:Fatty_Acid_Biosynthesis_FASII}"],
		["cellwall","cpd15750","FRACTION","AND{CLASS:Gram positive|SUBSYSTEM:Fatty_Acid_Biosynthesis_FASII}"],
		["cellwall","cpd15759","FRACTION","AND{CLASS:Gram positive|SUBSYSTEM:Fatty_Acid_Biosynthesis_FASII}"],
		["cellwall","cpd15768","FRACTION","AND{CLASS:Gram positive|SUBSYSTEM:Fatty_Acid_Biosynthesis_FASII}"],
		["cellwall","cpd15777","FRACTION","AND{CLASS:Gram positive|SUBSYSTEM:Fatty_Acid_Biosynthesis_FASII}"],
		["cellwall","cpd15667","FRACTION","AND{CLASS:Gram positive|SUBSYSTEM:Fatty_Acid_Biosynthesis_FASII}"],
		["cellwall","cpd15668","FRACTION","AND{CLASS:Gram positive|SUBSYSTEM:Fatty_Acid_Biosynthesis_FASII}"],
		["cellwall","cpd15669","FRACTION","AND{CLASS:Gram positive|SUBSYSTEM:Fatty_Acid_Biosynthesis_FASII}"],
		["cellwall","cpd11459","FRACTION","AND{CLASS:Gram positive}"],
		["cellwall","cpd15432","FRACTION","AND{CLASS:Gram negative}"],
		["cellwall","cpd02229","FRACTION","AND{!NAME:Mycoplasma|!NAME:Spiroplasma|!NAME:Ureaplasma|!NAME:phytoplasma}"],
		["cellwall","cpd15665","FRACTION","AND{!NAME:Mycoplasma|!NAME:Spiroplasma|!NAME:Ureaplasma|!NAME:phytoplasma}"],
		["cellwall","cpd15666","cpd15665,cpd15667,cpd15668,cpd15669","OR{COMPOUND:cpd15665|COMPOUND:cpd15667|COMPOUND:cpd15668|COMPOUND:cpd15669}"],
		["cofactor","cpd01997","cpd00166","AND{COMPOUND:cpd00166}"],
		["cofactor","cpd03422","cpd00166","AND{COMPOUND:cpd00166}"]
	];
	my $templates = [
		$mapping->add("biomassTemplates",{
			class => "Gram positive",
			dna => "0.026",
			rna => "0.0655",
			protein => "0.5284",
			lipid => "0.075",
			cellwall => "0.25",
			cofactor => "0.10"
		}),
		$mapping->add("biomassTemplates",{
			class => "Gram negative",
			dna => "0.031",
			rna => "0.21",
			protein => "0.563",
			lipid => "0.093",
			cellwall => "0.177",
			cofactor => "0.039"
		}),
		$mapping->add("biomassTemplates",{
			class => "Unknown",
			dna => "0.031",
			rna => "0.21",
			protein => "0.563",
			lipid => "0.093",
			cellwall => "0.177",
			cofactor => "0.039"
		})
	];
	foreach my $template (@{$templates}) {
		if (defined($biomassTempComp->{$template->class()})) {
			foreach my $type (keys(%{$biomassTempComp->{$template->class()}})) {
				foreach my $cpd (keys(%{$biomassTempComp->{$template->class()}->{$type}})) {
					my $cpdobj = $biochemistry->getObjectByAlias("compounds",$cpd,"ModelSEED");
					$template->add("biomassTemplateComponents",{
						class => $type,
						coefficientType => "NUMBER",
						coefficient => $biomassTempComp->{$template->class()}->{$type}->{$cpd},
						compound_uuid => $cpdobj->uuid(),
						condition => "UNIVERSAL"
					});
				}
			}
		}
		for (my $i=0; $i < @{$universalBiomassTempComp}; $i++) {
			my $cpdobj = $biochemistry->getObjectByAlias("compounds",$universalBiomassTempComp->[$i]->[1],"ModelSEED");
			my $coefficientType = "FRACTION";
			my $coefficient = 1;
			if ($universalBiomassTempComp->[$i]->[2] =~ m/cpd\d+/) {
				my $array = [split(/,/,$universalBiomassTempComp->[$i]->[2])];
				for (my $j=0; $j < @{$array}; $j++) {
					my $newcpdobj = $biochemistry->getObjectByAlias("compounds",$array->[$j],"ModelSEED");
					$array->[$j] = $newcpdobj->uuid();
				}
				$coefficientType = join(",",@{$array});
			} elsif ($universalBiomassTempComp->[$i]->[2] =~ m/\d/) {
				$coefficientType = "NUMBER";
				$coefficient = $universalBiomassTempComp->[$i]->[2];
			}
			$template->add("biomassTemplateComponents",{
				class => $universalBiomassTempComp->[$i]->[0],
				coefficientType => $coefficientType,
				coefficient => $coefficient,
				compound_uuid => $cpdobj->uuid(),
				condition => "UNIVERSAL"
			});
		}
		for (my $i=0; $i < @{$conditionedBiomassTempComp}; $i++) {
			my $cpdobj = $biochemistry->getObjectByAlias("compounds",$conditionedBiomassTempComp->[$i]->[1],"ModelSEED");
			my $coefficientType = "FRACTION";
			my $coefficient = 1;
			if ($conditionedBiomassTempComp->[$i]->[2] =~ m/cpd\d+/) {
				my $array = [split(/,/,$conditionedBiomassTempComp->[$i]->[2])];
				for (my $j=0; $j < @{$array}; $j++) {
					my $newcpdobj = $biochemistry->getObjectByAlias("compounds",$array->[$j],"ModelSEED");
					$array->[$j] = $newcpdobj->uuid();
				}
				$coefficientType = join(",",@{$array});
			} elsif ($conditionedBiomassTempComp->[$i]->[2] =~ m/\d/) {
				$coefficientType = "NUMBER";
				$coefficient = $conditionedBiomassTempComp->[$i]->[2];
			}
			$template->add("biomassTemplateComponents",{
				class => $conditionedBiomassTempComp->[$i]->[0],
				coefficientType => $coefficientType,
				coefficient => $coefficient,
				compound_uuid => $cpdobj->uuid(),
				condition => $conditionedBiomassTempComp->[$i]->[3]
			});
		}
	};
	my $roles = $self->roleTbl();
    print "Processing ".$roles->size()." roles\n" if($args->{verbose});
	for (my $i=0; $i < $roles->size(); $i++) {
		my $row = $roles->row($i);
		my $role = $mapping->add("roles",{
			locked => "0",
			name => $row->name(),
			seedfeature => $row->exemplarmd5()
		});
		$mapping->addAlias({
			attribute => "roles",
			aliasName => "ModelSEED",
			alias => $row->id(),
			uuid => $role->uuid()
		});
	}
	my $subsystems = $self->subsystemTbl();
    print "Processing ".$subsystems->size()." subsystems\n" if($args->{verbose});
	for (my $i=0; $i < @{$subsystems}; $i++) {
		my $ss = $mapping->add("rolesets",{
			public => "1",
			locked => "0",
			name => $subsystems->[$i]->name(),
			class => $subsystems->[$i]->classOne(),
			subclass => $subsystems->[$i]->classTwo(),
			type => "SEED Subsystem"
		});
		$mapping->addAlias({
			attribute => "rolesets",
			aliasName => "ModelSEED",
			alias => $subsystems->[$i]->id(),
			uuid => $ss->uuid()
		});
	}
	my $ssroles = $self->ssroleTbl();
	for (my $i=0; $i < $ssroles->size(); $i++) {
		my $row = $ssroles->row($i);
		my $ss = $mapping->getObjectByAlias("rolesets",$row->SUBSYSTEM(),"ModelSEED");
        next unless(defined($ss));
        my $role = $mapping->getObjectByAlias("roles",$row->ROLE(),"ModelSEED");
        next unless(defined($role));
        push(@{$ss->role_uuids()},$role->uuid());
	}
	my $complexes = $self->complexTbl();
	for (my $i=0; $i < $complexes->size(); $i++) {
		my $row = $complexes->row($i);
		my $complex = $mapping->add("complexes",{
			locked => "0",
			name => $row->id(),
		});
		$mapping->addAlias({
			attribute => "complexes",
			aliasName => "ModelSEED",
			alias => $row->id(),
			uuid => $complex->uuid()
		});
	}
	my $complexRoles = $self->cpxroleTbl();
	for (my $i=0; $i < $complexRoles->size(); $i++) {
        my $cpx_role = $complexRoles->row($i);
		my $complex = $mapping->getObjectByAlias(
            "complexes",$cpx_role->COMPLEX(),"ModelSEED"
        );
		next unless(defined($complex));
        my $role = $mapping->getObjectByAlias(
            "roles",$cpx_role->ROLE(),"ModelSEED"
        );
        next unless defined($role);
        my $type = "triggering";
        if ($cpx_role->type() eq "L") {
            $type = "involved";	
        }
        $complex->add("complexroles",{
            role_uuid => $role->uuid(),
            optional => "0",
            type => $type
        });
	}
	my $reactionRules = $self->rxncpxTbl();
    print "Processing ".scalar(@$reactionRules)." reactions\n" if($args->{verbose});
	for (my $i=0; $i < rxncpxTbl->size(); $i++) {
        my $rule = $complexRoles->row($i);
		next unless($rule->master() eq "1");
        my $complex = $mapping->getObjectByAlias(
            "complexes", $rule->COMPLEX(), "ModelSEED"
        );
        next unless(defined($complex));
        my $rxn = $biochemistry->getObjectByAlias(
            "reactions", $rule->REACTION(), "ModelSEED"
        );
        next unless(defined($rxn));
        push(@{$complex->reaction_uuids()},$rxn->uuid);
	}
	return $mapping;	
}

sub createAnnotation {
	my ($self,$args) = @_;
	$args = ModelSEED::utilities::ARGS($args,["genome","mapping"],{
		name => undef
	});
	if (!defined($args->{name})) {
		$args->{name} = $self->namespace()."/".$args->{genome}.".annotation";
	}
	my $factory = ModelSEED::MS::Factories::Annotation->new();
	return $factory->buildMooseAnnotation({
		genome_id => $args->{genome},
		mapping => $args->{mapping}
	});
}

# The PPO files use ";" as subdelimiters in some tables
# The model flat-files use "|" in these cases
# Returns a regex that matches the correct thingy.
sub _getDelimiterRegex {
    my ($self, $string) = @_;
    my $DelimiterRegex = qr{;};
    my @array = split(/\|/, $string);
    $DelimiterRegex = qr{\|} if(@array > 1);
    return $DelimiterRegex;
}

__PACKAGE__->meta->make_immutable;
