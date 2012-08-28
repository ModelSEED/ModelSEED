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
        ["config|c=s", "Configuration filename for formulating the gapgeneration"],
        ["fbaconfig|c=s", "Configuration filename for the FBA formulation used by the gapgeneration"],
        ["overwrite|o", "Overwrite existing model with gapgen model"],
        ["save|s:s", "Save gapfilled model to new model name"],
        ["verbose|v", "Print verbose status information"],
        ["fileout|f:s", "Name of file where FBA solution object will be printed"],
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
    my $out_fh;
	if ($opts->{fileout}) {
	    open($out_fh, ">", $opts->{fileout}) or die "Cannot open ".$opts->{fileout}.": $!";
	} else {
	    $out_fh = \*STDOUT;
	}
	#Creating gapfilling formulation
	my $input = {model => $model};
	if ($opts->{config}) {
		$input->{filename} = $opts->{config};
	}
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
    #Running gapfilling
    print STDERR "Running Gapgen...\n" if($opts->{verbose});
    my $result = $model->gapgenModel({
        gapgenFormulation => $gapgenFormulation,
    });
    if (!defined($result)) {
    	print STDERR " Could not find knockouts to meet gapgen specifications!\n";
    } else {
		print $out_fh $result->toJSON({pp => 1});
	    #Standard commands that save results of the analysis to the database
	    if ($opts->{overwrite}) {
	    	print STDERR "Saving gapgen model over original model...\n" if($opts->{verbose});
	    	$store->save_object($ref,$model);
	    } elsif ($opts->{save}) {
			$ref = $helper->process_ref_string($opts->{save}, "model", $auth->username);
			print STDERR "Saving gapgen model as new model ".$ref."...\n" if($opts->{verbose});
			$store->save_object($ref,$model);
	    }
    }
}

1;
