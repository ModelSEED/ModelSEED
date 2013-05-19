########################################################################
# ModelSEED::MS::Factories::SBMLFactory
# 
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location:
#   Mathematics and Computer Science Division, Argonne National Lab;
#   Computation Institute, University of Chicago
#
# Date of module creation: 2012-06-03
########################################################################

=head1 ModelSEED::MS::Factories::SBMLFactory

A Factory that creates a model, mapping, annotation, and biochemistry from an SBML file.

=head2 Methods

=head3 new
	
	$sbmlfactory = ModelSEED::MS::Factories::SBMLFactory->new();
	
Creates new L<ModelSEED::MS::Factories::SBMLFactory> object. No arugments are accepted.

=head3 createModel

    ($biochemistry,$model,$anno,$mapping) = $fact->parseSBML(\%arguments);

Construct L<ModelSEED::MS::Model>, L<ModelSEED::MS::Mapping>, L<ModelSEED::MS::Annotation>, and L<ModelSEED::MS::Biochemistry> objects.
Arguments is a hash ref that accepts the following:

=over 4

=item filename

The filename of the SBML file to be imported. Required.

=item modelid

ID of the model being imported, used to reference aliases for model compounds and reactions. Optional.

=back

=cut

package ModelSEED::MS::Factories::SBMLFactory;
use ModelSEED::utilities;
use XML::DOM;
use XML::Parser;
use Class::Autouse qw(
    ModelSEED::Auth::Factory
    ModelSEED::Auth
    ModelSEED::MS::Model
    ModelSEED::MS::Biomass
    ModelSEED::MS::Annotation
    ModelSEED::MS::Mapping
);
use Try::Tiny;
use Moose;
use namespace::autoclean;

sub parseSBML {
    my $self = shift;
    my $args = args(["filename"],{
    	modelid => undef,
    }, @_);
	#Opening and parsing file
	my $doc = $self->openParseSBMLFile({
		filename => $args->{filename}
	});
    #Parsing model name
    my $mdlData = $self->parseModelName({
    	document => $doc
    });
    #Building objects 
    if (!defined($args->{modelid}) && defined($mdlData->{id})) {
		$args->{modelid} = $mdlData->{id};
	}
    my $bio = ModelSEED::MS::Biochemistry->new({
    	defaultNameSpace => $args->{modelid},
    	name => $mdlData->{name}
    });
    my $map = ModelSEED::MS::Mapping->new({
		defaultNameSpace => $args->{modelid},
		name => $mdlData->{name},
		biochemistry_uuid => $bio->uuid(),
		biochemistry => $bio
	});
    my $anno = ModelSEED::MS::Annotation->new({
		defaultNameSpace => $args->{modelid},
		name => $mdlData->{name},
		mapping_uuid => $map->uuid(),
		mapping => $map
	});
	$anno->add("genomes",{
		id => $args->{modelid},
		name => $mdlData->{name},
		source => "SBML"
	});
	my $mdl = ModelSEED::MS::Model->new({
		defaultNameSpace => $args->{modelid},
		name => $mdlData->{name},
		id => $args->{modelid},
		biochemistry_uuid => $bio->uuid(),
		biochemistry => $bio,
		annotation_uuid => $anno->uuid(),
		annotation => $anno
	});
    #Parsing compartments
    my ($bioCmpHash,$mdlCmpHash) = $self->parseCompartments({
    	document => $doc,
    	model => $mdl,
    	biochemistry => $bio
    });
    #Parsing compounds
    my ($bioCpdHash,$bioCpdCmpHash,$mdlCpdHash) = $self->parseCompounds({
    	document => $doc,
    	model => $mdl,
    	biochemistry => $bio,
    	biocmphash => $bioCmpHash,
    	mdlcmphash => $mdlCmpHash
    });
    #Parsing reactions
    my ($bioRxnHash,$mdlRxnHash) = $self->parseReactions({
    	document => $doc,
    	annotation => $anno,
    	model => $mdl,
    	biochemistry => $bio,
    	biocmphash => $bioCmpHash,
    	mdlcmphash => $mdlCmpHash,
    	biocpdhash => $bioCpdHash,
    	biocpdcmphash => $bioCpdCmpHash,
    	mdlcpdhash => $mdlCpdHash
    });
	return ($bio,$mdl,$anno,$map);
}

sub openParseSBMLFile {
	my $self = shift;
	my $args = args(["filename"],{
    	namespace => undef,
       	annotation => undef
    }, @_);
	if (!-e $args->{filename}) {
		ModelSEED::utilities::ERROR("SBML file not found!");
	}
    my $parser = new XML::DOM::Parser;
	return $parser->parsefile($args->{filename});
}

sub parseModelName {
	my $self = shift;
	my $args = args(["document"],{}, @_);
	my $doc = $args->{document};
    my $mdls = [$doc->getElementsByTagName("model")];
    my $data = {
    	id => "Unknown",
    	name => "Unknown"
    };
    if (defined($mdls->[0])) {
		foreach my $attr ($mdls->[0]->getAttributes()->getValues()) {
			my $name = $attr->getName();
    		my $value = $attr->getValue();
			if ($name eq "id") {
				$data->{id} = $value;
			} elsif ($name eq "name") {
				$data->{name} = $value;
			}
		}
		if ($data->{id} eq "Unknown" && $data->{name} ne "Unkown") {
			$data->{id} = $data->{name};
		} elsif ($data->{name} eq "Unknown" && $data->{id} ne "Unkown") {
			$data->{name} = $data->{id};
		}
	}
    return $data;
}

sub parseCompartments {
    my $self = shift;
	my $args = args(["document","biochemistry"],{"model" => undef}, @_);
    my $trans = $self->compartmentTranslation();
    my $doc = $args->{document};
    my $bio = $args->{biochemistry};
    my $mdl = $args->{model};
    my $cmpts = [$doc->getElementsByTagName("compartment")];
    my $bioCmpHash = {};
    my $mdlCmpHash = {};
    foreach my $cmpt (@$cmpts){
    	my $data = {hierarchy => 1};
    	foreach my $attr ($cmpt->getAttributes()->getValues()) {
    		my $name = $attr->getName();
    		my $value = $attr->getValue();
    		if ($name eq "id") {
    			if (defined($trans->{$value})) {
    				$data->{id} = $trans->{$value}->{id};
    				$data->{name} = $trans->{$value}->{name};
    			} else {
    				$data->{id} = $value;
    			}
    		} elsif ($name eq "name") {
    			if (defined($trans->{$value})) {
    				$data->{id} = $trans->{$value}->{id};
    				$data->{name} = $trans->{$value}->{name};
    			} else {
    				$data->{name} = $value;
    			}
    		}
    	}
    	if (!defined($data->{name})) {
    		$data->{name} = $data->{id};
    	}
    	if (defined($data->{id})) {
    		$bioCmpHash->{$data->{id}} = $bio->add("compartments",$data);
    		if (defined($mdl)) {
	    		$mdlCmpHash->{$data->{id}} = $mdl->add("modelcompartments",{
	    			compartment_uuid => $bioCmpHash->{$data->{id}}->uuid(),
	    			compartmentIndex => 0,
	    			label => $data->{name}."0",
	    			pH => 7,
	    			potential => 0
	    		});
	    	}
    	}
	}
	return ($bioCmpHash,$mdlCmpHash);
}
    
sub parseCompounds {
    my $self = shift;
	my $args = args(["document","biochemistry","biocmphash","mdlcmphash"],{
		"model" => undef
	}, @_);
	my $trans = $self->compartmentTranslation();
    my $doc = $args->{document};
    my $bio = $args->{biochemistry};
    my $mdl = $args->{model};
    my $bioCmpHash = $args->{biocmphash};
	my $mdlCmpHash = $args->{mdlcmphash};
	my $bioCpdHash = {};
	my $mdlCpdHash = {};
	my $bioCpdCmpHash = {};
    my $cpds = [$doc->getElementsByTagName("species")];
    foreach my $cpd (@$cpds){
    	my $formula = "Unknown";
    	my $charge = "0";
    	my $sbmlid = "0";
    	my $compartment = "c";
    	my $id = undef;
    	my $name = "Unknown";
    	foreach my $attr ($cpd->getAttributes()->getValues()) {
    		my $nm = $attr->getName();
    		my $value = $attr->getValue();
    		if ($nm eq "id") {
    			$sbmlid = $value;
    			$id = $value;
    			if ($id =~ m/^M_(.+)/) {
    				$id = $1;
    			}
    			if ($id =~ m/(.+)_([a-z])$/) {
    				$id = $1;
    			}
    		} elsif ($nm eq "name") {
    			$name = $value;
    			if ($name =~ m/^M_(.+)/) {
    				$name = $1;
    			}
    			if ($name =~ m/(.+)_([A-Z0123456789]+)$/) {
    				$name = $1;
    				$formula = $2;
    			}
    		} elsif ($nm eq "compartment") {
    			$compartment = $value;
    			if (defined($trans->{$compartment})) {
    				$compartment = $trans->{$compartment}->{id};
    			}
    		} elsif ($nm eq "charge") {
    			$charge = $value;
    		} elsif ($nm eq "formula") {
    			$formula = $value;
    		} elsif ($nm eq "boundaryCondition") {
    			
    		}
    	}	
    	if (defined($id)) {
    		if (!defined($bioCmpHash->{$compartment})) {
    			ModelSEED::utilities::ERROR("Unrecognized compartment '".$compartment."' in compound portion of SBML file!");
    		}
    		if (!defined($bioCpdHash->{$id})) {
    			$bioCpdHash->{$id} = $bio->add("compounds",{
    				name => $name,
    				abbreviation => $id,
    				formula => $formula,
    				defaultCharge => $charge,
    				isCofactor => 0
    			});
    			$bio->addAlias({
					attribute => "compounds",
					aliasName => $bio->defaultNameSpace(),
					alias => $id,
					uuid => $bioCpdHash->{$id}->uuid()
				});
    		}
    		$bioCpdCmpHash->{$sbmlid}->{compound} = $bioCpdHash->{$id};
    		$bioCpdCmpHash->{$sbmlid}->{compartment} = $bioCmpHash->{$compartment};
			if (defined($mdl)) {	
	    		my $mdlcpd = $mdl->add("modelcompounds",{
	    			compound_uuid => $bioCpdHash->{$id}->uuid(),
	    			charge => $charge,
	    			formula => $formula,
	    			modelcompartment_uuid => $mdlCmpHash->{$compartment}->uuid()
	    		});
	    		$mdlCpdHash->{$sbmlid} = $mdlcpd;
	    	}
    	}
    }
    return ($bioCpdHash,$bioCpdCmpHash,$mdlCpdHash);
}

sub parseReactions {
	my $self = shift;
	my $args = args(["document","biochemistry","biocmphash","mdlcmphash","biocpdhash","biocpdcmphash","mdlcpdhash"],{
		"model" => undef,
		"annotation" => undef,
	}, @_);
	my $doc = $args->{document};
	my $bio = $args->{biochemistry};
	my $mdl = $args->{model};
	my $anno = $args->{annotation};
	my $bioCmpHash = $args->{biocmphash};
	my $mdlCmpHash = $args->{mdlcmphash};
	my $bioCpdHash = $args->{biocpdhash};
	my $mdlCpdHash = $args->{mdlcpdhash};
	my $bioCpdCmpHash = $args->{biocpdcmphash};
	my $bioRxnHash = {};
	my $mdlRxnHash = {};
    my $rxns = [$doc->getElementsByTagName("reaction")];
    my $pathwayRxn = {};
    foreach my $rxn (@$rxns){
    	my $id = undef;
    	my $name = "Unknown";
    	my $direction = "=";
    	my $protons = 0;
    	my $reactants = {};
    	my $compartment = "c";
    	my $fbaData = {};
    	my $enzymes = [];
    	my $gpr = [];
    	my $protein = "Unknown";
    	foreach my $attr ($rxn->getAttributes()->getValues()) {
    		my $nm = $attr->getName();
    		my $value = $attr->getValue();
    		if ($nm eq "id") {
    			if ($value =~ m/^R_(.+)/) {
    				$value = $1;
    			}
    			$id = $value;
    		} elsif ($nm eq "name") {
    			if ($value =~ m/^R_(.+)/) {
    				$value = $1;
    			}
    			$value =~ s/_/-/g;
    			$name = $value;
    		} elsif ($nm eq "reversible") {
    			if ($value ne "true") {
    				$direction = ">";
    			}
    		} else {
    			print $nm.":".$value."\n";
    		}
    	}
    	foreach my $node ($rxn->getElementsByTagName("*",0)){
    		if ($node->getNodeName() eq "listOfReactants" || $node->getNodeName() eq "listOfProducts") {
    			foreach my $species ($node->getElementsByTagName("speciesReference",0)){
    				my $spec;
    				my $stoich;
    				foreach my $attr ($species->getAttributes()->getValues()) {
    					if ($attr->getName() eq "species") {
    						$spec = $attr->getValue();
    					} elsif ($attr->getName() eq "stoichiometry") {
    						my $sign = 1;
    						if ($node->getNodeName() eq "listOfReactants") {
    							$sign = -1;
    						}
    						$stoich = $sign*$attr->getValue();
    					}
    				}
    				if (defined($spec) && defined($stoich)) {
    					$reactants->{$spec} = $stoich;
    				}
    			}
    		} elsif ($node->getNodeName() eq "kineticLaw") {
    			my @newnodes = $node->getElementsByTagName("listOfParameters",0);
    			my $newnode = $newnodes[0];
    			if (defined($newnode)) {
    				foreach my $parameter ($newnode->getElementsByTagName("parameter",0)){
    					foreach my $attr ($parameter->getAttributes()->getValues()) {
    						my $name = $attr->getName();
    						my $value = $attr->getValue();
    						$fbaData->{$name} = $value;
    					}
    				}
    			}
    		} elsif ($node->getNodeName() eq "notes") {
    			foreach my $html ($node->getElementsByTagName("*",0)){
    				my $text = $html->getFirstChild()->getNodeValue();
					if ($text =~ m/GENE_ASSOCIATION:\s*(.+)/) {
						my $gprText = $1;
						if (length($gprText) > 0 && $gprText !~ m/^\s+$/) {
							$gpr = $self->translateGPRHash($self->parseGPR($gprText));
						}
					} elsif ($text =~ m/PROTEIN_ASSOCIATION:\s*/) {
						$protein = $1;
					} elsif ($text =~ m/PROTEIN_CLASS:\s*(.+)/) {
						my $array = [split(/\s/,$1)];
						foreach my $enzyme (@{$array}) {
							if (length($enzyme) > 0) {
								push(@{$enzymes},$enzyme);
							}
						}
					} elsif ($text =~ m/SUBSYSTEM:\s*(.+)/) {
						my $subsystem = $1;
						$subsystem =~ s/^S_//;
						$pathwayRxn->{$subsystem}->{$id} = 1;
					}
    			}
    		}
    	}
    	if (defined($id)) {
    		$bioRxnHash->{$id} = $bio->add("reactions",{
    			name => $name,
    			abbreviation => $id,
    			direction => $direction,
    			thermoReversibility => "=",
    			defaultProtons => $protons,
    			status => "Imported from SBML"
    		});
    		$bio->addAlias({
				attribute => "reactions",
				aliasName => $bio->defaultNameSpace(),
				alias => $id,
				uuid => $bioRxnHash->{$id}->uuid()
			});
			foreach my $enzyme (@{$enzymes}) {
				$bio->addAlias({
					attribute => "reactions",
					aliasName => "Enzyme Class",
					alias => $enzyme,
					uuid => $bioRxnHash->{$id}->uuid()
				});
			}
			foreach my $reactant (keys(%{$reactants})) {
				$bioRxnHash->{$id}->add("reagents",{
					compound_uuid => $bioCpdCmpHash->{$reactant}->{compound}->uuid(),
					compartment_uuid => $bioCpdCmpHash->{$reactant}->{compartment}->uuid(),
					coefficient => $reactants->{$reactant},
					isCofactor => 0
				});
			}
    		if (defined($mdl)) {	
	    		$mdlRxnHash->{$id} = $mdl->add("modelreactions",{
	    			reaction_uuid => $bioRxnHash->{$id}->uuid(),
	    			direction => $direction,
	    			protons => $protons,
	    			modelcompartment_uuid => $mdlCmpHash->{$compartment}->uuid()
	    		});
	    		foreach my $reactant (keys(%{$reactants})) {
					$mdlRxnHash->{$id}->add("modelReactionReagents",{
						modelcompound_uuid => $mdlCpdHash->{$reactant}->uuid(),
						coefficient => $reactants->{$reactant},
					});
				}
				for (my $i=0; $i < @{$gpr}; $i++) {
					my $protObj = $mdlRxnHash->{$id}->add("modelReactionProteins",{
						complex_uuid => "00000000-0000-0000-0000-000000000000",
						note => "Imported from SBML"
					});
					for (my $j=0; $j < @{$gpr->[$i]}; $j++) {
						my $subObj = $protObj->add("modelReactionProteinSubunits",{
							role_uuid => "00000000-0000-0000-0000-000000000000",
							note => "Imported from SBML"
						});
						for (my $k=0; $k < @{$gpr->[$i]->[$j]}; $k++) {
							my $ftrID = $gpr->[$i]->[$j]->[$k];
							my $ftrObj = $anno->add("features",{
								id => $ftrID,
								genome_uuid => $anno->genomes()->[0]->uuid(),
							});
							my $ftr = $subObj->add("modelReactionProteinSubunitGenes",{
								feature_uuid => $ftrObj->uuid()
							});
						}
					}
				}
	    	}
    	}
    }
    my $index = 1;
    foreach my $subsys (keys(%{$pathwayRxn})) {
    	my $reactionList = [];
    	foreach my $rxnid (keys(%{$pathwayRxn->{$subsys}})) {
    		my $rxnobj = $bioRxnHash->{$rxnid};
    		push(@{$reactionList},$rxnobj->uuid());
    	}
    	$bio->add("reactionSets",{
    		id => "sbml".$index,
    		name => $subsys,
    		type => "SBML pathway",
    		reactions_uuids => $reactionList
    	});
    	$index++;
    }
    return ($bioRxnHash,$mdlRxnHash);
}

=head3 parseGPR

Definition:
	{}:Logic hash = ModelSEED::MS::Factories::SBMLFactory->parseGPR();
Description:
	Parses GPR string into a hash where each key is a node ID,
	and each node ID points to a logical expression of genes or other
	node IDs. 
	
	Logical expressions only have one form of logic, either "or" or "and".

	Every hash returned has a root node called "root", and this is
	where the gene protein reaction boolean rule starts.
Example:
	GPR string "(A and B) or (C and D)" is translated into:
	{
		root => "node1|node2",
		node1 => "A+B",
		node2 => "C+D"
	}
	
=cut

sub parseGPR {
	my $self = shift;
	my $gpr = shift;
	$gpr =~ s/\s+and\s+/;/g;
	$gpr =~ s/\s+or\s+/:/g;
	$gpr =~ s/\s+\)/)/g;
	$gpr =~ s/\)\s+/)/g;
	$gpr =~ s/\s+\(/(/g;
	$gpr =~ s/\(\s+/(/g;
	my $index = 1;
	my $gprHash = {_baseGPR => $gpr};
	while ($gpr =~ m/\(([^\)^\(]+)\)/) {
		my $node = $1;
		my $text = "\\(".$node."\\)";
		if ($node !~ m/;/ && $node !~ m/:/) {
			$gpr =~ s/$text/$node/g;
		} else {
			my $nodeid = "node".$index;
			$index++;
			$gpr =~ s/$text/$nodeid/g;
			$gprHash->{$nodeid} = $node;
		}
	}
	$gprHash->{root} = $gpr;
	$index = 0;
	my $nodelist = ["root"];
	while (defined($nodelist->[$index])) {
		my $currentNode = $nodelist->[$index];
		my $data = $gprHash->{$currentNode};
		my $delim = "";
		if ($data =~ m/;/) {
			$delim = ";";
		} elsif ($data =~ m/:/) {
			$delim = ":";
		}
		if (length($delim) > 0) {
			my $split = [split(/$delim/,$data)];
			foreach my $item (@{$split}) {
				if (defined($gprHash->{$item})) {
					my $newdata = $gprHash->{$item};
					if ($newdata =~ m/$delim/) {
						$gprHash->{$currentNode} =~ s/$item/$newdata/g;
						delete $gprHash->{$item};
						$index--;
					} else {
						push(@{$nodelist},$item);
					}
				}
			}
		} elsif (defined($gprHash->{$data})) {
			push(@{$nodelist},$data);
		}
		$index++;
	}
	foreach my $item (keys(%{$gprHash})) {
		$gprHash->{$item} =~ s/;/+/g;
		$gprHash->{$item} =~ s/:/|/g;
	}
	return $gprHash;
}

=head3 translateGPRHash

Definition:
	[[[]]]:Protein subunit gene array = ModelSEED::MS::Factories::SBMLFactory->translateGPRHash({}:GPR hash);
Description:
	Translates the GPR hash generated by "parseGPR" into a three level array ref.
	The three level array ref represents the three levels of GPR rules in the ModelSEED.
	The outermost array represents proteins (with 'or' logic).
	The next level array represents subunits (with 'and' logic).
	The innermost array represents gene homologs (with 'or' logic).
	In order to be parsed into this form, the input GPR hash must include logic
	of the forms: "or(and(or))" or "or(and)" or "and" or "or"
	
Example:
	GPR hash:
	{
		root => "node1|node2",
		node1 => "A+B",
		node2 => "C+D"
	}
	Is translated into the array:
	[
		[
			["A"],
			["B"]
		],
		[
			["C"],
			["D"]
		]
	]

=cut

sub translateGPRHash {
	my $self = shift;
	my $gprHash = shift;
	my $root = $gprHash->{root};
	my $proteins = [];
	if ($root =~ m/\|/) {
		my $proteinItems = [split(/\|/,$root)];
		my $found = 0;
		foreach my $item (@{$proteinItems}) {
			if (defined($gprHash->{$item})) {
				$found = 1;
				last;
			}
		}
		if ($found == 0) {
			$proteins->[0]->[0] = $proteinItems
		} else {
			foreach my $item (@{$proteinItems}) {
				push(@{$proteins},$self->parseSingleProtein($item,$gprHash));
			}
		}
	} elsif ($root =~ m/\+/) {
		$proteins->[0] = $self->parseSingleProtein($root,$gprHash);
	} elsif (defined($gprHash->{$root})) {
		$gprHash->{root} = $gprHash->{$root};
		return $self->translateGPRHash($gprHash);
	} else {
		$proteins->[0]->[0]->[0] = $root;
	}
	return $proteins;
}

=head3 parseSingleProtein

Definition:
	[[]]:Subunit gene array = ModelSEED::MS::Factories::SBMLFactory->parseSingleProtein({}:GPR hash);
Description:
	Translates the GPR hash generated by "parseGPR" into a two level array ref.
	The two level array ref represents the two levels of GPR rules in the ModelSEED.
	The outermost array represents subunits (with 'and' logic).
	The innermost array represents gene homologs (with 'or' logic).
	In order to be parsed into this form, the input GPR hash must include logic
	of the forms: "and(or)" or "and" or "or"
	
Example:
	GPR hash:
	{
		root => "A+B",
	}
	Is translated into the array:
	[
		["A"],
		["B"]
	]

=cut

sub parseSingleProtein {
	my $self = shift;
	my $node = shift;
	my $gprHash = shift;
	my $subunits = [];
	if ($node =~ m/\+/) {
		my $items = [split(/\+/,$node)];
		my $index = 0;
		foreach my $item (@{$items}) {
			if (defined($gprHash->{$item})) {
				my $subunitNode = $gprHash->{$item};
				if ($subunitNode =~ m/\|/) {
					my $suitems = [split(/\|/,$subunitNode)];
					my $found = 0;
					foreach my $suitem (@{$suitems}) {
						if (defined($gprHash->{$item})) {
							$found = 1;
						}
					}
					if ($found == 0) {
						$subunits->[$index] = $suitems;
						$index++;
					} else {
						print "Incompatible GPR:".$gprHash->{_baseGPR}."\n";
					}
				} elsif ($subunitNode =~ m/\+/) {
					print "Incompatible GPR:".$gprHash->{_baseGPR}."\n";
				} else {
					$subunits->[$index]->[0] = $subunitNode;
					$index++;
				}
			} else {
				$subunits->[$index]->[0] = $item;
				$index++;
			}
		}
	} elsif (defined($gprHash->{$node})) {
		return $self->parseSingleProtein($gprHash->{$node},$gprHash)
	} else {
		$subunits->[0]->[0] = $node;
	}
	return $subunits;
}

sub compartmentTranslation {
	my $self = shift;
	my $trans = {
		Extra_organism => {
			name => "Extracellular",
			id => "e"
		},
		Cytosol => {
			name => "Cytosol",
			id => "c"
		},
	};
	return $trans;
}

1;
