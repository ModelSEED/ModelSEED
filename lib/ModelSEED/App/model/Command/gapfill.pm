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
        ["config|c=s", "Configuration filename for formulating the gapfilling"],
        ["fbaconfig|c=s", "Configuration filename for the FBA formulation used by the gapfilling"],
        ["overwrite|o", "Overwrite existing model with gapfilled model"],
        ["save|s:s", "Save gapfilled model to new model name"],
        ["verbose|v", "Print verbose status information"],
        ["fileout|f:s", "Name of file where FBA solution object will be printed"],
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
	# Redirect output to file if we need to
    my $out_fh;
	if ($opts->{fileout}) {
	    open($out_fh, ">", $opts->{fileout}) or die "Cannot open ".$opts->{fileout}.": $!";
	} else {
	    $out_fh = \*STDOUT;
	}
	# Creating gapfilling formulation
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
    if (defined($opts->{loadsolution}) && -d $opts->{loadsolution}) {
		my $fbaform = $gapfillingFormulation->prepareFBAFormulation();
		my $directory = $fbaform->jobDirectory();
		$fbaform->jobDirectory($opts->{loadsolution});
		my $fbaresults = $fbaform->add("fbaResults",{});
		$fbaresults->loadMFAToolkitResults();
		my $solutions = $fbaresults->gapfillingSolutions();
		if (defined($solutions->[0])) {
			$result = $solutions->[0];
		}
	} else {
		#Running gapfilling
	    print STDERR "Running Gapfilling...\n" if($opts->{verbose});
	    $result = $model->gapfillModel({
	        gapfillingFormulation => $gapfillingFormulation,
	    });
	}
    if (!defined($result)) {
    	print STDERR " Reactions passing user criteria were insufficient to enable objective!\n";
    } else {
		print $out_fh $result->toJSON({pp => 1});
	    # Standard commands that save results of the analysis to the database
        my $fbaFormulation = $gapfillingFormulation->fbaFormulation;
	    if ($opts->{overwrite} || $opts->{save}) {
            $store->save_object("fBAFormulation/".$fbaFormulation->uuid, $fbaFormulation);
            $store->save_object("gapfillingFormulation/".$gapfillingFormulation->uuid, $gapfillingFormulation);
        }
        if ($opts->{overwrite}) {
	    	print STDERR "Saving gapfilled model over original model...\n" if($opts->{verbose});
	    	$store->save_object($ref, $model);
	    } elsif ($opts->{save}) {
			my $new_ref = $helper->process_ref_string($opts->{save}, "model", $auth->username);
			print STDERR "Saving gapfilled model as new model ".$new_ref."...\n" if($opts->{verbose});
			$store->save_object($ref, $model);
	    }
    }
    close $out_fh if $opts->{fileout};
}

1;
