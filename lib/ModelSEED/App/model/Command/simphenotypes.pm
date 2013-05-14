package ModelSEED::App::model::Command::simphenotypes;
use strict;
use common::sense;
use ModelSEED::App::model;
use base 'ModelSEED::App::ModelBaseCommand';
use Class::Autouse qw(
    ModelSEED::MS::Factories::ExchangeFormatFactory
);
use ModelSEED::utilities qw( config error args verbose set_verbose translateArrayOptions);
sub abstract { return "Simulate table of growth phenotypes" }
sub usage_desc { return "model simphenotypes [model id] [filename] [options]" }
sub options {
    return (
        ["notes:s","User notes to be affiliated with FBA simulation"],
        ["objective:s","String describing the objective of the FBA problem"],
        ["rxnko:s","Comma delimited list of reactions in model to be knocked out"],
        ["geneko:s","Comma delimited list of genes in model to be knocked out"],
        ["uptakelim:s","List of max uptakes for atoms to be used as constraints"],
        ["defaultmaxflux:s","Maximum flux to use as default"],
        ["defaultmaxuptake:s","Maximum uptake flux to use as default"],
        ["defaultminuptake:s","Minimum uptake flux to use as default"],
        ["save|s", "Save results in the existing model"],
        ["saveas|sa:s", "Save results in a new model"],
    );
}

sub sub_execute {
    my ($self, $opts, $args,$model) = @_;
	#Reading file with phenotype data
	if (!defined($args->[1]) || !-e $args->[1]) {
		$self->usage_error("Phenotype specification file not found.");
	}
	my $phenoData = ModelSEED::utilities::LOADTABLE($args->[1],"\\t");
	#Creating FBA formulation
	my $input = {model => $model,overrides => {media => "Media/name/Carbon-D-Glucose"}};
	my $fbaoverrides = {
		objective => "objectiveString",rxnko => "geneKO",geneko => "reactionKO",uptakelim => "uptakeLimits",
		defaultmaxflux => "defaultMaxFlux",defaultmaxuptake => "defaultMaxDrainFlux",defaultminuptake => "defaultMinDrainFlux"
	};
	foreach my $argument (keys(%{$fbaoverrides})) {
		if (defined($opts->{$argument})) {
			$input->{overrides}->{$fbaoverrides->{$argument}} = $opts->{$argument};
		}
	}
	#Parsing phenotype data
	$input->{overrides}->{fbaPhenotypeSimulations} = [];
	my $columns = {label => -1,geneKOs => -1,reactionKOs => -1,media => -1,additionalCpds => -1,temperature => -1,pH => -1,growth => -1};
	for (my $i=0; $i < @{$phenoData->{headings}}; $i++) {
		$columns->{$phenoData->{headings}->[$i]} = $i;
	}
	for (my $i=0; $i < @{$phenoData->{data}}; $i++) {
		my $row = $phenoData->{data}->[$i];
		my $newpheno = {label => $i,media => $row->[$columns->{media}]};
		if ($columns->{geneKOs} != -1 && $row->[$columns->{geneKOs}] ne "none") {
			$newpheno->{geneKOs} = [split(/;/,$row->[$columns->{geneKOs}])];
		} else {
			$newpheno->{geneKOs} = [];
		}
		if ($columns->{reactionKOs} != -1 && $row->[$columns->{reactionKOs}] ne "none") {
			$newpheno->{reactionKOs} = [split(/;/,$row->[$columns->{reactionKOs}])];
		} else {
			$newpheno->{reactionKOs} = [];
		}
		if ($columns->{additionalCpds} != -1 && $row->[$columns->{additionalCpds}] ne "none") {
			$newpheno->{additionalCpds} = [split(/;/,$row->[$columns->{additionalCpds}])];
		} else {
			$newpheno->{additionalCpds} = [];
		}
		if ($columns->{pH} != -1) {
			$newpheno->{pH} = $row->[$columns->{pH}];
		} else {
			$newpheno->{pH} = 7;
		}
		if ($columns->{temperature} != -1) {
			$newpheno->{temperature} = $row->[$columns->{temperature}];
		} else {
			$newpheno->{temperature} = 298;
		}
		if ($columns->{growth} != -1) {
			$newpheno->{growth} = $row->[$columns->{growth}];
		}
		push(@{$input->{overrides}->{fbaPhenotypeSimulations}},$newpheno);
	}
	my $exchange_factory = ModelSEED::MS::Factories::ExchangeFormatFactory->new();
	my $fbaform = $exchange_factory->buildFBAFormulation($input);
    #Running FBA
    verbose("Running FBA...");
    my $fbaResult = $fbaform->runFBA();
    #Standard commands that save results of the analysis to the database
    if (!defined($fbaResult) || @{$fbaResult->fbaPhenotypeSimultationResults()} == 0) {
    	print STDERR " FBA failed with no solution returned!\n";
    } else {
    	my $phenoresults = $fbaResult->fbaPhenotypeSimultationResults();
    	my $newColumnStart = @{$phenoData->{headings}};
    	$phenoData->{headings}->[$newColumnStart] = "Simulated growth fraction";
    	$phenoData->{headings}->[$newColumnStart+1] = "Simulated growth";
    	$phenoData->{headings}->[$newColumnStart+2] = "Class";
    	foreach my $phenoResult (@{$phenoresults}) {
    		$phenoData->{data}->[$phenoResult->fbaPhenotypeSimulation()->label()]->[$newColumnStart] = $phenoResult->simulatedGrowthFraction();
    		$phenoData->{data}->[$phenoResult->fbaPhenotypeSimulation()->label()]->[$newColumnStart+1] = $phenoResult->simulatedGrowth();
    		$phenoData->{data}->[$phenoResult->fbaPhenotypeSimulation()->label()]->[$newColumnStart+2] = $phenoResult->class();
    	}
    	ModelSEED::utilities::PRINTTABLE("STDOUT",$phenoData);
	    #Standard commands that save results of the analysis to the database
	    if ($opts->{save} || $opts->{saveas}) {
	    	$self->save_object({
				type => "FBAFormulation",
				reference => "FBAFormulation/".$fbaform->uuid(),
				object => $fbaform
			});
	    	$model->add("fbaFormulations",$fbaform);
	    	$self->save_model($model);
	    }
    }
}

1;