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
use ModelSEED::utilities;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::DB::Reaction';
#***********************************************************************************************************
# ADDITIONAL ATTRIBUTES:
#***********************************************************************************************************
has definition => ( is => 'rw',printOrder => 3, isa => 'Str', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_builddefinition' );
has equation => ( is => 'rw',printOrder => 4, isa => 'Str', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildequation' );
has equationDir => ( is => 'rw',printOrder => 4, isa => 'Str', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildequationdirection' );
has equationCode => ( is => 'rw', isa => 'Str', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildequationcode' );
has revEquationCode => ( is => 'rw', isa => 'Str', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildrevequationcode' );
has equationCompFreeCode => ( is => 'rw', isa => 'Str', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildcompfreeequationcode' );
has revEquationCompFreeCode => ( is => 'rw', isa => 'Str', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildrevcompfreeequationcode' );
has equationFormula => ( is => 'rw', isa => 'Str', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildequationformula' );
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

sub _buildequationdirection {
	my ($self) = @_;
	return $self->createEquation({format=>"id",hashed=>0,direction=>1});
}

sub _buildequationcode {
	my ($self) = @_;
	return $self->createEquation({format=>"uuid",hashed=>1});
}

sub _buildrevequationcode {
	my ($self) = @_;
	return $self->createEquation({format=>"uuid",hashed=>1,reverse=>1});
}

sub _buildcompfreeequationcode {
	my ($self) = @_;
	return $self->createEquation({format=>"uuid",hashed=>1,compts=>0});
}

sub _buildrevcompfreeequationcode {
	my ($self) = @_;
	return $self->createEquation({format=>"uuid",hashed=>1,compts=>0,reverse=>1});
}

sub _buildequationformula {
    my ($self,$args) = @_;
    return $self->createEquation({format=>"formula",hashed=>0,water=>0});
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
		ModelSEED::utilities::error("Could not find cytosol compartment in biochemistry!");	
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
		if ($rgts->[$i]->compartment_uuid() ne $cmp) {
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
	if ($rgts->[$i]->compound_uuid() eq $rgt_uuid) {
	    return 1;
	}
    }
    return 0;
}

=head3 hasReagentInCompartment

Definition:
	boolean = ModelSEED::MS::Reaction->hasReagentInCompartment(string(uuid), string(uuid));
Description:
	Checks to see if a reaction contains a reagent in a specific oompartment
=cut

sub hasReagentInCompartment {
    my ($self,$rgt_uuid,$cmp_uuid) = @_;
    my $rgts = $self->reagents();
    if (!defined($rgts->[0])) {
	return 0;	
    }
    for (my $i=0; $i < @{$rgts}; $i++) {
	if ($rgts->[$i]->compound_uuid() eq $rgt_uuid && $rgts->[$i]->compartment_uuid() eq $cmp_uuid) {
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
    my $args = ModelSEED::utilities::args([], { format => "uuid", hashed => 0, water => 0, compts=>1, reverse=>0, direction=>0 }, @_);
	my $rgt = $self->reagents();
	my $rgtHash;
        my $rxnCompID = $self->compartment()->id();
        my $hcpd = $self->biochemistry()->checkForProton();
 	if (!defined($hcpd) && $args->{hashed}==1) {
	    ModelSEED::utilities::error("Could not find proton in biochemistry!");
	}
        my $wcpd = $self->biochemistry()->checkForWater();
 	if (!defined($wcpd) && $args->{water}==1) {
	    ModelSEED::utilities::error("Could not find water in biochemistry!");
	}
	for (my $i=0; $i < @{$rgt}; $i++) {
		my $id = $rgt->[$i]->compound_uuid();
		next if $args->{hashed}==1 && $id eq $hcpd->uuid() && !$self->isTransport();
		next if $args->{hashed}==1 && $args->{water}==1 && $id eq $wcpd->uuid();
		if ($args->{format} eq "name" || $args->{format} eq "id") {
			my $function = $args->{format};
			$id = $rgt->[$i]->compound()->$function();
		} elsif ($args->{format} ne "uuid") {
		    if($args->{format} ne "formula"){
			$id = $rgt->[$i]->compound()->getAlias($args->{format});
		    }
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
    if($args->{direction}==1){
	$sign = " => " if $self->direction() eq ">";
	$sign = " <= " if $self->direction() eq "<";
    }
	my $sortedCpd = [sort(keys(%{$rgtHash}))];
	for (my $i=0; $i < @{$sortedCpd}; $i++) {
	    my $printId=$sortedCpd->[$i];
	    if($args->{format} eq "formula"){
		$printId=$self->biochemistry()->getObject("compounds",$sortedCpd->[$i])->formula();
	    }
		my $comps = [sort(keys(%{$rgtHash->{$sortedCpd->[$i]}}))];
		for (my $j=0; $j < @{$comps}; $j++) {
			my $compartment = "[".$comps->[$j]."]";
			$compartment="" if !$args->{compts};
			if ($rgtHash->{$sortedCpd->[$i]}->{$comps->[$j]} < 0) {
				my $coef = -1*$rgtHash->{$sortedCpd->[$i]}->{$comps->[$j]};
				if (length($reactcode) > 0) {
					$reactcode .= " + ";	
				}
				$reactcode .= "(".$coef.") ".$printId.$compartment;
			} elsif ($rgtHash->{$sortedCpd->[$i]}->{$comps->[$j]} > 0) {
				if (length($productcode) > 0) {
					$productcode .= " + ";	
				}
				$productcode .= "(".$rgtHash->{$sortedCpd->[$i]}->{$comps->[$j]}.") ".$printId.$compartment;
			} 
		}
	}
    my $reaction_string = $reactcode.$sign.$productcode;
    if($args->{reverse}==1){
	$reaction_string = $productcode.$sign.$reactcode;
    }
    if ($args->{hashed} == 1) {
	return Digest::MD5::md5_hex($reaction_string);
    }
    return $reaction_string;
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
    my $args = ModelSEED::utilities::args(["equation","aliasType"], {compartment=>"c",checkDuplicates=>0}, @_);
	my $bio = $self->parent();
	my @TempArray = split(/\s+/, $args->{equation});
	my $CurrentlyOnReactants = 1;
	my $Coefficient = 1;
	my $parts = [];
	my $cpdCmpHash;
	my $compHash;
	my $compUUIDHash;
	my $cpdHash;
	my $cpdCmpCount;
	for (my $i = 0; $i < @TempArray; $i++) {
	    #some identifiers may include '=' sign, need to skip actual '+' in equation
	    next if $TempArray[$i] eq "+";
	    if( $TempArray[$i] =~ m/=/ || $TempArray[$i] =~ m/-->/ || $TempArray[$i] =~ m/<--/) {
		$CurrentlyOnReactants = 0;
	    } elsif ($TempArray[$i] =~ m/^\(([eE\-\.\d]+)\)$/ || $TempArray[$i] =~ m/^([eE\-\.\d]+)$/) {
		$Coefficient = $1;
	    } elsif ($TempArray[$i] =~ m/(^[\/\\<>\w,&;'#:\{\}\-+\(\)]+)/){
		$Coefficient *= -1 if ($CurrentlyOnReactants);
		my $NewRow = {
		    compound => $1,
		    compartment => $args->{compartment},
		    coefficient => $Coefficient
		};
		my $Compound=quotemeta($NewRow->{compound});
		if ($TempArray[$i] =~ m/^${Compound}\[([a-zA-Z]+)\]/) {
		    $NewRow->{compartment} = lc($1);
		}
		my $comp = $compHash->{$NewRow->{compartment}};
		unless(defined($comp)) {
		    $comp = $bio->queryObject("compartments", { id => $NewRow->{compartment} });
		}
		unless(defined($comp)) {
		    ModelSEED::utilities::USEWARNING("Unrecognized compartment '".$NewRow->{compartment}."' used in reaction ".$args->{rxnId});
		    $comp = $bio->add("compartments",{
			locked => "0",
			id => $NewRow->{compartment},
			name => $NewRow->{compartment},
			hierarchy => 3});
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
			ModelSEED::utilities::verbose("Compound '".$NewRow->{compound}."' automatically added to database");
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
		push(@$parts, $NewRow);
		$Coefficient = 1;
	    }
	}
	foreach my $cpduuid (keys(%{$cpdCmpHash})) {
	    foreach my $cmpuuid (keys(%{$cpdCmpHash->{$cpduuid}})) {
	        # Do not include reagents with zero coefficients
	        next if $cpdCmpHash->{$cpduuid}->{$cmpuuid} == 0;
	        $self->add("reagents", {
	            compound_uuid               => $cpduuid,
	            compartment_uuid            => $cmpuuid,
	            coefficient                 => $cpdCmpHash->{$cpduuid}->{$cmpuuid},
	            isCofactor                  => 0,
			   });
	    }
	}
	
	#multiple instances of the same reactant in the same compartment is unacceptable.
        #however, these aren't rejected, (no duplicate reagents are created in the code above
        #and instead are accounted for in checkReactionMassChargeBalance()
	if($args->{checkDuplicates}==1 && scalar( grep { $cpdCmpCount->{$_} >1 } keys %$cpdCmpCount)>0){
	    return 0;
	}else{
	    return 1;
	}
}

=head3 checkReactionCueBalance
Definition:
	{} = ModelSEED::MS::Reaction->checkReactionCueBalance({});
Description:
	Checks if the cues in the reaction can be balanced

=cut

sub checkReactionCueBalance {
    my $self = shift;

    #Adding up atoms and charge from all reagents
    my $rgts = $self->reagents();

    #balance out reagents in case of 'cpderror'
    my %reagents=();
    foreach my $rgt (@$rgts){
	$reagents{$rgt->compound_uuid()}+=$rgt->coefficient();
    }

    #balance out cues
    my %Cues=();
    foreach my $rgt ( grep { $reagents{$_->compound_uuid()} != 0 } @$rgts ){
	my %cues = %{$rgt->compound()->cues()};
	foreach my $cue (keys %cues){
	    $Cues{$cue}+=($cues{$cue}*$rgt->coefficient());
	}
    }

    %Cues = map { $_ => $Cues{$_} } grep { $Cues{$_} != 0 } keys %Cues;

    $self->cues(\%Cues);
}

=head3 calculateEnergyofReaction
Definition:
	{} = ModelSEED::MS::Reaction->calculateEnergyofReaction({});
Description:
	calculates the energy of reaction

=cut

sub calculateEnergyofReaction{
    my $self=shift;
    my %Cues=%{$self->cues()};

    if($self->status() eq "EMPTY" || $self->status() eq "CPDFORMERROR"){
	$self->deltaG("10000000");
	$self->deltaGErr("10000000");
	return;
    }

    my $biochem=$self->parent();

    my $noDeltaG=0;
    my %cue_dG=();
    my %cue_dGE=();
    foreach my $cue( grep { $Cues{$_} !=0 } keys %Cues){
	$cue_dG{$cue}=$biochem->getObject("cues",$cue)->deltaG();
	$cue_dGE{$cue}=$biochem->getObject("cues",$cue)->deltaGErr();
        $noDeltaG=1 if !defined($cue_dG{$cue}) || $cue_dG{$cue} == -10000 || $cue_dG{$cue} == 10000000;
    }

    if($noDeltaG){
	$self->deltaG("10000000");
	$self->deltaGErr("10000000");
	return;
    }

    my $deltaG=0.0;
    my $deltaGErr=0.0;
    foreach my $cue (keys %Cues){
        $deltaG+=($cue_dG{$cue}*$Cues{$cue});
        $deltaGErr+=(($cue_dGE{$cue}*$Cues{$cue})**2);
    }
    $deltaGErr=$deltaGErr**0.5;
    $deltaGErr=2.0 if !$deltaGErr;

    $deltaG=sprintf("%.2f",$deltaG);
    $deltaGErr=sprintf("%.2f",$deltaGErr);

    $self->deltaG($deltaG);
    $self->deltaGErr($deltaGErr);
}

=head3 estimateThermoReversibility
Definition:
	"" = ModelSEED::MS::Reaction->estimateThermoReversibility({});
Description:
	Checks if the cues in the reaction can be balanced

=cut

sub estimateThermoReversibility{
    my $self=shift;
    my $args = ModelSEED::utilities::args([], { direction=>0 }, @_);

    ModelSEED::utilities::set_verbose(1);

    if($self->deltaG() eq "10000000"){
	$self->thermoReversibility("?");
	return "No deltaG";
    }

    my $biochem = $self->parent();

    my $TEMPERATURE=298.15;
    my $GAS_CONSTANT=0.0019858775;
    my $RT_CONST=$TEMPERATURE*$GAS_CONSTANT;
    my $FARADAY = 0.023061; # kcal/vol  gram divided by 1000?

    #Calculate MdeltaG
    my ($max,$min)=(0.02,0.00001);

    my ($rct_min,$rct_max)=(0.0,0.0);
    my ($pdt_min,$pdt_max)=(0.0,0.0);
    foreach my $rgt (@{$self->reagents()}){
	next if $rgt->compound_uuid() eq $biochem->checkForProton()->uuid() || $rgt->compound_uuid() eq $biochem->checkForWater()->uuid();

	my ($tmx,$tmn)=($max,$min);
	if($rgt->compartment->id() eq "e"){
	    ($tmx,$tmn)=(1.0,0.0000001);
	}
	if($rgt->coefficient()<0){
	    $rct_min += ($rgt->coefficient()*log($tmn));
	    $rct_max += ($rgt->coefficient()*log($tmx));
	}else{
	    $pdt_min += ($rgt->coefficient()*log($tmn));
	    $pdt_max += ($rgt->coefficient()*log($tmx));
	}
    }

    my $deltaGTransport=0.0;
    if($self->isTransport()){
#	my $deltadpsiG=0.0;
#	my $deltadconcG=0.0;

#	my $internalpH=7.0;
#	my $externalpH=7.5;
#	my $minpH=7.5;
#	my $maxpH=7.5;

#    foreach my $rgt (@{$self->reagents()}){
#	if($r->{"DATABASE"}->[0] eq $p->{"DATABASE"}->[0]){
#	    if($r->{"COMPARTMENT"}->[0] ne $p->{"COMPARTMENT"}){
		#Find number of mols transported
		#And direction of transport
#		my $tempCoeff = 0;
#		my $tempComp="";
#		if($r->{"COEFFICIENT"}->[0] < $p->{"COEFFICIENT"}->[0]){
#		    $tempCoeff=$p->{"COEFFICIENT"}->[0];
#		    $tempComp=$p->{"COMPARTMENT"}->[0];
#		}else{
#		    $tempCoeff=$r->{"COEFFICIENT"}->[0];
#		    $tempComp=$r->{"COMPARTMENT"}->[0];
#		}
		
		#find direction of transport based on difference in concentrations
#		my $conc_diff=0.0;
#		if($tempComp ne "c"){
#		    $conc_diff=$internalpH-$externalpH;
#		}else{
#		    $conc_diff=$externalpH-$internalpH
#		}
		
#		my $delta_psi = 33.33 * $conc_diff - 143.33;
		
#		my $cDB=$self->figmodel()->database()->get_object('compound',{id=>$r->{"DATABASE"}->[0]});
#		my $net_charge=0.0;
#		if(!$cDB || $cDB->charge() eq "" || $cDB->charge() eq "10000000"){
#		    print STDERR "Transporting ",$r->{"DATABASE"}->[0]," but no charge\n";
#		}else{
#		    $net_charge=$cDB->charge()*$tempCoeff;
#		}
		
#		$deltadpsiG += $net_charge * $FARADAY * $delta_psi;
#		$deltadconcG += -2.3 * $RT_CONST * $conc_diff * $tempCoeff;
#	    }
#	}
#    }

#if($r->{"DATABASE"}->[0] eq "cpd00067"){
#$extCoeff -= ($DPSI_COEFF-$RT_CONST*1)*$tempCoeff;
#$intCoeff += ($DPSI_COEFF-$RT_CONST*1)*$tempCoeff;
#}else{
#$extCoeff -= $DPSI_COEFF*$charge*$tempCoeff;
#$intCoeff += $DPSI_COEFF*$charge*$tempCoeff;
#}
#Then for the whole reactant
#if (HinCoeff < 0) {
#    DeltaGMin += -HinCoeff*IntpH + -HextCoeff*MaxExtpH;
#    DeltaGMax += -HinCoeff*IntpH + -HextCoeff*MinExtpH;
#    mMDeltaG += -HinCoeff*IntpH + -HextCoeff*(IntpH+0.5);
#}
#else {
#    DeltaGMin += -HinCoeff*IntpH + -HextCoeff*MinExtpH;
#    DeltaGMax += -HinCoeff*IntpH + -HextCoeff*MaxExtpH;
#    mMDeltaG += -HinCoeff*IntpH + -HextCoeff*(IntpH+0.5);
#}
    }

    my $storedmax=$self->deltaG()+$deltaGTransport+($RT_CONST*$pdt_max)+($RT_CONST*$rct_min)+$self->deltaGErr();
    my $storedmin=$self->deltaG()+$deltaGTransport+($RT_CONST*$pdt_min)+($RT_CONST*$rct_max)-$self->deltaGErr();

    $storedmax=sprintf("%.4f",$storedmax);
    $storedmin=sprintf("%.4f",$storedmin);

    if($storedmax<0){
	$self->thermoReversibility(">");
	$self->direction(">") if $args->{direction};
        return "MdeltaG:".$storedmin.">".$storedmax;
    }
    if($storedmin>0){
	$self->thermoReversibility("<");
	$self->direction("<") if $args->{direction};
        return "MdeltaG:".$storedmin."<".$storedmax;
    }

    #Do heuristics
    #1: ATP hydrolysis transport
    #1a: Find Phosphate stuff
    my %PhoIDs=("ATP" => { "ModelSEED" => "cpd00002", "KEGG" => "C00002", "MetaCyc" => "ATP", "UUID" =>"" },
		"ADP" => { "ModelSEED" => "cpd00008", "KEGG" => "C00008", "MetaCyc" => "ADP", "UUID" =>"" },
		"AMP" => { "ModelSEED" => "cpd00018", "KEGG" => "C00020", "MetaCyc" => "AMP", "UUID" =>"" },
		"Pi"  => { "ModelSEED" => "cpd00009", "KEGG" => "C00009", "MetaCyc" => "Pi",  "UUID" =>"" },
		"Ppi" => { "ModelSEED" => "cpd00012", "KEGG" => "C00013", "MetaCyc" => "PPI", "UUID" =>"" });

    my $Source="None";
    foreach my $src ("KEGG","MetaCyc","ModelSEED"){
	if($biochem->queryObject("aliasSets",{name=>$src,attribute=>"compounds"})){
	    my $cpdObj = $biochem->getObjectByAlias("compounds",$PhoIDs{"Pi"}{$src},$src);
	    if($cpdObj){
		$Source=$src;
		last;
	    }
	}
    }
    if($Source eq "None"){
	ModelSEED::utilities::verbose("Cannot use heuristics with atypical biochemistry aliases");
	return "Error";
    }

    foreach my $cpd (keys %PhoIDs){
	my $cpdObj = $biochem->getObjectByAlias("compounds",$PhoIDs{$cpd}{$Source},$Source);
	if($cpdObj){
	    $PhoIDs{$cpd}{"UUID"}=$cpdObj->uuid();
	}else{
	    ModelSEED::utilities::verbose("Unable to find phopsphate compound in biochemistry: $cpd");
	    return "Error";
	}
    }

    my %PhoHash=();
    my %Comps=();
    my $Contains_Protons=0;
    foreach my $rgt (@{$self->reagents()}){
        $Comps{$rgt->compartment()->id()}=1;
        $Contains_Protons=1 if $rgt->compartment()->id() ne "c" && $rgt->compound_uuid() eq $biochem->checkForProton()->uuid();
	foreach my $cpd (keys %PhoIDs){
	    $PhoHash{$cpd} += $rgt->coefficient() if $PhoIDs{$cpd}{"UUID"} eq $rgt->compound_uuid();
	}
    }

    #1b: ATP Synthase is reversible
    if(scalar(keys %Comps)>1 && exists($PhoHash{"ATP"}) && $Contains_Protons){
	$self->thermoReversibility("=");
	$self->direction("=") if $args->{direction};
        return "ATPS";
    }

    #1b: Find ABC Transporters (but not ATP Synthase)
    if(scalar(keys %Comps)>1 && exists($PhoHash{"ATP"}) && !$Contains_Protons){
        my $dir="=";
        if($PhoHash{"ATP"}<0){
            $dir=">";
        }elsif($PhoHash{"ATP"}>0){
            $dir="<";
        }
	$self->thermoReversibility($dir);
	$self->direction($dir) if $args->{direction};
        return "ABCT: ".$dir;
    }

    #2: Calculate mMdeltaG
    my %GasIDs=("CO2"=> { "ModelSEED" => "cpd00011", "KEGG" => "C00011", "MetaCyc" => "CARBON-DIOXIDE", "UUID" =>"" },
		"O2" => { "ModelSEED" => "cpd00007", "KEGG" => "C00007", "MetaCyc" => "OXYGEN-MOLECULE", "UUID" =>"" },
		"H2" => { "ModelSEED" => "cpd11640", "KEGG" => "C00282", "MetaCyc" => "HYDROGEN-MOLECULE", "UUID" =>"" });

    foreach my $cpd (keys %GasIDs){
	my $cpdObj = $biochem->getObjectByAlias("compounds",$GasIDs{$cpd}{$Source},$Source);
	if($cpdObj){
	    $GasIDs{$cpd}{"UUID"}=$cpdObj->uuid();
	}else{
	    ModelSEED::utilities::verbose("Unable to find gas compound in biochemistry: $cpd");
	    return "Error";
	}
    }

    my $conc=0.001;
    my $rgt_total=0.0;
    foreach my $rgt (@{$self->reagents()}){
	next if $rgt->compound_uuid() eq $biochem->checkForProton()->uuid() || $rgt->compound_uuid() eq $biochem->checkForWater()->uuid();
        my $tconc=$conc;
        if($rgt->compound_uuid() eq $GasIDs{"CO2"}{"UUID"}){
            $tconc=0.0001;
        }
        if($rgt->compound_uuid() eq $GasIDs{"O2"}{"UUID"} || $rgt->compound_uuid() eq $GasIDs{"H2"}{"UUID"}){
            $tconc=0.000001;
        }
        $rgt_total+=($rgt->coefficient()*log($tconc));
    }

    my $mMdeltaG=$self->deltaG()+($RT_CONST*$rgt_total);
    $mMdeltaG=sprintf("%.4f",$mMdeltaG);

    if($mMdeltaG >= -2 && $mMdeltaG <= 2) {
	$self->thermoReversibility("=");
	$self->direction("=") if $args->{direction};
        return "mMdeltaG: $mMdeltaG";
    }

    #3: Calculate low energy points
    #3a: Find minimum Phosphate stuff
    my $LowEnergyPoints=0;
    my $minimum=10000;
    if(exists($PhoHash{"ATP"}) && exists($PhoHash{"Pi"}) && exists($PhoHash{"ADP"})){
        foreach my $key ("ATP", "ADP", "Pi"){
            if(exists($PhoHash{$key})){
                $minimum=$PhoHash{$key} if $PhoHash{$key}<$minimum;
            }
        }
        $LowEnergyPoints=$minimum if $minimum<10000;
    }elsif(exists($PhoHash{"ATP"}) && exists($PhoHash{"Ppi"}) && exists($PhoHash{"AMP"})){
        foreach my $key ("ATP", "AMP", "Ppi"){
            if(exists($PhoHash{$key})){
                $minimum=$PhoHash{$key} if $PhoHash{$key}<$minimum;
            }
        }
        $LowEnergyPoints=$minimum if $minimum<10000;
    }

    #3b:Find other low energy compounds
    #taken from software/mfatoolkit/Parameters/Defaults.txt
    my %LowEIDs=("CO2" => { "ModelSEED" => "cpd00011", "KEGG" => "C00011", "MetaCyc" => "CARBON-DIOXIDE", "UUID" =>"" },
		 "NH3" => { "ModelSEED" => "cpd00013", "KEGG" => "C00014", "MetaCyc" => "AMMONIA", "UUID" =>"" },
		 "ACP" => { "ModelSEED" => "cpd11493", "KEGG" => "C00229", "MetaCyc" => "ACP", "UUID" =>"" },
		 "Pi"  => { "ModelSEED" => "cpd00009", "KEGG" => "C00009", "MetaCyc" => "Pi",  "UUID" =>"" },
		 "Ppi" => { "ModelSEED" => "cpd00012", "KEGG" => "C00013", "MetaCyc" => "PPI", "UUID" =>"" },
		 "CoA" => { "ModelSEED" => "cpd00010", "KEGG" => "C00010", "MetaCyc" => "CO-A", "UUID" =>"" },
		 "DHL" => { "ModelSEED" => "cpd00449", "KEGG" => "C00579", "MetaCyc" => "DIHYDROLIPOAMIDE", "UUID" =>"" },
		 "CO3" => { "ModelSEED" => "cpd00242", "KEGG" => "C00288", "MetaCyc" => "HCO3", "UUID" =>"" });

    my %LowEUUIDs=();
    foreach my $cpd (keys %LowEIDs){
	my $cpdObj = $biochem->getObjectByAlias("compounds",$LowEIDs{$cpd}{$Source},$Source);
	if($cpdObj){
	    $LowEIDs{$cpd}{"UUID"}=$cpdObj->uuid();
	    $LowEUUIDs{$cpdObj->uuid()}=1;
	}else{
	    ModelSEED::utilities::verbose("Unable to find low energy compound in biochemistry: $cpd");
	    return "Error";
	}
    }

    my $LowE_total=0;
    foreach my $rgt (@{$self->reagents()}){
	if(exists($LowEUUIDs{$rgt->compound_uuid()})){
	    $LowE_total += $rgt->coefficient();
	}
    }

    $LowEnergyPoints-=$LowE_total;

    #test points
    if(($LowEnergyPoints*$mMdeltaG) > 2 && $mMdeltaG < 0){
	$self->thermoReversibility(">");
	$self->direction(">") if $args->{direction};
        return "Low Energy Points:$LowEnergyPoints\tmMdeltaG: $mMdeltaG";
    }elsif(($LowEnergyPoints*$mMdeltaG) > 2 && $mMdeltaG > 0){
	$self->thermoReversibility("<");
	$self->direction("<") if $args->{direction};
        return "Low Energy Points:$LowEnergyPoints\tmMdeltaG: $mMdeltaG";
    }

    return "Default";
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
    my $args = ModelSEED::utilities::args([], {rebalanceProtons => 0,rebalanceWater => 0, saveStatus => 0}, @_);
    my $atomHash;
    my $netCharge = 0;
    my $status = "OK";

    #Adding up atoms and charge from all reagents
    my $rgts = $self->reagents();

    #Need to remember whether reaction has proton reagent in which compartment
    my $waterCompHash=();
    my $protonCompHash=();
    my $compHash=();
    my $cpdCmpCount=();
    my $hcpd=$self->biochemistry()->checkForProton();
    my $wcpd=$self->biochemistry()->checkForWater();

    #check for the one reaction which is truly empty
    if(scalar(@$rgts)==0){
	$self->status("EMPTY");
	return {
	    balanced => 0,
	    error => "Reactants cancel out completely"
	};
    }

    #check for reactions with duplicate reagents (same compound in same compartment)
    #this is rare but arises from use of consolidatebio which doesn't check reactions
    #after merging compounds.  The duplicate reagents need to be removed before balancing
    #reaction
    foreach my $rgt (@$rgts){
	$cpdCmpCount->{$rgt->compound_uuid()."_".$rgt->compartment_uuid()}++;
    }

    if(scalar( grep { $cpdCmpCount->{$_} > 1 } keys %$cpdCmpCount)>0){

	foreach my $cpdcmpt ( grep { $cpdCmpCount->{$_} > 1 } keys %$cpdCmpCount){

	    my ($cpd,$cmpt)=split(/_/,$cpdcmpt);
	    my $coefficient=0;
	    my $rgtUUIDs="";

	    foreach my $rgt (@$rgts){
		if($rgt->compartment_uuid() eq $cmpt && $rgt->compound_uuid() eq $cpd){
		    $coefficient+=$rgt->coefficient();

		    if(!$rgtUUIDs){
			$rgtUUIDs=$cpdcmpt;
		    }else{
			$self->remove("reagents",$rgt);
		    }
		}
	    }
	    
	    $rgts = $self->reagents();

	    foreach my $rgt (@$rgts){
		if($rgt->compound_uuid()."_".$rgt->compartment_uuid() eq $rgtUUIDs){
		    $rgt->coefficient($coefficient);
		}
	    }
	}
    }

    for (my $i=0; $i < @{$rgts};$i++) {
	my $rgt = $rgts->[$i];
	
	#Check for protons/water
	$protonCompHash->{$rgt->compartment_uuid()}=$rgt->compartment() if $rgt->compound_uuid() eq $hcpd->uuid();
	$waterCompHash->{$rgt->compartment_uuid()}=$rgt->compartment() if $args->{rebalanceWater} && $rgt->compound_uuid() eq $wcpd->uuid();
	$compHash->{$rgt->compartment_uuid()}=$rgt->compartment();
	
	$cpdCmpCount->{$rgt->compound_uuid()."_".$rgt->compartment_uuid()}++;
	
	#Problems are: compounds with noformula, polymers (see next line), and reactions with duplicate compounds in the same compartment
	#Latest KEGG formulas for polymers contain brackets and 'n', older ones contain '*'
	my $cpdatoms = $rgt->compound()->calculateAtomsFromFormula();
	
	if (defined($cpdatoms->{error})) {
	    $self->status("CPDFORMERROR");
	    return {
		balanced => 0,
		error => $cpdatoms->{error}
	    };	
	}
	
	$netCharge += $rgt->coefficient()*$rgt->compound()->defaultCharge();
	
	foreach my $atom (keys(%{$cpdatoms})) {
	    if (!defined($atomHash->{$atom})) {
		$atomHash->{$atom} = 0;
	    }
	    $atomHash->{$atom} += $rgt->coefficient()*$cpdatoms->{$atom};
	}
    }
    
    #Adding protons
    #use of defaultProtons() discontinued for time being
    #$netCharge += $self->defaultProtons()*1;
    
    if (!defined($atomHash->{H})) {
	$atomHash->{H} = 0;
    }
    
    #$atomHash->{H} += $self->defaultProtons();
    
    #Checking if charge or atoms are unbalanced
    my $results = {
	balanced => 1
    };
    
    my $imbalancedAtoms = {};
    foreach my $atom (keys(%{$atomHash})) { 
	if ($atomHash->{$atom} > 0.00000001 || $atomHash->{$atom} < -0.00000001) {
	    $imbalancedAtoms->{$atom}=$atomHash->{$atom};
	}
    }
    
    if($args->{rebalanceWater} && join("",sort keys %$imbalancedAtoms) eq "HO" && ($imbalancedAtoms->{"H"}/$imbalancedAtoms->{"O"}) == 2){
	ModelSEED::utilities::verbose("Adjusting ".$self->id()." water by ".$imbalancedAtoms->{"O"});
	
	if(scalar(keys %$waterCompHash)==0){
	    #must create water reagent
	    #either reaction compartment or, if transporter, defaults to compartment with highest number in hierarchy
	    my $compUuid = (keys %$compHash)[0];
	    if(scalar(keys %$compHash)>1){
		my $hierarchy=1;
		foreach my $tmpCompUuid (keys %$compHash){
		    if($compHash->{$tmpCompUuid}->hierarchy()>$hierarchy){
			$compUuid=$tmpCompUuid;
			$hierarchy=$compHash->{$tmpCompUuid}->hierarchy();
		    }
		}
	    }
	    
	    $self->add("reagents", {compound_uuid => $wcpd->uuid(),
				    compartment_uuid => $compUuid,
				    coefficient => -1*$imbalancedAtoms->{"O"},
				    isCofactor => 0});
	    
	}elsif(scalar(keys %$waterCompHash)>0){
	    #must choose water reagent
	    #defaults to compartment with highest number in hierarchy
	    
	    my $compUuid = (keys %$waterCompHash)[0];
	    my $hierarchy=1;
	    foreach my $tmpCompUuid ( grep { $_ ne $compUuid } keys %$waterCompHash){
		if($waterCompHash->{$tmpCompUuid}->hierarchy()>$hierarchy){
		    $compUuid=$tmpCompUuid;
		    $hierarchy=$waterCompHash->{$tmpCompUuid}->hierarchy();
		}
	    }
	    
	    my $rgts = $self->reagents();
	    for(my $i=0;$i<scalar(@$rgts);$i++){
		if($rgts->[$i]->compound_uuid() eq $wcpd->uuid() && $rgts->[$i]->compartment_uuid() eq $compUuid){
		    my $coeff=$rgts->[$i]->coefficient();
		    $rgts->[$i]->coefficient($coeff+(-1*$imbalancedAtoms->{"O"}));
		}
	    }
	    $self->reagents($rgts);
	}
	
	foreach my $key ("H","O"){
	    $atomHash->{$key} = 0;
	    delete($imbalancedAtoms->{$key})
	}
    }
    
    if ($args->{rebalanceProtons} && join("",keys %$imbalancedAtoms) eq "H") {
	ModelSEED::utilities::verbose("Adjusting ".$self->id()." protons by ".$imbalancedAtoms->{"H"});
	
	if(scalar(keys %$protonCompHash)==0){
	    #must create proton reagent
	    #either reaction compartment or, if transporter, defaults to compartment with highest number in hierarchy
	    my $compUuid = (keys %$compHash)[0];
	    if(scalar(keys %$compHash)>1){
		my $hierarchy=1;
		foreach my $tmpCompUuid (keys %$compHash){
		    if($compHash->{$tmpCompUuid}->hierarchy()>$hierarchy){
			$compUuid=$tmpCompUuid;
			$hierarchy=$compHash->{$tmpCompUuid}->hierarchy();
		    }
		}
	    }
	    
	    $self->add("reagents", {compound_uuid => $hcpd->uuid(),
				    compartment_uuid => $compUuid,
				    coefficient => -1*$imbalancedAtoms->{"H"},
				    isCofactor => 0});
	    
	}elsif(scalar(keys %$protonCompHash)>0){
	    #must choose proton reagent
	    #defaults to compartment with highest number in hierarchy
	    
	    my $compUuid = (keys %$protonCompHash)[0];
	    my $hierarchy=1;
	    foreach my $tmpCompUuid ( grep { $_ ne $compUuid } keys %$protonCompHash){
		if($protonCompHash->{$tmpCompUuid}->hierarchy()>$hierarchy){
		    $compUuid=$tmpCompUuid;
		    $hierarchy=$protonCompHash->{$tmpCompUuid}->hierarchy();
		}
	    }
	    
	    my $rgts = $self->reagents();
	    for(my $i=0;$i<scalar(@$rgts);$i++){
		if($rgts->[$i]->compound_uuid() eq $hcpd->uuid() && $rgts->[$i]->compartment_uuid() eq $compUuid){
		    my $coeff=$rgts->[$i]->coefficient();
		    $rgts->[$i]->coefficient($coeff+(-1*$imbalancedAtoms->{"H"}));
		}
	    }
	    $self->reagents($rgts);
	}
	
	#my $currentProtons = $self->defaultProtons();
	#$currentProtons += -1*$imbalancedAtoms->{"H"};
	#$self->defaultProtons($currentProtons);
	
	$netCharge += -1*$imbalancedAtoms->{"H"};
	$atomHash->{H} = 0;
	delete($imbalancedAtoms->{H});
	$status.="|HB";
    }
    
    foreach my $atom (keys(%{$imbalancedAtoms})) { 
	if ($status eq "OK") {
	    $status = "MI:";	
	} else {
	    $status .= "|";
	}
	$results->{balanced} = 0;
	$results->{imbalancedAtoms}->{$atom} = $atomHash->{$atom};
	$status .= $atom.":".$atomHash->{$atom};
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
    
    if($args->{saveStatus} == 1){
	$self->status($status);
    }
    
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
