package ModelSEED::App::model::Command::simphenotypes;
use strict;
use common::sense;
use base 'App::Cmd::Command';
use Class::Autouse qw(
    ModelSEED::Store
    ModelSEED::Auth::Factory
    ModelSEED::Reference
    ModelSEED::Configuration
    ModelSEED::App::Helpers
    ModelSEED::MS::Factories::ExchangeFormatFactory
);
sub abstract { return "Simulate table of growth phenotypes"; }
sub usage_desc { return "model simphenotypes [ model || - ] [filename] [options]"; }
sub opt_spec {
    return (
        ["save|s", "Save results in the existing model"],
        ["saveas|sa:s", "Save results in a new model"],
        ["verbose|v", "Print verbose status information"],
        ["notes:s","User notes to be affiliated with FBA simulation"],
        ["objective:s","String describing the objective of the FBA problem"],
        ["rxnko:s","Comma delimited list of reactions in model to be knocked out"],
        ["geneko:s","Comma delimited list of genes in model to be knocked out"],
        ["uptakelim:s","List of max uptakes for atoms to be used as constraints"],
        ["defaultmaxflux:s","Maximum flux to use as default"],
        ["defaultmaxuptake:s","Maximum uptake flux to use as default"],
        ["defaultminuptake:s","Minimum uptake flux to use as default"],
        ["help|h|?", "Print this usage information"],
    );
}

sub execute {
    my ($self, $opts, $args) = @_;
    print($self->usage) && exit if $opts->{help};
    my $auth  = ModelSEED::Auth::Factory->new->from_config;
    my $store = ModelSEED::Store->new(auth => $auth);
    my $helper = ModelSEED::App::Helpers->new();
    #Retreiving the model object on which FBA will be performed
    (my $model,my $ref) = $helper->get_object("model",$args,$store);
    $self->usage_error("Model not found; You must supply a valid model name.") unless(defined($model));
	#Standard commands to handle where output will be printed
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
			$newpheno->{geneKOs} = [split(/,/,$row->[$columns->{geneKOs}])];
		}
		if ($columns->{reactionKOs} != -1 && $row->[$columns->{reactionKOs}] ne "none") {
			$newpheno->{reactionKOs} = [split(/,/,$row->[$columns->{reactionKOs}])];
		}
		if ($columns->{additionalCpds} != -1 && $row->[$columns->{additionalCpds}] ne "none") {
			$newpheno->{additionalCpds} = [split(/,/,$row->[$columns->{additionalCpds}])];
		}
		if ($columns->{pH} != -1) {
			$newpheno->{pH} = $row->[$columns->{pH}];
		}
		if ($columns->{temperature} != -1) {
			$newpheno->{temperature} = $row->[$columns->{temperature}];
		}
		if ($columns->{growth} != -1) {
			$newpheno->{growth} = $row->[$columns->{growth}];
		}
		push(@{$input->{overrides}->{fbaPhenotypeSimulations}},$newpheno);
	}
	my $exchange_factory = ModelSEED::MS::Factories::ExchangeFormatFactory->new();
	my $fbaform = $exchange_factory->buildFBAFormulation($input);
    #Running FBA
    print STDERR "Running FBA..." if($opts->{verbose});
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
	    if ($opts->{save}) {
	    	print STDERR "Saving model with FBA solution over original model...\n" if($opts->{verbose});
	    	$model->add("fbaFormulations",$fbaform);
	    	$store->save_object($ref,$model);
	    } elsif ($opts->{saveas}) {
			$ref = $helper->process_ref_string($opts->{saveas}, "model", $auth->username);
			print STDERR "Saving model with FBA solution as new model ".$ref."...\n" if($opts->{verbose});
			$model->add("fbaFormulations",$fbaform);
			$store->save_object($ref,$model);
	    }
    }
}

1;
