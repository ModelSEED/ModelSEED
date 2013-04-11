package ModelSEED::App::model::Command::runfba;
use strict;
use common::sense;
use ModelSEED::App::model;
use Class::Autouse qw(
    JSON::XS
    ModelSEED::MS::Factories::ExchangeFormatFactory
    ModelSEED::MS::FBAFormulation
    ModelSEED::Solver::FBA
);
use base 'ModelSEED::App::ModelBaseCommand';
use ModelSEED::utilities qw( config error args verbose set_verbose translateArrayOptions);
sub abstract { return "Run flux balance analysis on the model" }
sub usage_desc { return "model runfba [model id] [options]" }
sub options {
    return (
    	["config|c:s", "Configuration filename for formulating the FBA"],
        ["media:s","Media formulation to be used for the FBA simulation"],
        ["notes:s","User notes to be affiliated with FBA simulation"],
        ["objective:s","String describing the objective of the FBA problem"],
        ["objfraction:s","Fraction of the objective to enforce to ensure"],
        ["rxnko:s","Comma delimited list of reactions to be knocked out"],
        ["geneko:s","Comma delimited list of genes to be knocked out"],
        ["uptakelim:s","List of max uptakes for atoms to be used as constraints"],
        ["defaultmaxflux:s","Maximum flux to use as default"],
        ["defaultmaxuptake:s","Maximum uptake flux to use as default"],
        ["defaultminuptake:s","Minimum uptake flux to use as default"],
        ["fva","Perform flux variability analysis"],
        ["prom:s","promModel object to perform probabilistic regulation of metabolism (PROM)"],
        ["simulateko","Simulate single gene knockouts"],
        ["minimizeflux","Minimize fluxes in output solution"],
        ["findminmedia","Predict minimal media formulations for the model"],
        ["allreversible","Make all reactions reversible in FBA simulation"],
        ["simplethermoconst","Use simple thermodynamic constraints"],
        ["thermoconst","Use standard thermodynamic constraints"],
        ["nothermoerror","Do not include uncertainty in thermodynamic constraints"],
        ["minthermoerror","Minimize uncertainty in thermodynamic constraints"],
        ["norun", "Do not run the FBA; print out the configuration as JSON"],
        ["html","Print FBA results in HTML"],
        ["readable","Print FBA results in readable format"],
        ["save|s", "Save results in the existing model"],
        ["saveas|sa:s", "Save results in a new model"],
    );
}
sub sub_execute {
    my ($self, $opts, $args,$model) = @_;
    my $pmodel;
    if (defined($opts->{prom})) {
	    $pmodel $self->get_object({
	    	type => "PROMModel",
	    	reference => $opts->{prom},
	    	store => $opts->{store},
	    });
    }
    my $fbaform;
    if ($opts->{config}) {
        $fbaform = $self->object_from_file({
        	type => "FBAFormulation",
        	filename => $opts->{config},
        	store => $opts->{store}
        });
    } else {
        # Creating FBA formulation
        my $input = { model => $model, promModel => $pmodel };
        my $overrideList = {
            media             => "media",
            notes             => "notes",
            fva               => "fva",
            simulateko        => "comboDeletions",
            minimizeflux      => "fluxMinimization",
            findminmedia      => "findMinimalMedia",
            objfraction       => "objectiveConstraintFraction",
            allreversible     => "allReversible",
            objective         => "objectiveString",
            geneko             => "geneKO",
            rxnko            => "reactionKO",
            uptakelim         => "uptakeLimits",
            defaultmaxflux    => "defaultMaxFlux",
            defaultminuptake  => "defaultMinDrainFlux",
            defaultmaxuptake  => "defaultMaxDrainFlux",
            simplethermoconst => "simpleThermoConstraints",
            thermoconst       => "thermodynamicConstraints",
            nothermoerror     => "noErrorThermodynamicConstraints",
            minthermoerror    => "minimizeErrorThermodynamicConstraints"
        };
        foreach my $argument (keys(%{$overrideList})) {
            if (defined($opts->{$argument})) {
                $input->{overrides}->{$overrideList->{$argument}} = $opts->{$argument};
            }
        }
	    my $exchange_factory = ModelSEED::MS::Factories::ExchangeFormatFactory->new();
	    $fbaform = $exchange_factory->buildFBAFormulation($input);
    }
    if ($opts->{norun}) {
        # Pretty print the formulation if "norun" option supplied
        print $fbaform->toJSON({ pp => 1});
        return;
    }
    # Running FBA
    verbose("Running FBA...");
    my $results = $fbaform->runFBA(); 
    if (!defined($results)) {
    	print STDERR " FBA failed with no solution returned!\n";
    } else {
	    push(@{$model->fbaFormulation_uuids()},$fbaform->uuid());
	    # Standard commands that save results of the analysis to the database
	    if ($opts->{save} || $opts->{saveas}) {
	    	$self->save_object({
				type => "FBAFormulation",
				reference => "FBAFormulation/".$fbaform->uuid(),
				object => $gapfillingFormulation->fbaFormulation()
			});
	    	$model->add("fbaFormulations",$fbaform);
	    	$self->save_model($model);
	    }
	    if ($opts->{html}) {
	    	print $fbaform->createHTML();
	    } elsif ($opts->{readable}) {
	    	print $fbaform->toReadableString();
	    } else {
	    	print $fbaform->toJSON({pp => 1});
	    }
    }
}

1;
