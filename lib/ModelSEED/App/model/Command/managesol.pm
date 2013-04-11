package ModelSEED::App::model::Command::managesol;
use strict;
use common::sense;
use ModelSEED::App::model;
use base 'ModelSEED::App::ModelBaseCommand';
use ModelSEED::utilities qw( config error args verbose set_verbose translateArrayOptions);
use Class::Autouse qw(
    ModelSEED::MS::Factories::ExchangeFormatFactory
);
sub abstract { return "Lists all gapfilling and gapgeneration solutions for model, and integrates a selected solution" }
sub usage_desc { return "model managesol [model] [options]" }
sub options {
    return (
        ["gapfillonly|f","Only show gapfilling solutions"],
        ["gapfgenonly|g","Only show gapgeneration solutions"],
        ["solution|s=s", "Solution to be integrated"],
        ["deletesol|e=s", "Formulation or solution to be deleted"],
        ["cleargapgen", "Clear all unintegrated gapgen formulations"],
        ["cleargapfill", "Clear all unintegrated gapfilling formulations"],
        ["saveas|a:s", "New name the model should be saved to"],
    );
}
sub sub_execute {
    my ($self, $opts, $args,$model) = @_;
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
    $self->save_model($model);
}

1;
