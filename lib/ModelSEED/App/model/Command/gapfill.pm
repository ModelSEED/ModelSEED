package ModelSEED::App::model::Command::gapfill;
use strict;
use common::sense;
use ModelSEED::App::model;
use base 'ModelSEED::App::ModelBaseCommand';
use Class::Autouse qw(
    ModelSEED::MS::Factories::ExchangeFormatFactory
);
use ModelSEED::utilities;
sub abstract { return "Fill gaps in the reaction network for a model"; }
sub usage_desc { return "model gapfill [model] [options]"; }
sub options {
    return (
        ["media:s","Media formulation to be used for the FBA simulation"],
        ["notes:s","User notes to be affiliated with FBA simulation"],
        ["objective:s","String describing the objective of the FBA problem"],
        ["numsolutions|n:s","Number of solutions desired"],
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
	["cplextimelimit:s", "Time limit for CPLEX solver in seconds: defaults to 3600 seconds"],
	["milptimelimit:s", "Time limit for MILP recursion in seconds: defaults to 3600 seconds"],
        ["loadsolution|l:s", "Loading existing solution into model"],
        ["norun", "Do not gapfill; print out the configuration as JSON"],
        ["integratesol|i", "Integrate first solution into model"],
        ["printraw|r", "Print raw data instead of readable data"],
        ["saveas|a:s", "New name the results should be saved to"],
    );
}

sub sub_execute {
    my ($self, $opts, $args,$model) = @_;
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
        geneko           => "geneKO",
        rxnko            => "reactionKO",
        uptakelim        => "uptakeLimits",
        defaultmaxflux   => "defaultMaxFlux",
        defaultmaxuptake => "defaultMaxDrainFlux",
        defaultminuptake => "defaultMinDrainFlux",
        numsolutions	 => "numberOfSolutions",
	cplextimelimit   => "cplexTimeLimit",
        milptimelimit    => "milpRecursionTimeLimit",
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
    ModelSEED::utilities::verbose("Running Gapfilling...");
    $gapfillingFormulation = $model->gapfillModel({gapfillingFormulation => $gapfillingFormulation});
    my $solutions = $gapfillingFormulation->gapfillingSolutions();
    if (!defined($solutions) || @{$solutions} == 0) {
    	ModelSEED::utilities::verbose("Reactions passing user criteria were insufficient to enable objective!");
    	return;
    }
    my $numSolutions = @{$solutions};
    if ($opts->{printraw}) {
    	for (my $i=0; $i < @{$solutions}; $i++) {
    		$solutions->[$i] = $solutions->[$i]->serializeToDB();
    	}
    	print ModelSEED::utilities::TOJSON($solutions,1);
    } else {
    	my $index = @{$model->unintegratedGapfillings()};
    	print $gapfillingFormulation->printStudy(($index-1));
    }
    if ($opts->{integratesol}) {
    	ModelSEED::utilities::verbose("Automatically integrating first solution in model.");
    	$model->integrateGapfillSolution($gapfillingFormulation,0);
    }
    $self->save_object({
		type => "FBAFormulation",
		reference => "FBAFormulation/".$gapfillingFormulation->fbaFormulation()->uuid(),
		object => $gapfillingFormulation->fbaFormulation()
	});
    $self->save_object({
    	type => "GapfillingFormulation",
		reference => "GapfillingFormulation/".$gapfillingFormulation->uuid(),
		object => $gapfillingFormulation
	});
    $self->save_model($opts,$model);
}

1;
