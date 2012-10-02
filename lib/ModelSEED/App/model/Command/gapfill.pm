package ModelSEED::App::model::Command::gapfill;
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
sub abstract { return "Fill gaps in the reaction network for a model"; }
sub usage_desc { return "model gapfill [ model || - ] [options]"; }
sub opt_spec {
    return (
        ["verbose|v", "Print verbose status information"],
        ["media:s","Media formulation to be used for the FBA simulation"],
        ["notes:s","User notes to be affiliated with FBA simulation"],
        ["objective:s","String describing the objective of the FBA problem"],
        ["nomediahyp","Set this flag to turn off media hypothesis"],
        ["nobiomasshyp","Set this flag to turn off biomass hypothesis"],
        ["nogprhyp","Set this flag to turn off GPR hypothesis"],
        ["nopathwayhyp","Set this flag to turn off pathway hypothesis"],
        ["allowunbalanced","Allow any unbalanced reactions to be used in gapfilling"],
        ["activitybonus:s","Add terms to objective favoring activation of inactive reactions"],
        ["drainpen:s","Penalty for gapfilling drain fluxes"],
        ["directionpen:s","Penalty for making irreversible reactions reverisble"],
        ["nostructpen:s","Penalty for reactions involving a substrate with unknown structure"],
        ["unfavorablepen:s","Penalty for thermodynamically unfavorable reactions"],
        ["nodeltagpen:s","Penalty for reactions with unknown free energy change"],
        ["biomasstranspen:s","Penalty for transporters involving biomass compounds"],
        ["singletranspen:s","Penalty for transporters with only one reactant and product"],
        ["transpen:s","Penalty for gapfilling transport reactions"],
        ["blacklistedrxns:s","'|' delimited list of reactions not allowed to be gapfilled"],
        ["gauranteedrxns:s","'|' delimited list of reactions always allowed to be gapfilled regardless of balance"],
        ["allowedcmps:s","'|' delimited list of compartments allowed in gapfilled reactions"],
        ["objfraction:s","Fraction of the objective to enforce to ensure"],
        ["rxnko:s","Comma delimited list of reactions in model to be knocked out"],
        ["geneko:s","Comma delimited list of genes in model to be knocked out"],
        ["uptakelim:s","List of max uptakes for atoms to be used as constraints"],
        ["defaultmaxflux:s","Maximum flux to use as default"],
        ["defaultmaxuptake:s","Maximum uptake flux to use as default"],
        ["defaultminuptake:s","Minimum uptake flux to use as default"],
        ["loadsolution|l:s", "Loading existing solution into model"],
        ["norun", "Do not gapfill; print out the configuration as JSON"],
        ["integratesol|i", "Integrate first solution into model"],
        ["printraw|r", "Print raw data instead of readable data"],
        ["saveas|a:s", "New name the results should be saved to"],
        ["dryrun|d", "Donot save results in database"],
        ["help|h|?", "Print this usage information"],
    );
}

sub execute {
    my ($self, $opts, $args) = @_;
    print($self->usage) && return if $opts->{help};
    my $auth  = ModelSEED::Auth::Factory->new->from_config;
    my $store = ModelSEED::Store->new(auth => $auth);
    my $helper = ModelSEED::App::Helpers->new();
    # Retreiving the model object on which FBA will be performed
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
	if ($opts->{config}) {
		$input->{filename} = $opts->{config};
	}
    my $fbaoverrides = {
        media            => "media",
        notes            => "notes",
        objfraction      => "objectiveConstraintFraction",
        objective        => "objectiveString",
        rxnko            => "geneKO",
        geneko           => "reactionKO",
        uptakelim        => "uptakeLimits",
        defaultmaxflux   => "defaultMaxFlux",
        defaultmaxuptake => "defaultMaxDrainFlux",
        defaultminuptake => "defaultMinDrainFlux"
    };
    my $overrideList = {
        nomediahyp      => "!mediaHypothesis",
        nobiomasshyp    => "!biomassHypothesis",
        nogprhyp        => "!gprHypothesis",
        nopathwayhyp    => "!reactionAdditionHypothesis",
        allowunbalanced => "!balancedReactionsOnly",
        activitybonus   => "reactionActivationBonus",
        drainpen        => "drainFluxMultiplier",
        directionpen    => "directionalityMultiplier",
        unfavorablepen  => "deltaGMultiplier",
        nodeltagpen     => "noDeltaGMultiplier",
        biomasstranspen => "biomassTransporterMultiplier",
        singletranspen  => "singleTransporterMultiplier",
        nostructpen     => "noStructureMultiplier",
        transpen        => "transporterMultiplier",
        blacklistedrxns => "blacklistedReactions",
        gauranteedrxns  => "guaranteedReactions",
        allowedcmps     => "allowableCompartments",
    };
	foreach my $argument (keys(%{$overrideList})) {
		if ($overrideList->{$argument} =~ m/^\!(.+)$/) {
			my $real_argument = $1;
			if (defined($opts->{$argument})) {
				$input->{overrides}->{$real_argument} = 0;
			} else {
				$input->{overrides}->{$real_argument} = 1;
			}
		} elsif (defined($opts->{$argument})) {
			$input->{overrides}->{$overrideList->{$argument}} = $opts->{$argument};
		}
	}
	foreach my $argument (keys(%{$fbaoverrides})) {
		if (defined($opts->{$argument})) {
			$input->{overrides}->{fbaFormulation}->{overrides}->{$fbaoverrides->{$argument}} = $opts->{$argument};
		}
	}
	my $exchange_factory = ModelSEED::MS::Factories::ExchangeFormatFactory->new();
	my $gapfillingFormulation = $exchange_factory->buildGapfillingFormulation($input);
    # Exit with config if thats what was requested
    if ($opts->{norun}) {
        print $gapfillingFormulation->toJSON();
        return;
    }
    my $result;
    ModelSEED::utilities::VERBOSEMSG("Running Gapfilling...");
    $gapfillingFormulation = $model->gapfillModel({gapfillingFormulation => $gapfillingFormulation});
    my $solutions = $gapfillingFormulation->gapfillingSolutions();
    if (!defined($solutions) || @{$solutions} == 0) {
    	ModelSEED::utilities::VERBOSEMSG("Reactions passing user criteria were insufficient to enable objective!");
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
    	print $gapfillingFormulation->toReadableString();
    }
    if ($opts->{integratesol}) {
    	ModelSEED::utilities::VERBOSEMSG("Automatically integrating first solution in model.");
    	$model->integrateGapfillSolution($gapfillingFormulation,0);
    }
    if ($opts->{saveas}) {
    	$ref = $helper->process_ref_string($opts->{saveas}, "model", $auth->username);
    	ModelSEED::utilities::VERBOSEMSG("New alias set for model:".$ref);
    }
    if ($opts->{dryrun}) {
    	ModelSEED::utilities::VERBOSEMSG("Dry run selected. Results not saved!");
    } else {
    	ModelSEED::utilities::VERBOSEMSG("Saving model to:".$ref);
    	$store->save_object("fBAFormulation/".$gapfillingFormulation->fbaFormulation()->uuid(),$gapfillingFormulation->fbaFormulation());
		$store->save_object("gapfillingFormulation/".$gapfillingFormulation->uuid(),$gapfillingFormulation);
    	$store->save_object($ref,$model);
    }
}

1;
