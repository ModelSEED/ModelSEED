########################################################################
# ModelSEED::MS::FBAFormulation - This is the moose object corresponding to the FBAFormulation object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-04-28T22:56:11
########################################################################
use strict;
use ModelSEED::MS::DB::FBAFormulation;
package ModelSEED::MS::FBAFormulation;
use Moose;
use namespace::autoclean;
use ModelSEED::Exceptions;
extends 'ModelSEED::MS::DB::FBAFormulation';
#***********************************************************************************************************
# ADDITIONAL ATTRIBUTES:
#***********************************************************************************************************
has jobID => ( is => 'rw', isa => 'Str',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildjobid' );
has jobPath => ( is => 'rw', isa => 'Str',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildjobpath' );
has jobDirectory => ( is => 'rw', isa => 'Str',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildjobdirectory' );
has command => ( is => 'rw', isa => 'Str',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, default => '' );
has mfatoolkitBinary => ( is => 'rw', isa => 'Str',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildmfatoolkitBinary' );
has mfatoolkitDirectory => ( is => 'rw', isa => 'Str',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildmfatoolkitDirectory' );
has dataDirectory => ( is => 'rw', isa => 'Str',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_builddataDirectory' );
has cplexLicense => ( is => 'rw', isa => 'Str',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildcplexLicense' );
has readableObjective => ( is => 'rw', isa => 'Str',printOrder => '2', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildreadableObjective' );
has mediaID => ( is => 'rw', isa => 'Str',printOrder => '0', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildmediaID' );
has knockouts => ( is => 'rw', isa => 'Str',printOrder => '3', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildknockouts' );

#***********************************************************************************************************
# BUILDERS:
#***********************************************************************************************************
sub _buildjobid {
	my ($self) = @_;
	my $path = $self->jobPath();
	my $fulldir = File::Temp::tempdir(DIR => $path);
	if (!-d $fulldir) {
		File::Path::mkpath ($fulldir);
	}
	my $jobid = substr($fulldir,length($path."/"));
	return $jobid
}

sub _buildjobpath {
	my ($self) = @_;
	my $path = $self->dataDirectory()."fbajobs";
	if (!-d $path) {
		File::Path::mkpath ($path);
	}
	return $path;
}

sub _buildjobdirectory {
	my ($self) = @_;
	return $self->jobPath()."/".$self->jobID();
}

sub _buildmfatoolkitBinary {
	my ($self) = @_;
	my $config = ModelSEED::Configuration->new();
	my $bin;
	if (defined($config->user_options()->{MFATK_BIN})) {
		$bin = $config->user_options()->{MFATK_BIN};
	} else {
            if ($^O =~ m/^MSWin/) {
		$bin = ModelSEED::utilities::MODELSEEDCORE()."/software/mfatoolkit/bin/mfatoolkit";
                $bin .= ".exe";
            } else {
                $bin = `which mfatoolkit 2>/dev/null`;
                chomp $bin;
            }
	}
	if (!-e $bin) {
        ModelSEED::Exception::MissingConfig->throw(
            variable => 'MFATK_BIN',
            message => <<ND
This is the path to the mfatoolkit binary. If it is not already
installed, this program can be downloaded from:
https://github.com/modelseed/mfatoolkit
Add the binary directory to your path or use the following command:
ND
        );
	}
	return $bin;
}

sub _buildmfatoolkitDirectory {
	my ($self) = @_;
	my $bin = $self->mfatoolkitBinary();
	if ($bin =~ m/^(.+\/)[^\/]+$/) {
		return $1;
	}
	return "";
}

sub _builddataDirectory {
	my ($self) = @_;
	my $config = ModelSEED::Configuration->new();
	if (defined($config->user_options()->{MFATK_CACHE})) {
		return $config->user_options()->{MFATK_CACHE}."/";
	}
	return ModelSEED::utilities::MODELSEEDCORE()."/data/";
}

sub _buildcplexLicense {
	my ($self) = @_;
	my $config = ModelSEED::Configuration->new();
	if (defined($config->user_options()->{CPLEX_LICENCE})) {
		return $config->user_options()->{CPLEX_LICENCE};
	}
	return "";
}

sub _buildreadableObjective {
	my ($self) = @_;
	my $string = "Max { ";
	if ($self->maximizeObjective() == 0) {
		$string = "Min { ";
	}
	my $terms = $self->fbaObjectiveTerms();
	for (my $i=0; $i < @{$terms}; $i++) {
		my $term = $terms->[$i];
		if ($i > 0) {
			$string .= " + ";
		}
		my $coef = "";
		if ($term->coefficient() != 1) {
			$coef = "(".$term->coefficient().") ";
		}
		$string .= $coef.$term->entity()->id()."_".$term->variableType();
	}
	$string .= " }";
	return $string;
}
sub _buildmediaID {
	my ($self) = @_;
	return $self->media()->id();
}
sub _buildknockouts {
	my ($self) = @_;
	my $string = "";
	my $genekos = $self->geneKOs();
	for (my $i=0; $i < @{$genekos}; $i++) {
		if ($i > 0) {
			$string .= ", ";
		}
		$string .= $genekos->[$i]->id();
	}
	my $rxnstr = "";
	my $rxnkos = $self->reactionKOs();
	for (my $i=0; $i < @{$rxnkos}; $i++) {
		if ($i > 0) {
			$rxnstr .= ", ";
		}
		$rxnstr .= $rxnkos->[$i]->id();
	}
	if (length($string) > 0 && length($rxnstr) > 0) {
		return $string.", ".$rxnstr;
	}
	return $string.$rxnstr;
}

#***********************************************************************************************************
# CONSTANTS:
#***********************************************************************************************************

#***********************************************************************************************************
# FUNCTIONS:
#***********************************************************************************************************

=head3 biochemistry

Definition:
	ModelSEED::MS::Biochemistry = biochemistry();
Description:
	Returns biochemistry behind gapfilling object

=cut

sub biochemistry {
	my ($self) = @_;
	$self->model()->biochemistry();	
}

=head3 annotation

Definition:
	ModelSEED::MS::Annotation = annotation();
Description:
	Returns annotation behind gapfilling object

=cut

sub annotation {
	my ($self) = @_;
	$self->model()->annotation();	
}

=head3 mapping

Definition:
	ModelSEED::MS::Mapping = mapping();
Description:
	Returns mapping behind gapfilling object

=cut

sub mapping {
	my ($self) = @_;
	$self->model()->mapping();	
}

=head3 runFBA

Definition:
	ModelSEED::MS::FBAResults = ModelSEED::MS::FBAFormulation->runFBA();
Description:
	Runs the FBA study described by the fomulation and returns a typed object with the results

=cut

sub runFBA {
	my ($self) = @_;
	if (!-e $self->jobDirectory()."/runMFAToolkit.sh") {
		$self->createJobDirectory();
	}
	$self->biochemistry()->printDBFiles();
	system($self->command());
	my $fbaresults = $self->add("fbaResults",{});
	$fbaresults->loadMFAToolkitResults();
	return $fbaresults;
}

=head3 createJobDirectory

Definition:
	void ModelSEED::MS::Model->createJobDirectory();
Description:
	Creates the MFAtoolkit job directory

=cut

sub createJobDirectory {
	my ($self) = @_;
	my $directory = $self->jobDirectory()."/";
	my $translation = {
		drainflux => "DRAIN_FLUX",
		flux => "FLUX",
		biomassflux => "FLUX"
	};
	#Print model to Model.tbl
	my $model = $self->model();
	my $mdlData = ["REACTIONS","LOAD;DIRECTIONALITY;COMPARTMENT;ASSOCIATED PEG"];
	my $mdlrxn = $model->modelreactions();
	for (my $i=0; $i < @{$mdlrxn}; $i++) {
		my $rxn = $mdlrxn->[$i];
		my $direction = $rxn->direction();
		if ($direction eq "=") {
			$direction = "<=>";	
		} elsif ($direction eq ">") {
			$direction = "=>";
		} elsif ($direction eq "<") {
			$direction = "<=";
		}
		my $line = $rxn->reaction()->id().";".$direction.";c;";
		$line .= $rxn->gprString();
		$line =~ s/kb\|g\.\d+\.//g;
		$line =~ s/fig\|\d+\.\d+\.//g;
		push(@{$mdlData},$line);
	}
	my $biomasses = $model->biomasses();
	File::Path::mkpath ($directory."reaction");
	File::Path::mkpath ($directory."MFAOutput/RawData/");
	for (my $i=0; $i < @{$biomasses}; $i++) {
		my $bio = $biomasses->[$i];
		push(@{$mdlData},$bio->id().";=>;c;UNIVERSAL");
		my $equation = $bio->equation();
		$equation =~ s/\+/ + /g;
		$equation =~ s/\)([a-zA-Z])/) $1/g;
		$equation =~ s/=\>/ => /g;
		my $bioData = ["NAME\tBiomass","DATABASE\t".$bio->id(),"EQUATION\t".$equation];
		ModelSEED::utilities::PRINTFILE($directory."reaction/".$bio->id(),$bioData);
	}
	ModelSEED::utilities::PRINTFILE($directory."Model.tbl",$mdlData);
	#Printing additional input files specified in formulation
	my $inputfileHash = $self->inputfiles();
	foreach my $filename (keys(%{$inputfileHash})) {
		ModelSEED::utilities::PRINTFILE($directory.$filename,$inputfileHash->{$filename});
	}
	#Setting drain max based on media
	my $primMedia = $self->media();
	if ($primMedia->name() eq "Complete") {
		if ($self->defaultMaxDrainFlux() <= 0) {
			$self->defaultMaxDrainFlux($self->defaultMaxFlux());
		}
	}
	#Selecting the solver based on whether the problem is MILP
	my $solver = "GLPK";
	if ($self->fluxUseVariables() == 1 || $self->drainfluxUseVariables() == 1 || $self->findMinimalMedia()) {
		if (-e $self->cplexLicense()) {
			$solver = "CPLEX";
		} else {
			$solver = "SCIP";
		}
	}
	#Setting gene KO
	my $geneKO = "none";
	for (my $i=0; $i < @{$self->geneKOs()}; $i++) {
		my $gene = $self->geneKOs()->[$i];
		if ($i == 0) {
			$geneKO = $gene->id();	
		} else {
			$geneKO .= ";".$gene->id();
		}
	}
	#Setting reaction KO
	my $rxnKO = "none";
	for (my $i=0; $i < @{$self->reactionKOs()}; $i++) {
		my $rxn = $self->reactionKOs()->[$i];
		if ($i == 0) {
			$rxnKO = $rxn->id();	
		} else {
			$rxnKO .= ";".$rxn->id();
		}
	}
	#Setting exchange species
	my $exchange = "Biomass[c]:-10000:0";
	#TODO
	#Setting the objective
	my $objective = "MAX";
	my $metToOpt = "none";
	my $optMetabolite = 1;
	if ($self->fva() == 1 || $self->comboDeletions() > 0) {
		$optMetabolite = 0;
	}
	if ($self->maximizeObjective() == 0) {
		$objective = "MIN";
		$optMetabolite = 0;
	}
	my $objterms = $self->fbaObjectiveTerms();
	for (my $i=0; $i < @{$objterms}; $i++) {
		my $objterm = $objterms->[$i];
		my $objVarName = "";
		my $objVarComp = "none";
		if (lc($objterm->entityType()) eq "compound") {
			my $entity = $model->getObject("modelcompounds",$objterm->entity_uuid());
			if (defined($entity)) {
				$objVarName = $entity->compound()->id();
				$objVarComp = $entity->modelcompartment()->label();
			}
			$optMetabolite = 0;
		} elsif (lc($objterm->entityType()) eq "reaction") {
			my $entity = $model->getObject("modelreactions",$objterm->entity_uuid());
			if (defined($entity)) {
				$objVarName = $entity->reaction()->id();
				$objVarComp = $entity->modelcompartment()->label();
				$metToOpt = "REACTANTS;".$entity->reaction()->id();
			}
		} elsif (lc($objterm->entityType()) eq "biomass") {
			my $entity = $model->getObject("biomasses",$objterm->entity_uuid());
			if (defined($entity)) {
				$objVarName = $entity->id();
				$objVarComp = "none";
				$metToOpt = "REACTANTS;".$entity->id();
			}
		}
		if (length($objVarName) > 0) {
			$objective .= ";".$translation->{$objterm->variableType()}.";".$objVarName.";".$objVarComp.";".$objterm->coefficient();
		}
	}
	if (@{$objterms} > 1) {
		$optMetabolite = 0;	
	}
	#Setting up uptake limits
	my $uptakeLimits = "none";
	foreach my $atom (keys(%{$self->uptakeLimits()})) {
		if ($uptakeLimits eq "none") {
			$uptakeLimits = $atom.":".$self->uptakeLimits()->{$atom};
		} else {
			$uptakeLimits .= ";".$atom.":".$self->uptakeLimits()->{$atom};
		}
	}
	my $comboDeletions = $self->comboDeletions();
	if ($comboDeletions == 0) {
		$comboDeletions = "none";
	}
	#Creating FBA experiment file
	my $fbaExpFile = $self->setupFBAExperiments();
	#Setting parameters
	my $parameters = {
		"perform MFA" => 1,
		"Default min drain flux" => $self->defaultMinDrainFlux(),
		"Default max drain flux" => $self->defaultMaxDrainFlux(),
		"Max flux" => $self->defaultMaxFlux(),
		"Min flux" => -1*$self->defaultMaxFlux(),
		"user bounds filename" => $self->media()->name(),
		"create file on completion" => "FBAComplete.txt",
		"Reactions to knockout" => $rxnKO,
		"Genes to knockout" => $geneKO,
		"output folder" => $self->jobID()."/",
		"use database fields" => 1,
		"MFASolver" => $solver,
		"exchange species" => $exchange,
		"database spec file" => $directory."StringDBFile.txt",
		"Reactions use variables" => $self->fluxUseVariables(),
		"Force use variables for all reactions" => 1,
		"Add use variables for any drain fluxes" => $self->drainfluxUseVariables(),
		"Decompose reversible reactions" => $self->decomposeReversibleFlux(),
		"Decompose reversible drain fluxes" => $self->decomposeReversibleDrainFlux(),
		"Make all reactions reversible in MFA" => $self->allReversible(),
		"Constrain objective to this fraction of the optimal value" => $self->objectiveConstraintFraction(),
		"objective" => $objective,
		"find tight bounds" => $self->fva(),
		"Combinatorial deletions" => $comboDeletions,
		"flux minimization" => $self->fluxMinimization(), 
		"uptake limits" => $uptakeLimits,
		"optimize metabolite production if objective is zero" => $optMetabolite,
		"metabolites to optimize" => $metToOpt,
		"FBA experiment file" => $fbaExpFile,
		"determine minimal required media" => $self->findMinimalMedia(),
		"Recursive MILP solution limit" => $self->numberOfSolutions(),
		"database root output directory" => $self->jobPath()."/",
		"database root input directory" => $self->jobDirectory()."/",
	};
	if ($solver eq "SCIP") {
		$parameters->{"use simple variable and constraint names"} = 1;
	}
	if ($^O =~ m/^MSWin/) {
		$parameters->{"scip executable"} = "scip.exe";
		$parameters->{"perl directory"} = "C:/Perl/bin/perl.exe";
		$parameters->{"os"} = "windows";
	} else {
		$parameters->{"scip executable"} = "scip";
		$parameters->{"perl directory"} = "/usr/bin/perl";
		$parameters->{"os"} = "linux";
	}
	#Setting thermodynamic constraints
	if ($self->thermodynamicConstraints() eq "none") {
		$parameters->{"Thermodynamic constraints"} = 0;
	} elsif ($self->thermodynamicConstraints() eq "simple") {
		$parameters->{"Thermodynamic constraints"} = 1;
		$parameters->{"simple thermo constraints"} = 1;
	} elsif ($self->thermodynamicConstraints() eq "error") {
		$parameters->{"Thermodynamic constraints"} = 1;
		$parameters->{"Account for error in delta G"} = 1;
		$parameters->{"minimize deltaG error"} = 0;
	} elsif ($self->thermodynamicConstraints() eq "noerror") {
		$parameters->{"Thermodynamic constraints"} = 1;
		$parameters->{"Account for error in delta G"} = 0;
		$parameters->{"minimize deltaG error"} = 0;
	} elsif ($self->thermodynamicConstraints() eq "minerror") {
		$parameters->{"Thermodynamic constraints"} = 1;
		$parameters->{"Account for error in delta G"} = 1;
		$parameters->{"minimize deltaG error"} = 1;
	}
	#Setting overide parameters
	foreach my $param (keys(%{$self->parameters()})) {
		$parameters->{$param} = $self->parameters()->{$param};
	}
	#Printing parameter file
	my $paramData = [];
	foreach my $param (keys(%{$parameters})) {
		push(@{$paramData},$param."|".$parameters->{$param}."|Specialized parameters");
	}
	ModelSEED::utilities::PRINTFILE($directory."SpecializedParameters.txt",$paramData);
	#Printing specialized bounds
	my $medialist = [$primMedia];
	push(@{$medialist},@{$self->secondaryMedia()});
	my $mediaData = ["ID\tNAMES\tVARIABLES\tTYPES\tMAX\tMIN\tCOMPARTMENTS"];
	my $cpdbnds = $self->fbaCompoundBounds();
	my $rxnbnds = $self->fbaReactionBounds();
	foreach my $media (@{$medialist}) {
		my $userBounds = {};
		my $mediaCpds = $media->mediacompounds();
		for (my $i=0; $i < @{$mediaCpds}; $i++) {
			$userBounds->{$mediaCpds->[$i]->compound()->id()}->{"e"}->{"DRAIN_FLUX"} = {
				max => $mediaCpds->[$i]->maxFlux(),
				min => $mediaCpds->[$i]->minFlux()
			};
		}
		for (my $i=0; $i < @{$cpdbnds}; $i++) {
			$userBounds->{$cpdbnds->[$i]->compound()->id()}->{$cpdbnds->[$i]->modelcompartment()->label()}->{$translation->{$cpdbnds->[$i]->variableType()}} = {
				max => $cpdbnds->[$i]->upperBound(),
				min => $cpdbnds->[$i]->lowerBound()
			};
		}
		for (my $i=0; $i < @{$rxnbnds}; $i++) {
			$userBounds->{$rxnbnds->[$i]->reaction()->id()}->{$rxnbnds->[$i]->modelcompartment()->label()}->{$translation->{$rxnbnds->[$i]->variableType()}} = {
				max => $rxnbnds->[$i]->upperBound(),
				min => $rxnbnds->[$i]->lowerBound()
			};
		}
		my $dataArrays;
		foreach my $var (keys(%{$userBounds})) {
			foreach my $comp (keys(%{$userBounds->{$var}})) {
				foreach my $type (keys(%{$userBounds->{$var}->{$comp}})) {
					push(@{$dataArrays->{var}},$var);
					push(@{$dataArrays->{type}},$type);
					push(@{$dataArrays->{min}},$userBounds->{$var}->{$comp}->{$type}->{min});
					push(@{$dataArrays->{max}},$userBounds->{$var}->{$comp}->{$type}->{max});
					push(@{$dataArrays->{comp}},$comp);
				}
			}
		}
		my $newLine = $media->name()."\t".$media->name()."\t";
		if (defined($dataArrays->{var}) && @{$dataArrays->{var}} > 0) {
			$newLine .= 
				join("|",@{$dataArrays->{var}})."\t".
				join("|",@{$dataArrays->{type}})."\t".
				join("|",@{$dataArrays->{max}})."\t".
				join("|",@{$dataArrays->{min}})."\t".
				join("|",@{$dataArrays->{comp}});
		} else {
			$newLine .= "\t\t\t\t";
		}
		push(@{$mediaData},$newLine);
	}
	ModelSEED::utilities::PRINTFILE($directory."media.tbl",$mediaData);
	#Set StringDBFile.txt
	my $mfatkdir = $self->mfatoolkitDirectory();
	my $dataDir = $self->dataDirectory();
	my $biochemid = $model->biochemistry()->uuid();
	my $stringdb = [
		"Name\tID attribute\tType\tPath\tFilename\tDelimiter\tItem delimiter\tIndexed columns",
		"compound\tid\tSINGLEFILE\t\t".$dataDir."fbafiles/".$biochemid."-compounds.tbl\tTAB\tSC\tid",
		"reaction\tid\tSINGLEFILE\t".$directory."reaction/\t".$dataDir."fbafiles/".$biochemid."-reactions.tbl\tTAB\t|\tid",
		"cue\tNAME\tSINGLEFILE\t\t".$mfatkdir."../etc/MFAToolkit/cueTable.txt\tTAB\t|\tNAME",
		"media\tID\tSINGLEFILE\t".$dataDir."ReactionDB/Media/\t".$directory."media.tbl\tTAB\t|\tID;NAMES"		
	];
	ModelSEED::utilities::PRINTFILE($directory."StringDBFile.txt",$stringdb);
	#Write shell script
	my $exec = [
		$self->mfatoolkitBinary().' resetparameter "MFA input directory" "'.$dataDir.'ReactionDB/" parameterfile "'.$directory.'SpecializedParameters.txt" LoadCentralSystem "'.$directory.'Model.tbl" > "'.$directory.'log.txt"'
	];
	ModelSEED::utilities::PRINTFILE($directory."runMFAToolkit.sh",$exec);
	chmod 0775,$directory."runMFAToolkit.sh";
	$self->command($self->mfatoolkitBinary().' parameterfile "'.$directory.'SpecializedParameters.txt" LoadCentralSystem "'.$directory.'Model.tbl" > "'.$directory.'log.txt"');
}

=head3 setupFBAExperiments

Definition:
	string:FBA experiment filename = setupFBAExperiments());
Description:
	Converts phenotype simulation specs into an FBA experiment file for the MFAToolkit

=cut

sub setupFBAExperiments {
	my ($self) = @_;
	my $fbaExpFile = "none";
	my $fbaSims = $self->fbaPhenotypeSimulations();
	if (@{$fbaSims} > 0) {
		$fbaExpFile = "FBAExperiment.txt";
		my $phenoData = ["Label\tKO\tMedia"];
		my $mediaHash = {};
		my $tempMediaIndex = 1;
		for (my $i=0; $i < @{$fbaSims}; $i++) {
			my $phenoko = "none";
			my $addnlCpds = $fbaSims->[$i]->additionalCpd_uuids();
			my $media = $fbaSims->[$i]->media()->name();
			if (@{$addnlCpds} > 0) {
				if (!defined($mediaHash->{$media.":".join("|",sort(@{$addnlCpds}))})) {
					$mediaHash->{$media.":".join("|",sort(@{$addnlCpds}))} = $self->createTemporaryMedia({
						name => "Temp".$tempMediaIndex,
						media => $fbaSims->[$i]->media(),
						additionalCpd => $fbaSims->[$i]->additionalCpds()
					});
					$tempMediaIndex++;
				}
				$media = $mediaHash->{$media.":".join("|",sort(@{$addnlCpds}))}->name();
			} else {
				$mediaHash->{$media} = $fbaSims->[$i]->media();
			}
			for (my $j=0; $j < @{$fbaSims->[$i]->geneKOs()}; $j++) {
				if ($phenoko eq "none" && $fbaSims->[$i]->geneKOs()->[$j]->id() =~ m/(\w+\.\d+)$/) {
					$phenoko = $1;
				} elsif ($fbaSims->[$i]->geneKOs()->[$j]->id() =~ m/(\w+\.\d+)$/) {
					$phenoko .= ";".$1;
				}
			}
			for (my $j=0; $j < @{$fbaSims->[$i]->reactionKOs()}; $j++) {
				if ($phenoko eq "none") {
					$phenoko = $fbaSims->[$i]->reactionKOs()->[$j]->id();
				} else {
					$phenoko .= ";".$fbaSims->[$i]->reactionKOs()->[$j]->id();
				}
			}
			push(@{$phenoData},$fbaSims->[$i]->uuid()."\t".$phenoko."\t".$media);
		}
		#Adding all additional media used as secondary media to FBAFormulation
		my $mediaRef = $self->secondaryMedia();
		foreach my $tempmedia (keys(%{$mediaHash})) {
			if ($tempmedia ne $self->media()->name()) {
				push(@{$self->secondaryMedia_uuids()},$mediaHash->{$tempmedia}->uuid());
				push(@{$mediaRef},$mediaHash->{$tempmedia});
			}
		}
		ModelSEED::utilities::PRINTFILE($self->jobDirectory()."/".$fbaExpFile,$phenoData);
	}
	return $fbaExpFile;
}

=head3 createTemporaryMedia

Definition:
	ModelSEED::MS::Media = createTemporaryMedia({
		name => "Temp".$tempMediaIndex,
		media => $fbaSims->[$i]->media(),
		additionalCpd => $fbaSims->[$i]->additionalCpds()
	});
Description:
	Creates a temporary media conditions with the specified base media plus the specified additional compounds

=cut

sub createTemporaryMedia {
	my ($self,$args) = @_;
	$args = ModelSEED::utilities::ARGS($args,["name","media","additionalCpd"],{});
	my $newMedia = ModelSEED::MS::Media->new({
		isDefined => 1,
		isMinimal => 0,
		id => $args->{name},
		name => $args->{name},
		type => "temporary"
	});
	$newMedia->parent($self->biochemistry());
	my $cpds = $args->{media}->mediacompounds();
	my $cpdHash = {};
	foreach my $cpd (@{$cpds}) {
		$cpdHash->{$cpd->compound_uuid()} = {
			compound_uuid => $cpd->compound_uuid(),
			concentration => $cpd->concentration(),
			maxFlux => $cpd->maxFlux(),
			minFlux => $cpd->minFlux(),
		};
	}
	foreach my $cpd (@{$args->{additionalCpd}}) {
		$cpdHash->{$cpd->uuid()} = {
			compound_uuid => $cpd->uuid(),
			concentration => 0.001,
			maxFlux => 100,
			minFlux => -100,
		};
	}
	foreach my $cpd (keys(%{$cpdHash})) {
		$newMedia->add("mediacompounds",$cpdHash->{$cpd});	
	}
	return $newMedia;
}

=head3 parsePhenotypeSimulations

Definition:
	void parsePhenotypeSimulations(
		[{}]
	);
Description:
	Parses array of hashes with phenotype specifications

=cut

sub parsePhenotypeSimulations {
	my ($self,$args) = @_;
	$args = ModelSEED::utilities::ARGS($args,["fbaPhenotypeSimulations"],{});
	my $phenos = $args->{fbaPhenotypeSimulations};
	for (my $i=0; $i < @{$phenos};$i++) {
		my ($addnluuids,$addnlcpds,$genokouuids,$genekos,$reactionkouuids,$reactionkos) = ([],[],[],[],[],[]);
		my $pheno = $phenos->[$i];
		(my $obj,my $type) = $self->interpretReference($pheno->{media},"Media");
		if (defined($pheno->{geneKOs})) {
			foreach my $gene (@{$pheno->{geneKOs}}) {
				(my $obj) = $self->interpretReference($gene,"Feature");
				if (defined($obj)) {
					push(@{$genekos},$obj);
					push(@{$genokouuids},$obj->uuid());
				}
			}
		}
		if (defined($pheno->{reactionKOs})) {
			foreach my $gene (@{$pheno->{reactionKOs}}) {
				(my $obj) = $self->interpretReference($gene,"Reaction");
				if (defined($obj)) {
					push(@{$reactionkos},$obj);
					push(@{$reactionkouuids},$obj->uuid());
				}
			}
		}
		if (defined($pheno->{additionalCpds})) {
			foreach my $gene (@{$pheno->{additionalCpds}}) {
				(my $obj) = $self->interpretReference($gene,"Compound");
				if (defined($obj)) {
					push(@{$addnlcpds},$obj);
					push(@{$addnluuids},$obj->uuid());
				}
			}
		}
		if (defined($obj)) {
			$self->add("fbaPhenotypeSimulations",{
				media => $obj,
				media_uuid => $obj->uuid(),
				label => $i,
				pH => $pheno->{pH},
				temperature => $pheno->{temperature},
				label => $pheno->{label},
				additionalCpd_uuids => $addnluuids,
				additionalCpds => $addnlcpds,
				geneKO_uuids => $genokouuids,
				geneKOs => $genekos,
				reactionKO_uuids => $reactionkouuids,
				reactionKOs => $reactionkos,
				observedGrowthFraction => $pheno->{growth}
			});
		}
	}
}

=head3 parseObjectiveTerms

Definition:
	void parseObjectiveTerms(
		[string]
	);
Description:
	Parses array of strings specifying objective into objective term sub objects

=cut

sub parseObjectiveTerms {
	my ($self,$args) = @_;
	$args = ModelSEED::utilities::ARGS($args,["objTerms"],{});
	my $terms = $args->{objTerms};
	for (my $i=0; $i < @{$terms};$i++) {
		(my $obj,my $type) = $self->interpretReference($terms->[$i]->{id});
		if (defined($obj)) {
			$self->add("fbaObjectiveTerms",{
				coefficient => $terms->[$i]->{coefficient},
				variableType => $terms->[$i]->{variableType},
				entityType => $type,
				entity_uuid => $obj->uuid(),
			});
		}
	}
}

=head3 parseConstraints

Definition:
	void parseConstraints({
		constraints => [string]
	});
Description:
	Parses array of strings specifying special constraints into constraint objects

=cut

sub parseConstraints {
	my ($self,$args) = @_;
	$args = ModelSEED::utilities::ARGS($args,["constraints"],{});
	my $vartrans = {
		f => "flux",ff => "forflux",rf => "revflux",
		df => "drainflux",fdf => "fordrainflux",rdf => "revdrainflux",
		ffu => "forfluxuse",rfu => "reffluxuse"
	};
	for (my $i=0; $i < @{$args->{constraints}};$i++) {
		my $array = [split(/\+/,$args->{constraints}->[$i]->{terms})];
		my $terms;
		for (my $j=0; $j < @{$array};$j++) {
			if ($array->[$j] =~ /\((\d+\.*\d*)\)(\w+)_([\w\/]+)\[(w+)\]/) {
				my $coef = $1;
				my $vartype = $vartrans->{$2};
				(my $obj,my $type) = $self->interpretReference($3);
				push(@{$terms},{
					entity_uuid => $obj->uuid(),
					entityType => $type,
					variableType => $vartype,
					coefficient => $coef
				});
			}
		}
		$self->add("fbaConstraints",{
			name => $args->{constraints}->[$i]->{name},
			rhs => $args->{constraints}->[$i]->{rhs},
			sign => $args->{constraints}->[$i]->{sign},
			fbaConstraintVariables => $terms
		});
	}
}

=head3 parseReactionKOList

Definition:
	void parseReactionKOList(
		string => string(none),delimiter => string(|),array => [string]([])
	);
Description:
	Parses a string or array of strings specifying a list of reaction KOs in the form of references

=cut

sub parseReactionKOList {
	my ($self,$args) = @_;
	$args->{data} = "uuid";
	$args->{type} = "Reaction";
	$self->reactionKO_uuids($self->parseReferenceList($args));
}

=head3 parseGeneKOList

Definition:
	void parseGeneKOList(
		string => string(none),delimiter => string(|),array => [string]([])
	);
Description:
	Parses a string or array of strings specifying a list of gene KOs in the form of references

=cut

sub parseGeneKOList {
	my ($self,$args) = @_;
	$args->{data} = "uuid";
	$args->{type} = "Feature";
	$self->geneKO_uuids($self->parseReferenceList($args));
}

__PACKAGE__->meta->make_immutable;
1;
