package ModelSEED::App::model::Command::gapgen;
use strict;
use common::sense;
use ModelSEED::App::model;
use base 'ModelSEED::App::ModelBaseCommand';
use Class::Autouse qw(
    ModelSEED::MS::Factories::ExchangeFormatFactory
);
use ModelSEED::utilities;
sub abstract { return "Identify changes in the model to force an objective to zero in the specified conditions" }
sub usage_desc { return "model gapgen [model] [options]" }
sub options {
    return (
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
	["cplextimelimit:s", "Time limit for CPLEX solver in seconds: defaults to 3600 seconds"],
	["milptimelimit:s", "Time limit for MILP recursion in seconds: defaults to 3600 seconds"],
        ["norun", "Do not gapfill; print out the configuration as JSON"],
        ["integratesol|i", "Integrate first solution into model"],
        ["printraw|r", "Print raw data instead of readable data"],
        ["saveas|a:s", "New name the results should be saved to"]
    );
}
sub sub_execute {
    my ($self, $opts, $args,$model) = @_;
	#Standard commands to handle where output will be printed
    my $out_fh = \*STDOUT;
	#Creating gapfilling formulation
	my $input = {model => $model};
	my $fbaoverrides = {
		media => "media",notes => "notes",objfraction => "objectiveConstraintFraction",
		objective => "objectiveString",rxnko => "geneKO",geneko => "reactionKO",uptakelim => "uptakeLimits",
		defaultmaxflux => "defaultMaxFlux",defaultmaxuptake => "defaultMaxDrainFlux",defaultminuptake => "defaultMinDrainFlux",
		cplextimelimit => "cplexTimeLimit",milptimelimit    => "milpRecursionTimeLimit",
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
		    if(defined($opts->{$argument})){
			$input->{overrides}->{$overrideList->{$argument}} = $opts->{$argument};
		    }
		}
	}
	foreach my $argument (keys(%{$fbaoverrides})) {
		if (defined($opts->{$argument})) {
			$input->{overrides}->{fbaFormulation}->{overrides}->{$fbaoverrides->{$argument}} = $opts->{$argument};
		}
	}
	my $exchange_factory = ModelSEED::MS::Factories::ExchangeFormatFactory->new();
	my $gapgenFormulation = $exchange_factory->buildGapgenFormulation($input);
    if ($opts->{norun}) {
        print $gapgenFormulation->toJSON();
        return;
    }
    ModelSEED::utilities::verbose("Running gapgeneration...");
    $gapgenFormulation = $model->gapgenModel({
        gapgenFormulation => $gapgenFormulation,
    });
	my $solutions = $gapgenFormulation->gapgenSolutions();
    if (!defined($solutions) || @{$solutions} == 0) {
    	ModelSEED::utilities::verbose("Could not find knockouts to meet gapgen specifications!");
    	return;
    }
    my $numSolutions = @{$solutions};
	ModelSEED::utilities::verbose($numSolutions." viable solutions identified.");
    if ($opts->{printraw}) {
    	for (my $i=0; $i < @{$solutions}; $i++) {
    		$solutions->[$i] = $solutions->[$i]->serializeToDB();
    	}
    	print ModelSEED::utilities::TOJSON($solutions,1);
    } else {
    	my $index = @{$model->unintegratedGapgens()};
    	print $gapgenFormulation->printSolutions(($index-1));
    }
    if ($opts->{integratesol}) {
    	ModelSEED::utilities::verbose("Automatically integrating first solution in model.");
    	$model->integrateGapgenSolution($gapgenFormulation,0);
    }
    $self->save_object({
		type => "FBAFormulation",
		reference => "FBAFormulation/".$gapgenFormulation->fbaFormulation()->uuid(),
		object => $gapgenFormulation->fbaFormulation()
	});
    $self->save_object({
		type => "GapgenFormulation",
		reference => "GapgenFormulation/".$gapgenFormulation->uuid(),
		object => $gapgenFormulation
	});
    $self->save_model();
}

1;
