package ModelSEED::App::model::Command::managesol;
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
use ModelSEED::utilities qw( set_verbose verbose );
sub abstract { return "Lists all gapfilling and gapgeneration solutions for model, and integrates a selected solution"; }
sub usage_desc { return "model managesol [ model || - ] [options]"; }
sub opt_spec {
    return (
        ["verbose|v", "Print verbose status information"],
        ["gapfillonly|f","Only show gapfilling solutions"],
        ["gapfgenonly|g","Only show gapgeneration solutions"],
        ["solution|s=s", "Solution to be integrated"],
        ["deletesol|d=s", "Formulation or solution to be deleted"],
        ["cleargapgen", "Clear all unintegrated gapgen formulations"],
        ["cleargapfill", "Clear all unintegrated gapfilling formulations"],
        ["saveas|a:s", "New name the model should be saved to"],
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
    (my $model,my $ref) = $helper->get_object("model",$args,$store);
    $self->usage_error("Model not found; You must supply a valid model name.") unless(defined($model));
	if ($opts->{verbose}) {
        set_verbose(1);
    	delete $opts->{verbose};
    }
    #Clearing gapgen or gapfilling solutions
    if (defined($opts->{cleargapgen}) && $opts->{cleargapgen} == 1) {
    	$model->clearLinkArray("unintegratedGapgens");
    }
    if (defined($opts->{cleargapfill}) && $opts->{cleargapfill} == 1) {
    	$model->clearLinkArray("unintegratedGapfillings");
    }
    #Deleting specified solution
    if (defined($opts->{deletesol})) {
    	my $type = "gapfillingFormulation";
    	my $subfunc = "gapfillingSolutions";
    	my $func = "unintegratedGapfillings";
    	if ($opts->{deletesol} != m/^GG/) {
    		$type = "gapgenFormulation";
    		$subfunc = "gapgenSolutions";
    		$func = "unintegratedGapgens";
    	}
    	if ($opts->{deletesol} =~ m/^G[GF](\d+)/){
    		my $formNum = $1;
    		my $form = $model->$func()->[$formNum];
    		if ($opts->{deletesol} =~ m/^G[GF]\d+\.(\d+)/){
    			my $solNum = $1;
    			my $formsols = $form->$subfunc();
    			if (@{$formsols} > $solNum) {
    				$form->remove($subfunc,$formsols->[$solNum]);
    				my $olduuid = $form->uuid();
    				my $newuuid = $store->save_object($type."/".$form->uuid(),$form);
					$model->replaceLinkArrayItem($func,$olduuid,$newuuid);
    			} else {
    				print STDERR "Invalid solution selected for deletions!"
    			}
    		} else {
    			$model->removeLinkArrayItem($func,$form);
    		}
    	}
    }
    #Integrating selected solution
    if (defined($opts->{solution})) {
    	if ($opts->{solution} =~ m/^G[GF](\d+)\.(\d+)/){
    		my $formNum = $1;
    		my $solNum = $2;
    		my $type = "gapfillingFormulation";
    		my $intfunc = "integrateGapfillSolution";
	    	my $subfunc = "gapfillingSolutions";
	    	my $func = "unintegratedGapfillings";
	    	if ($opts->{solution} != m/^GG/) {
	    		my $intfunc = "integrateGapgenSolution";
	    		$type = "gapgenFormulation";
	    		$subfunc = "gapgenSolutions";
	    		$func = "unintegratedGapgens";
	    	}
	    	my $form = $model->$func()->[$formNum];
	    	my $formsols = $form->$subfunc();
    		if (@{$formsols} > $solNum) {
    			$model->$intfunc({
    				$type => $form,
    				solutionNum => $solNum
    			});
    		} else {
    			print STDERR "Invalid solution selected for integration!"
    		}
    	} else {
    		print "Selected solution not valid! Select valid solution:\n";
    	}
    }
    #Printing gapgeneration solutions
	if (!defined($opts->{gapfillonly}) || $opts->{gapfillonly} == 0) {
		my $forms = $model->unintegratedGapgens();
		if (@{$forms} == 0) {
			print "*********************************************\n";
			print "No unintegrated gap generation studies!\n";
			print "*********************************************\n";
		} else {
			print "*********************************************\n";
			print @{$forms}." unintegrated gap generation studies!\n";
			for (my $i=0 ;$i < @{$forms}; $i++) {
				print $forms->[$i]->printStudy($i)
			}
		}
	}
	#Printing gapfilling solutions
	if (!defined($opts->{gapfgenonly}) || $opts->{gapfgenonly} == 0) {
		my $forms = $model->unintegratedGapfillings();
		if (@{$forms} == 0) {
			print "*********************************************\n";
			print "No unintegrated gap generation studies!\n";
			print "*********************************************\n";
		} else {
			print "*********************************************\n";
			print @{$forms}." unintegrated gapfilling studies!\n";
			for (my $i=0 ;$i < @{$forms}; $i++) {
				print $forms->[$i]->printStudy($i)
			}
		}
	}
	#Saving results in model
	if ($opts->{saveas}) {
    	$ref = $helper->process_ref_string($opts->{saveas}, "model", $auth->username);
    	verbose("New alias set for model:".$ref);
    }
    if ($opts->{dryrun}) {
    	verbose("Dry run selected. Results not saved!");
    } else {
    	verbose("Saving model!");
       	$store->save_object($ref,$model);
    }
}

1;
