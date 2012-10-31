########################################################################
# ModelSEED::MS::Factories - This is the factory for producing the moose objects from the SEED data
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-03-15T16:44:01
########################################################################
package ModelSEED::MS::Factories::TableFileFactory;
use common::sense;
use ModelSEED::utilities qw( args verbose );
use ModelSEED::MS::Utilities::GlobalFunctions;
use Class::Autouse qw(
	ModelSEED::MS::BiochemistryStructures
    ModelSEED::MS::Biochemistry
    ModelSEED::MS::Mapping
    ModelSEED::MS::Model
    ModelSEED::MS::Factories::Annotation
    ModelSEED::MS::Annotation
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
has uuidHash => ( is => 'rw', isa => 'HashRef', lazy => 1, builder => '_builduuidHash' );
has biomassTemplateData => ( is => 'rw', isa => 'HashRef', lazy => 1, builder => '_buildbiomassTemplateData' );
has genomeTbl => ( is => 'rw', isa => 'ModelSEED::Table', lazy => 1, builder => '_buildgenomeTbl' );

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
	return ModelSEED::Table->new(filename => $self->filepath()."/cpxrole.tbl",rows_return_as => "ref");
}
sub _buildrxncpxTbl {
	my ($self) = @_;
	return ModelSEED::Table->new(filename => $self->filepath()."/rxncpx.tbl",rows_return_as => "ref");
}

sub _builduuidHash {
	my ($self) = @_;
	my $types = ["compartment","complexes","cpd","media","rolesets","roles","rxn"];
	my $hash = {};
	for (my $i=0; $i < @{$types}; $i++) {
		if (-e $self->filepath()."/".$types->[$i]."uuid.txt") {
			my $data = ModelSEED::utilities::LOADFILE($self->filepath()."/".$types->[$i]."uuid.txt");
			for (my $j=0; $j < @{$data}; $j++) {
				if ($data->[$j] =~ m/\/([^\/]+)\t(.+)/) {
					$hash->{$types->[$i]}->{$2} = $1;
				}
			}
		}
	}
	return $hash;
}

sub _buildgenomeTbl {
	my ($self) = @_;
	return ModelSEED::Table->new(filename => $self->filepath()."/genomes.tbl",rows_return_as => "ref");
}
sub _buildbiomassTemplateData() {
	my ($self) = @_;
	my $filedata = ModelSEED::utilities::LOADFILE($self->filepath()."/biomassTemplateData.txt");
	my $template = {
		"spontaneous reactions" => [],
		"universal reactions" => [],
		"biomass template components" => {},
		"templates" => {},
		"universal biomass components" => [],
		"conditional biomass components" => [],
	};
	for (my $i=0; $i < @{$filedata};$i++) {
		if ($filedata->[$i] =~ m/Spontaneous\sreactions:(.+)/) {
			$template->{"spontaneous reactions"} = [split(/;/,$1)];
		} elsif ($filedata->[$i] =~ m/Universal\sreactions:(.+)/) {
			$template->{"universal reactions"} = [split(/;/,$1)];
		} elsif ($filedata->[$i] =~ m/Biomass\stemplates:(.+)\{/) {
			my $type = $1;
			$i++;
			while ($filedata->[$i] ne "}") {
				if ($filedata->[$i] =~ m/(.+):(.+)/) {
					my $class = $1;
					my $compounds = $2;
					my $array = [split(/;/,$compounds)];
					foreach my $compound (@{$array}) {
						my $subarray = [split(/=/,$compound)];
						if (defined($subarray->[1])) {
							if ($class eq "coefficients") {
								if (!defined($template->{"templates"}->{$type})) {
									$template->{"templates"}->{$type}->{class} = $type;
								}
								$template->{"templates"}->{$type}->{$subarray->[0]} = $subarray->[1];
							} else {
								$template->{"biomass template components"}->{$type}->{$class}->{$subarray->[0]} = $subarray->[1];
							}
						}
					}
				}
				$i++;
			}
		} elsif ($filedata->[$i] =~ m/Universal\sbiomass\scomponents\{/) {
			$i++;
			while ($filedata->[$i] ne "}") {
				my $array = [split(/\t/,$filedata->[$i])];
				push(@{$template->{"universal biomass components"}},$array);
				$i++;
			}
		} elsif ($filedata->[$i] =~ m/Conditional\sbiomass\scomponents\{/) {
			$i++;
			while ($filedata->[$i] ne "}") {
				my $array = [split(/\t/,$filedata->[$i])];
				push(@{$template->{"conditional biomass components"}},$array);
				$i++;
			}
		}
	}
	return $template;
}

#***********************************************************************************************************
# FUNCTIONS:
#***********************************************************************************************************
sub loadFtrTbl {
	my ($self,$id) = @_;
	return ModelSEED::Table->new({filename => $self->filepath()."/".$id.".tbl",rows_return_as => "ref"});
}


sub createModel {
    my $self = shift;
    my $args = args(["id","biochemistry" ], {}, @_);
	my $bio = $args->{biochemistry};
	my $filename = $self->filepath().$args->{id}.".mdl";
	if (!-e $filename) {
		ModelSEED::utilities::ERROR("File for model data not found!");
	}
	my $tbl = ModelSEED::Table->new({filename => $filename,rows_return_as => "ref"});
	#Creating the model
	my $model = ModelSEED::MS::Model->new({
		id => $id,
		name => $id,
		version => 1,
		type => "Singlegenome",
		status => "Model loaded into new database",
		reactions => 0,
		compounds => 0,
		annotations => 0,
		growth => 0,
		current => 1,
		mapping_uuid => $map->uuid(),
		biochemistry_uuid => $bio->uuid(),
		annotation_uuid => $anno->uuid(),
	});
	for (my  $i=0; $i < $tbl->size(); $i++) {
		my $row = $tbl->row($i);
		my $rxn = $bio->getObjectByAlias("reactions",$row->id(),"ModelSEED");
		if (!defined($rxn)) {
			verbose("Reaction ".$row->LOAD()." not found!");
		} else {
			my $direction = "=";
			if ($row->DIRECTIONALITY() eq "=>") {
				$direction = ">";
			} elsif ($row->DIRECTIONALITY() eq "<=") {
				$direction = "<";
			}
			$model->addReactionToModel({
				reaction => $rxn,
				direction => $direction,
				gpr => $row->PEGS()
			});
		}
	}
	$filename = $self->filepath().$args->{id}.".bof";
	if (!-e $filename) {
		ModelSEED::utilities::ERROR("Biomass file for model not found!");
	}
	my $data = ModelSEED::utilities::LOADFILE($filename);
	my $equation;
	for (my $i=0; $i < @{$data};$i++) {
		my $array = [split(/\t/,$data->[$i])];
		if (defined($array->[1])) {
			if ($array->[0] eq "EQUATION") {
				$equation = $array->[0];
			}
		}
	}
	my $bioobj = $model->add("biomasses",{
		name => "bio00001"
	});
	$bioobj->loadFromEquation({
		equation => $equation,
		aliasType => "ModelSEED"
	});
	my $modelreactions = $model->modelreactions();
	my $modelcompounds = $model->modelcompounds();
	$model->reactions(@{$modelreactions});
	$model->compounds(@{$modelcompounds});
	return $model;
}

sub createBiochemistry {
    my $self = shift;
    my $args = args([], {
		name => $self->namespace()."/primary.biochemistry",
		addAliases => 1,
		addStructuralCues => 1,
		addStructure => 1,
		addPK => 1,
        verbose => 0
	}, @_);
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
    my $uuidhash = $self->uuidHash();
	for (my $i=0; $i < @{$comps}; $i++) {
		my $data = {
			locked => "0",
			id => $comps->[$i]->{id},
			name => $comps->[$i]->{name},
			hierarchy => $comps->[$i]->{hierarchy}
		};
		if (defined($uuidhash->{compartment}->{$comps->[$i]->{id}})) {
			$data->{uuid} = $uuidhash->{compartment}->{$comps->[$i]->{id}};
		}
		my $comp = $biochemistry->add("compartments",$data);
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
		print $cpdRow->id()."\n" if($args->{verbose});
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
		if (defined($uuidhash->{cpd}->{$cpdRow->id()})) {
			$cpdData->{uuid} = $uuidhash->{cpd}->{$cpdRow->id()};
		}
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
	print "Handling media formulations!\n" if($args->{verbose});
	#Adding media formulations
	my $medias = $self->mediaTbl();
	my $mediacpdstbl = $self->mediacpdTbl();
	my $rowHash = {};
	for (my $j=0; $j < $mediacpdstbl->size(); $j++) {
		my $mediacpdRow = $mediacpdstbl->row($j);
		push(@{$rowHash->{$mediacpdRow->MEDIA()}},$mediacpdRow);
	}
	for (my $i=0; $i < $medias->size(); $i++) {
		my $mediaRow = $medias->row($i);
		print $mediaRow->id()."\n" if($args->{verbose});
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
		print $rxnRow->id()."\n" if($args->{verbose});
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
		if (defined($uuidhash->{rxn}->{$rxnRow->id()})) {
			$data->{uuid} = $uuidhash->{rxn}->{$rxnRow->id()};
		}
		foreach my $key (keys(%{$data})) {
			if (!defined($data->{$key}) || $data->{$key} eq "") {
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
			next unless(defined($cueListString) && length($cueListString) > 0 && keys(%{$rxn->cues()}) == 0 );
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
    my $self = shift;
    my $args = args(["biochemistry"], {}, @_);
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
    my $self = shift;
    my $args = args(["biochemistry"], {
		name => $self->namespace()."/primary.mapping",
        verbose => 0,
	}, @_);
	my $uuidhash = $self->uuidHash();
	my $biomassTemplateData = $self->biomassTemplateData();
	my $spontaneousRxn = $biomassTemplateData->{"spontaneous reactions"};
	my $universalRxn = $biomassTemplateData->{"universal reactions"};
	my $templateData = $biomassTemplateData->{"templates"};
	my $biomassTempComp = $biomassTemplateData->{"biomass template components"};
	my $universalBiomassTempComp = $biomassTemplateData->{"universal biomass components"};
	my $conditionedBiomassTempComp = $biomassTemplateData->{"conditional biomass components"};
	my $mapping = ModelSEED::MS::Mapping->new({
		name=>$args->{name},
		biochemistry_uuid => $args->{biochemistry}->uuid(),
		biochemistry => $args->{biochemistry}
	});
    my $biochemistry = $mapping->biochemistry;
	for (my $i=0; $i < @{$spontaneousRxn}; $i++) {
		my $rxn = $biochemistry->getObjectByAlias("reactions",$spontaneousRxn->[$i],"ModelSEED");
		if (defined($rxn)) {
			$mapping->add("universalReactions",{
				type => "SPONTANEOUS",
				reaction_uuid => $rxn->uuid()	
			});
		}
	}
	for (my $i=0; $i < @{$universalRxn}; $i++) {
		my $rxn = $biochemistry->getObjectByAlias("reactions",$universalRxn->[$i],"ModelSEED");
		if (defined($rxn)) {
			$mapping->add("universalReactions",{
				type => "UNIVERSAL",
				reaction_uuid => $rxn->uuid()	
			});
		}
	}
	my $templates = [];
	foreach my $template (keys(%{$templateData})) {
		push(@$templates,$mapping->add("biomassTemplates",$templateData->{$template}));
	}
	foreach my $template (@{$templates}) {
		if (defined($biomassTempComp->{$template->class()})) {
			foreach my $type (keys(%{$biomassTempComp->{$template->class()}})) {
				foreach my $cpd (keys(%{$biomassTempComp->{$template->class()}->{$type}})) {
					my $cpdobj = $biochemistry->getObjectByAlias("compounds",$cpd,"ModelSEED");
					if (defined($cpdobj)) {
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
		my $data = {
			locked => "0",
			name => $row->name(),
			seedfeature => $row->exemplarmd5()
		};
		if (defined($uuidhash->{roles}->{$row->id()})) {
			$data->{uuid} = $uuidhash->{roles}->{$row->id()};
		}
		my $role = $mapping->add("roles",$data);
		$mapping->addAlias({
			attribute => "roles",
			aliasName => "ModelSEED",
			alias => $row->id(),
			uuid => $role->uuid()
		});
	}
	my $subsystems = $self->subsystemTbl();
    print "Processing ".$subsystems->size()." subsystems\n" if($args->{verbose});
	for (my $i=0; $i < $subsystems->size(); $i++) {
		my $row = $subsystems->row($i);
		my $data = {
			public => "1",
			locked => "0",
			name => $row->name(),
			class => $row->classOne(),
			subclass => $row->classTwo(),
			type => "SEED Subsystem"
		};
		if (defined($uuidhash->{rolesets}->{$row->name()})) {
			$data->{uuid} = $uuidhash->{rolesets}->{$row->name()};
		}
		my $ss = $mapping->add("rolesets",$data);
		$mapping->addAlias({
			attribute => "rolesets",
			aliasName => "ModelSEED",
			alias => $row->id(),
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
        $ss->addRole($role);
	}
	my $complexes = $self->complexTbl();
	for (my $i=0; $i < $complexes->size(); $i++) {
		my $row = $complexes->row($i);
		my $data = {
			locked => "0",
			name => $row->id(),
		};
		if (defined($uuidhash->{complexes}->{$row->id()})) {
			$data->{uuid} = $uuidhash->{complexes}->{$row->id()};
		}
		my $complex = $mapping->add("complexes",$data);
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
	my $rxncpxTbl = $self->rxncpxTbl();
    print "Processing ".$rxncpxTbl->size()." reactions\n" if($args->{verbose});
	for (my $i=0; $i < $rxncpxTbl->size(); $i++) {
        my $rule = $rxncpxTbl->row($i);
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
    my $self = shift;
    my $args = args(["genome","mapping"], {}, @_);
	if (!-e $self->filepath()."/".$args->{genome}.".tbl") {
		ModelSEED::utilities::ERROR("Input genome ".$args->{genome}." not found in available flatfiles!");
	}
	my $genomeTbl = $self->genomeTbl();
	my $genomeData;
	for (my $i=0; $i < $genomeTbl->size(); $i++) {
		my $row = $genomeTbl->row($i);
		if ($row->id() eq $args->{genome}) {
			$genomeData = $row;
			last;
		}
	}
	my $defaultGenome = {
		id => $args->{genome},
		name => $args->{genome},
		source => "file",
		class => "unknown",
		taxonomy => "unknown",
		size => 0,
		gc => 0.5,
		etcType => "unknown"
	};
	if (defined($genomeData)) {
		$defaultGenome->{name} = $genomeData->name();
		$defaultGenome->{source} = $genomeData->source();
		$defaultGenome->{taxonomy} = $genomeData->taxonomy();
		$defaultGenome->{size} = $genomeData->size();
		$defaultGenome->{class} = $genomeData->class();
		$defaultGenome->{gc} = $genomeData->gc();
		$defaultGenome->{etcType} = $genomeData->etcType();
	}
	# Creating annotation object
	my $anno = ModelSEED::MS::Annotation->new({
		name=>$genomeData->name(),
		mapping_uuid =>$args->{mapping}->uuid(),
		mapping =>$args->{mapping}
	});
	# Adding genome object to annotation
	my $genome = $anno->add("genomes",$defaultGenome);
	# Adding features to annotation
	my $ftrTbl = $self->loadFtrTbl($args->{genome});
	for (my $i=0; $i < $ftrTbl->size(); $i++) {
		my $row = $ftrTbl->row($i);
		my $gene = $anno->add("features",{
			genome_uuid => $genome->uuid(),
			id => $row->id(),
			start => $row->start(),
			stop => $row->stop(),
			contig => $row->contig(),
			direction => $row->direction(),
			type => $row->type(),
		});
		my $roles = [split(/\|/,$row->roles())];
		for (my $j=0; $j < @{$roles}; $j++) {
			my $role = $args->{mapping}->queryObject("roles",{
				name => $roles->[$j]
			});
			if (!defined($role)) {
				$role = $args->{mapping}->add("roles",{
					name => $roles->[$j]
				});
			}
			$gene->add("featureroles",{
				role_uuid => $role->uuid(),
				compartment => "u",
			});
		}
	}
	return $anno;
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
