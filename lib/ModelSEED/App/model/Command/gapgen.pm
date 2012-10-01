package ModelSEED::App::model::Command::gapgen;
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
sub abstract { return "Identify changes in the model to force an objective to zero in the specified conditions"; }
sub usage_desc { return "model gapgen [ model || - ] [options]"; }
sub opt_spec {
    return (
        ["verbose|v", "Print verbose status information"],
        ["media:s","Target media formulation in which to force objective to zero"],
        ["refmedia:s","Reference media formulation in which the objective must be nonzero"],
        ["notes:s","User notes to be affiliated with FBA simulation"],
        ["nomediahyp","Set this flag to turn off media hypothesis"],
        ["nobiomasshyp","Set this flag to turn off biomass hypothesis"],
        ["nogprhyp","Set this flag to turn off GPR hypothesis"],
        ["nopathwayhyp","Set this flag to turn off pathway hypothesis"],
        ["objective:s","String describing the objective of the FBA problem"],
        ["objfraction:s","Fraction of the objective to enforce to ensure"],
        ["rxnko:s","Comma delimited list of reactions in model to be knocked out"],
        ["geneko:s","Comma delimited list of genes in model to be knocked out"],
        ["uptakelim:s","List of max uptakes for atoms to be used as constraints"],
        ["defaultmaxflux:s","Maximum flux to use as default"],
        ["defaultmaxuptake:s","Maximum uptake flux to use as default"],
        ["defaultminuptake:s","Minimum uptake flux to use as default"],
        ["integratesol|i", "Integrate first solution into model"],
        ["printraw|r", "Print raw data instead of readable data"],
        ["saveas|a:s", "New name the results should be saved to"],
        ["dryrun|d", "Donot save results in database"],
        ["help|h|?", "Print this usage information"]
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
	if ($opts->{verbose}) {
    	ModelSEED::utilities::SETVERBOSE(1);
    	delete $opts->{verbose};
    }
	#Standard commands to handle where output will be printed
    my $out_fh = \*STDOUT;
	#Creating gapfilling formulation
	my $input = {model => $model};
	my $fbaoverrides = {
		media => "media",notes => "notes",objfraction => "objectiveConstraintFraction",
		objective => "objectiveString",rxnko => "geneKO",geneko => "reactionKO",uptakelim => "uptakeLimits",
		defaultmaxflux => "defaultMaxFlux",defaultmaxuptake => "defaultMaxDrainFlux",defaultminuptake => "defaultMinDrainFlux"
	};
	my $overrideList = {
		refmedia => "referenceMedia",nomediahyp => "!mediaHypothesis",nobiomasshyp => "!biomassHypothesis",
		nogprhyp => "!gprHypothesis",nopathwayhyp => "!reactionRemovalHypothesis"
	};
	foreach my $argument (keys(%{$overrideList})) {
		if ($overrideList->{$argument} =~ m/^\!(.+)$/) {
			$argument = $1;
			if (defined($opts->{$argument})) {
				$input->{overrides}->{$overrideList->{$argument}} = 0;
			} else {
				$input->{overrides}->{$overrideList->{$argument}} = 1;
			}
		} else {
			$input->{overrides}->{$overrideList->{$argument}} = $opts->{$argument};
		}
	}
	foreach my $argument (keys(%{$fbaoverrides})) {
		if (defined($opts->{$argument})) {
			$input->{overrides}->{fbaFormulation}->{overrides}->{$fbaoverrides->{$argument}} = $opts->{$argument};
		}
	}
	my $exchange_factory = ModelSEED::MS::Factories::ExchangeFormatFactory->new();
	my $gapgenFormulation = $exchange_factory->buildGapgenFormulation($input);
    ModelSEED::utilities::VERBOSEMSG("Running gapgeneration...");
    $gapgenFormulation = $model->gapgenModel({
        gapgenFormulation => $gapgenFormulation,
    });
	my $solutions = $gapgenFormulation->gapgenSolutions();
    if (!defined($solutions) || @{$solutions} == 0) {
    	ModelSEED::utilities::VERBOSEMSG("Could not find knockouts to meet gapgen specifications!");
    	return;
    }
    my $numSolutions = @{$solutions};
	ModelSEED::utilities::VERBOSEMSG($numSolutions." viable solutions identified.");
    if ($opts->{printraw}) {
    	for (my $i=0; $i < @{$solutions}; $i++) {
    		$solutions->[$i] = $solutions->[$i]->serializeToDB();
    	}
    	print ModelSEED::utilities::TOJSON($solutions,1);
    } else {
    	print $gapgenFormulation->toReadableString();
    }
    if ($opts->{integratesol}) {
    	ModelSEED::utilities::VERBOSEMSG("Automatically integrating first solution in model.");
    	$model->integrateGapgenSolution($gapgenFormulation,0);
    }
    if ($opts->{saveas}) {
    	$ref = $helper->process_ref_string($opts->{saveas}, "model", $auth->username);
    	ModelSEED::utilities::VERBOSEMSG("New alias set for model:".$ref);
    }
    if ($opts->{dryrun}) {
    	ModelSEED::utilities::VERBOSEMSG("Dry run selected. Results not saved!");
    } else {
    	ModelSEED::utilities::VERBOSEMSG("Saving model to:".$ref);
    	$store->save_object("fBAFormulation/".$gapgenFormulation->fbaFormulation()->uuid(),$gapgenFormulation->fbaFormulation());
		$store->save_object("gapgenFormulation/".$gapgenFormulation->uuid(),$gapgenFormulation);
    	$store->save_object($ref,$model);
    }
}

1;