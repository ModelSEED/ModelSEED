########################################################################
# ModelSEED::MS::Reaction - This is the moose object corresponding to the Reaction object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-03-26T23:22:35
########################################################################
use strict;
use ModelSEED::MS::DB::Reaction;
package ModelSEED::MS::Reaction;
use ModelSEED::utilities qw( args error );
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::DB::Reaction';
#***********************************************************************************************************
# ADDITIONAL ATTRIBUTES:
#***********************************************************************************************************
has definition => ( is => 'rw',printOrder => 3, isa => 'Str', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_builddefinition' );
has equation => ( is => 'rw',printOrder => 4, isa => 'Str', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildequation' );
has equationCode => ( is => 'rw', isa => 'Str', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildequationcode' );
has balanced => ( is => 'rw', isa => 'Bool',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildbalanced' );
has mapped_uuid  => ( is => 'rw', isa => 'ModelSEED::uuid',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildmapped_uuid' );
has compartment  => ( is => 'rw', isa => 'ModelSEED::MS::Compartment',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildcompartment' );
has roles  => ( is => 'rw', isa => 'ArrayRef',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildroles' );
has isTransport  => ( is => 'rw', isa => 'Bool',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildisTransport' );

#***********************************************************************************************************
# BUILDERS:
#***********************************************************************************************************
sub _builddefinition {
	my ($self) = @_;
	return $self->createEquation({format=>"name",hashed=>0});
}
sub _buildequation {
	my ($self) = @_;
	return $self->createEquation({format=>"id",hashed=>0});
}
sub _buildequationcode {
	my ($self,$args) = @_;
	return $self->createEquation({format=>"uuid",hashed=>1});
}
sub _buildbalanced {
	my ($self,$args) = @_;
	my $result = $self->checkReactionMassChargeBalance({rebalanceProtons => 0});
	return $result->{balanced};
}
sub _buildmapped_uuid {
	my ($self) = @_;
	return "00000000-0000-0000-0000-000000000000";
}
sub _buildcompartment {
	my ($self) = @_;
	my $comp = $self->biochemistry()->queryObject("compartments",{name => "Cytosol"});
	if (!defined($comp)) {
		error("Could not find cytosol compartment in biochemistry!");	
	}
	return $comp;
}
sub _buildroles {
	my ($self) = @_;
	my $hash = $self->parent()->reactionRoleHash();
	if (defined($hash->{$self->uuid()})) {
		return [keys(%{$hash->{$self->uuid()}})];
	}
	return [];
}

sub _buildisTransport {
	my ($self) = @_;
	my $rgts = $self->reagents();
	if (!defined($rgts->[0])) {
		return 0;	
	}
	my $cmp = $rgts->[0]->compartment_uuid();
	for (my $i=0; $i < @{$rgts}; $i++) {
		if ($rgts->[0]->compartment_uuid() ne $cmp) {
			return 1;
		}
	}
	return 0;
}

#***********************************************************************************************************
# CONSTANTS:
#***********************************************************************************************************

#***********************************************************************************************************
# FUNCTIONS:
#***********************************************************************************************************

=head3 hasReagent
Definition:
	boolean = ModelSEED::MS::Reaction->hasReagent(string(uuid));
Description:
	Checks to see if a reaction contains a reagent

=cut

sub hasReagent {
    my ($self,$rgt_uuid) = @_;
    my $rgts = $self->reagents();
    if (!defined($rgts->[0])) {
	return 0;	
    }
    for (my $i=0; $i < @{$rgts}; $i++) {
	if ($rgts->[0]->compound_uuid() eq $rgt_uuid) {
	    return 1;
	}
    }
    return 0;
}

=head3 createEquation
Definition:
	string = ModelSEED::MS::Reaction->createEquation({
		format => string(uuid),
		hashed => 0/1(0)
	});
Description:
	Creates an equation for the core reaction with compounds specified according to the input format

=cut

sub createEquation {
    my $self = shift;
    my $args = args([], { format => "uuid", hashed => 0 }, @_);
	my $rgt = $self->reagents();
	my $rgtHash;
        my $rxnCompID = $self->compartment()->id();
        my $hcpd = $self->biochemistry()->checkForProton();
 	if (!defined($hcpd)) {
	    error("Could not find proton in biochemistry!");
	}
	for (my $i=0; $i < @{$rgt}; $i++) {
		my $id = $rgt->[$i]->compound_uuid();
		next if $id eq $hcpd->uuid() && $args->{hashed}==1;
		if ($args->{format} eq "name" || $args->{format} eq "id") {
			my $function = $args->{format};
			$id = $rgt->[$i]->compound()->$function();
		} elsif ($args->{format} ne "uuid") {
			$id = $rgt->[$i]->compound()->getAlias($args->{format});
		}
		if (!defined($rgtHash->{$id}->{$rgt->[$i]->compartment()->id()})) {
			$rgtHash->{$id}->{$rgt->[$i]->compartment()->id()} = 0;
		}
		$rgtHash->{$id}->{$rgt->[$i]->compartment()->id()} += $rgt->[$i]->coefficient();
	}
#Deliberately commented out for the time being, as protons are being added to the reagents list a priori
#	if (defined($self->defaultProtons()) && $self->defaultProtons() != 0 && !$args->{hashed}) {
#		my $id = $hcpd->uuid();
#		if ($args->{format} eq "name" || $args->{format} eq "id") {
#			my $function = $args->{format};
#			$id = $hcpd->$function();
#		} elsif ($args->{format} ne "uuid") {
#			$id = $hcpd->getAlias($args->{format});
#		}
#		$rgtHash->{$id}->{$rxnCompID} += $self->defaultProtons();
#	}
	my $reactcode = "";
	my $productcode = "";
	my $sign = " <=> ";
	my $sortedCpd = [sort(keys(%{$rgtHash}))];
	for (my $i=0; $i < @{$sortedCpd}; $i++) {
		my $comps = [sort(keys(%{$rgtHash->{$sortedCpd->[$i]}}))];
		for (my $j=0; $j < @{$comps}; $j++) {
			my $compartment = "[".$comps->[$j]."]";
			if ($rgtHash->{$sortedCpd->[$i]}->{$comps->[$j]} < 0) {
				my $coef = -1*$rgtHash->{$sortedCpd->[$i]}->{$comps->[$j]};
				if (length($reactcode) > 0) {
					$reactcode .= " + ";	
				}
				$reactcode .= "(".$coef.") ".$sortedCpd->[$i].$compartment;
			} elsif ($rgtHash->{$sortedCpd->[$i]}->{$comps->[$j]} > 0) {
				if (length($productcode) > 0) {
					$productcode .= " + ";	
				}
				$productcode .= "(".$rgtHash->{$sortedCpd->[$i]}->{$comps->[$j]}.") ".$sortedCpd->[$i].$compartment;
			} 
		}
	}
	if ($args->{hashed} == 1) {
		return Digest::MD5::md5_hex($reactcode.$sign.$productcode);
	}
	return $reactcode.$sign.$productcode;
}

=head3 loadFromEquation
Definition:
	ModelSEED::MS::ReactionInstance = ModelSEED::MS::Reaction->loadFromEquation({
		equation => REQUIRED:string:stoichiometric equation with reactants and products,
		aliasType => REQUIRED:string:alias type used in equation
	});
Description:
	Parses the input equation, generates the reaction stoichiometry based on the equation, and returns the reaction instance for the equation

=cut

sub loadFromEquation {
    my $self = shift;
    my $args = args(["equation","aliasType"], {}, @_);
	my $bio = $self->parent();
	my @TempArray = split(/\s+/, $args->{equation});
	my $CurrentlyOnReactants = 1;
	my $Coefficient = 1;
	my $rxnComp;
	my $currCompScore;
	my $parts = [];
	my $cpdCmpHash;
	my $compHash;
	my $compUUIDHash;
	my $cpdHash;
	my $cpdCmpCount;
	for (my $i = 0; $i < @TempArray; $i++) {
	    #some identifiers may include '=' sign, need to skip actual '+' in equation
	    next if $TempArray[$i] eq "+";
		if ($TempArray[$i] =~ m/^\(([\.\d]+)\)$/ || $TempArray[$i] =~ m/^([\.\d]+)$/) {
			$Coefficient = $1;
		} elsif ($TempArray[$i] =~ m/(^[\w\-+]+)/) {
			$Coefficient *= -1 if ($CurrentlyOnReactants);
			my $NewRow = {
				compound => $1,
				compartment => "c",
				coefficient => $Coefficient
			};
			if ($TempArray[$i] =~ m/^[\w\-+]+\[([a-zA-Z]+)\]/) {
				$NewRow->{compartment} = lc($1);
			}
            my $comp = $compHash->{$NewRow->{compartment}};
            unless(defined($comp)) {
                $comp = $bio->queryObject("compartments", {id => $NewRow->{compartment} });
            }
            unless(defined($comp)) {
		ModelSEED::utilities::USEWARNING("Unrecognized compartment '".$NewRow->{compartment}."' used in reaction!");
		$comp = $bio->add("compartments",{
		    locked => "0",
		    id => $NewRow->{compartment},
		    name => $NewRow->{compartment},
		    hierarchy => 3
				  });
	    }
			$compUUIDHash->{$comp->uuid()} = $comp;
			$compHash->{$comp->id()} = $comp;
			$NewRow->{compartment} = $comp;
			my $cpd;
			if ($args->{aliasType} eq "uuid" || $args->{aliasType} eq "name") {
				$cpd = $bio->queryObject("compounds",{$args->{aliasType} => $NewRow->{compound}});
			} else {
				$cpd = $bio->getObjectByAlias("compounds",$NewRow->{compound},$args->{aliasType});
			}
			if (!defined($cpd)) {
				ModelSEED::utilities::USEWARNING("Unrecognized compound '".$NewRow->{compound}."' used in reaction ".$args->{rxnId});
				if(defined($args->{autoadd}) && $args->{autoadd}==1){
				    ModelSEED::utilities::verbose("Compound '".$NewRow->{compound}."' automatically added to database\n");
				    $cpd = $bio->add("compounds",{ locked => "0",
								   name => $NewRow->{compound},
								   abbreviation => $NewRow->{compound}
						     });
				    $bio->addAlias({ attribute => "compounds",
						     aliasName => $args->{aliasType},
						     alias => $NewRow->{compound},
						     uuid => $cpd->uuid()
						   });
				}else{
				    return 0;
				}
			}
			$NewRow->{compound} = $cpd;
			if (!defined($cpdCmpHash->{$cpd->uuid()}->{$comp->uuid()})) {
				$cpdCmpHash->{$cpd->uuid()}->{$comp->uuid()} = 0;
			}
			$cpdCmpHash->{$cpd->uuid()}->{$comp->uuid()} += $Coefficient;
			$cpdHash->{$cpd->uuid()} = $cpd;
			$cpdCmpCount->{$cpd->uuid()."_".$comp->uuid()}++;
			if ($comp->id() eq "c") {
				$currCompScore = 100;
				$rxnComp = $comp;
			} elsif (!defined($rxnComp) || $comp->hierarchy() > $currCompScore) {
				$currCompScore = $comp->hierarchy();
            	$rxnComp = $comp;
			}
			push(@$parts, $NewRow);
			$Coefficient = 1;
		} elsif ($TempArray[$i] =~ m/=/) {
			$CurrentlyOnReactants = 0;
		}
	}
	if (!defined($rxnComp)) {
		$rxnComp = $bio->queryObject("compartments",{id => "c"});
	}
	foreach my $cpduuid (keys(%{$cpdCmpHash})) {
	    foreach my $cmpuuid (keys(%{$cpdCmpHash->{$cpduuid}})) {
	        # Do not include reagents with zero coefficients
	        next if $cpdCmpHash->{$cpduuid}->{$cmpuuid} == 0;
	        # Do not include Hydrogen in reagents
	        $self->add("reagents", {
	            compound_uuid               => $cpduuid,
	            compartment_uuid            => $cmpuuid,
	            coefficient                 => $cpdCmpHash->{$cpduuid}->{$cmpuuid},
	            isCofactor                  => 0,
			   });
	    }
	}
	
	#multiple instances of the same reaction in the same compartment is unacceptable.
	if(scalar( grep { $cpdCmpCount->{$_} >1 } keys %$cpdCmpCount)>0){
	    return 0;
	}else{
	    return 1;
	}
}

=head3 checkReactionMassChargeBalance
Definition:
	{
		balanced => 0/1,
		error => string,
		imbalancedAtoms => {
			C => 1,
			...	
		}
		imbalancedCharge => float
	} = ModelSEED::MS::Reaction->checkReactionMassChargeBalance({
		rebalanceProtons => 0/1(0):boolean flag indicating if protons should be rebalanced if they are the only imbalanced elements in the reaction
	});
Description:
	Checks if the reaction is mass and charge balanced, and rebalances protons if called for, but only if protons are the only broken element in the equation

=cut

sub checkReactionMassChargeBalance {
    my $self = shift;
    my $args = args([], {rebalanceProtons => 0}, @_);
	my $atomHash;
	my $netCharge = 0;
	#Adding up atoms and charge from all reagents
	my $rgts = $self->reagents();
	for (my $i=0; $i < @{$rgts};$i++) {
		my $rgt = $rgts->[$i];
		#Problems are: compounds with noformula, polymers (see next line), and reactions with duplicate compounds in the same compartment
		#Latest KEGG formulas for polymers contain brackets and 'n', older ones contain '*'
		my $cpdatoms = $rgt->compound()->calculateAtomsFromFormula();
		if (defined($cpdatoms->{error})) {
			return {
				balanced => 0,
				error => $cpdatoms->{error}
			};	
		}
		foreach my $atom (keys(%{$cpdatoms})) {
			if (!defined($atomHash->{$atom})) {
				$atomHash->{$atom} = 0;
			}
			$netCharge += $rgt->coefficient()*$rgt->compound()->defaultCharge();
			$atomHash->{$atom} += $rgt->coefficient()*$cpdatoms->{$atom};
		}
	}
	#Adding protons
	$netCharge += $self->defaultProtons()*1;
	if (!defined($atomHash->{H})) {
		$atomHash->{H} = 0;
	}
	$atomHash->{H} += $self->defaultProtons();
	#Checking if charge or atoms are unbalanced
	my $results = {
		balanced => 1
	};
	my $onlyH = 1;
	my $HImbalance = 0;
	foreach my $atom (keys(%{$atomHash})) { 
		if ($atomHash->{$atom} > 0.00000001 || $atomHash->{$atom} < -0.00000001) {
			if ($atom eq "H") {
				$HImbalance = $atomHash->{$atom};
			} else {
				$onlyH = 0;
			}
		}
	}
	if ($HImbalance != 0 && $onlyH == 1 && $HImbalance == $netCharge) {
		print "Adjusting ".$self->id()." protons by ".$HImbalance."\n";
		my $currentProtons = $self->defaultProtons();
		$currentProtons += -1*$HImbalance;
		$self->defaultProtons($currentProtons);
		$netCharge = 0;
		$atomHash->{H} = 0;
	}
	my $status = "OK";
	foreach my $atom (keys(%{$atomHash})) { 
		if ($atomHash->{$atom} > 0.00000001 || $atomHash->{$atom} < -0.00000001) {
			if ($status eq "OK") {
				$status = "MI:";	
			} else {
				$status .= "|";
			}
			$results->{balanced} = 0;
			$results->{imbalancedAtoms}->{$atom} = $atomHash->{$atom};
			$status .= $atom.":".$atomHash->{$atom};
		}
	}
	if ($netCharge != 0) {
		if ($status eq "OK") {
			$status = "CI:".$netCharge;	
		} else {
			$status .= "|CI:".$netCharge;
		}
		$results->{balanced} = 0;
		$results->{imbalancedCharge} = $netCharge;
		
	}
	$self->status($status);
	return $results;
}

sub checkForDuplicateReagents{
    my $self=shift;
    my %cpdCmpCount=();
    foreach my $rgt (@{$self->reagents()}){
	$cpdCmpCount{$rgt->compound_uuid()."_".$rgt->compartment_uuid()}++;
    }

    if(scalar( grep { $cpdCmpCount{$_} >1 } keys %cpdCmpCount)>0){
	return 1;
    }else{
	return 0;
    }
}

__PACKAGE__->meta->make_immutable;
1;
