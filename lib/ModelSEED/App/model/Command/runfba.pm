package ModelSEED::App::model::Command::runfba;
use strict;
use common::sense;
use base 'App::Cmd::Command';
use Class::Autouse qw(
    JSON::XS
    ModelSEED::Store
    ModelSEED::Auth::Factory
    ModelSEED::Reference
    ModelSEED::Configuration
    ModelSEED::App::Helpers
    ModelSEED::MS::Factories::ExchangeFormatFactory
    ModelSEED::MS::FBAFormulation
    ModelSEED::Solver::FBA
);
sub abstract { return "Fill gaps in the reaction network for a model"; }
sub usage_desc { return "model runfba [ model || - ] [options]"; }
sub opt_spec {
    return (
        ["config|c:s", "Configuration filename for formulating the FBA"],
        ["overwrite|o", "Save FBA solution in existing model"],
        ["save|s:s", "Save FBA solution in a new model"],
        ["verbose|v", "Print verbose status information"],
        ["fileout|f:s", "Name of file where FBA solution object will be printed"],
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
    my ($model, $ref) = $helper->get_object("model",$args,$store);
    $self->usage_error("Model not found; You must supply a valid model name.") unless(defined($model));
    my $out_fh;
    if ($opts->{fileout}) {
        my $filename = $opts->{fileout};
        open($out_fh, ">", $filename) or die "Cannot open $filename: $!";
    } else {
        $out_fh = \*STDOUT;
    }
    my $fbaform;
    if ($opts->{config}) {
        $fbaform = $helper->object_from_file("FBAFormulation", $opts->{config}, $store);
    } else {
        # Creating FBA formulation
        my $input = { model => $model };
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
            rxnko             => "geneKO",
            geneko            => "reactionKO",
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
    print STDERR "Running FBA..." if($opts->{verbose});
    my $results = $fbaform->runFBA(); 
    if (!defined($results)) {
    	print STDERR " FBA failed with no solution returned!\n";
    } else {
	    push(@{$model->fbaFormulation_uuids()},$fbaform->uuid());
	    # Standard commands that save results of the analysis to the database
	    if ($opts->{overwrite}) {
	    	print STDERR "Saving model with FBA solution over original model...\n" if($opts->{verbose});
	    	$store->save_object("fBAFormulation/".$fbaform->uuid(),$fbaform);
	    	$store->save_object($ref,$model);
	    } elsif ($opts->{save}) {
			$ref = $helper->process_ref_string($opts->{save}, "model", $auth->username);
			print STDERR "Saving model with FBA solution as new model ".$ref."...\n" if($opts->{verbose});
			$store->save_object("fBAFormulation/".$fbaform->uuid(),$fbaform);	
			$store->save_object($ref,$model);
	    }
	    if ($opts->{html}) {
	    	print $out_fh $fbaform->createHTML();
	    } else {
	    	print $out_fh $fbaform->toJSON({pp => 1});
	    }
    }
    close $out_fh if $opts->{fileout};
}

sub _getModel {
    my ($self, $args, $store) = @_;
    my $helper = ModelSEED::App::Helpers->new();
    my $ref = $helper->get_base_ref("model", $args);
    if(defined($ref)) {
        return $store->get_object($ref);
    }
}

1;
