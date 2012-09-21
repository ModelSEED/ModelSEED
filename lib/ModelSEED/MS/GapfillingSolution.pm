########################################################################
# ModelSEED::MS::GapfillingSolution - This is the moose object corresponding to the GapfillingSolution object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-05-25T05:08:47
########################################################################
use strict;
use ModelSEED::MS::DB::GapfillingSolution;
package ModelSEED::MS::GapfillingSolution;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::DB::GapfillingSolution';
#***********************************************************************************************************
# ADDITIONAL ATTRIBUTES:
#***********************************************************************************************************

#***********************************************************************************************************
# BUILDERS:
#***********************************************************************************************************

#***********************************************************************************************************
# CONSTANTS:
#***********************************************************************************************************

#***********************************************************************************************************
# FUNCTIONS:
#***********************************************************************************************************

=head3 loadFromFile

Definition:
	void ModelSEED::MS::Model->loadFromFile();
Description:
	Loads gapfilling results from file

=cut

sub loadFromFile {
	my ($self,$args) = @_;
	$args = ModelSEED::utilities::ARGS($args,["filename"],{
		model => $self->model()
	});
	if (!-e $args->{filename}) {
		ModelSEED::utilities::ERROR("Could not open gapfilling file ".$args->{filename});
	}
	my $filedata = ModelSEED::utilities::LOADFILE($args->{filename});
	my $model = $args->{model};
	my $count = 0;
	for (my $i=0; $i < @{$filedata}; $i++) {
		if ($filedata->[$i] =~ m/^bio00001/) {
			my $array = [split(/\t/,$filedata->[$i])];
			if (defined($array->[1])) {
				my $subarray = [split(/;/,$array->[1])];
				for (my $j=0; $j < @{$subarray}; $j++) {
					if ($subarray->[$j] =~ m/([\-\+])(rxn\d\d\d\d\d)/) {
						my $rxnid = $2;
						my $sign = $1;
						my $rxn = $model->biochemistry()->queryObject("reactions",{id => $rxnid});
						if (!defined($rxn)) {
							ModelSEED::utilities::ERROR("Could not find gapfilled reaction ".$rxnid."!");
						}
						my $mdlrxn = $model->queryObject("modelreactions",{reaction_uuid => $rxn->uuid()});
						my $direction = ">";
						if ($sign eq "-") {
							$direction = "<";
						}
						if ($rxn->direction() ne $direction) {
							$direction = "=";
						}
						if (defined($mdlrxn)) { 
							$mdlrxn->direction("=");
						} else {
							$mdlrxn = $model->addReactionToModel({
								reaction => $rxn,
								direction => $direction
							});
						}
						$count++;
						$self->add("gapfillingSolutionReactions",{
							modelreaction_uuid => $mdlrxn->uuid(),
							modelreaction => $mdlrxn,
							direction => $direction
						});	
					} elsif ($subarray->[$j] =~ m/([\+])(cpd\d\d\d\d\d)DrnRxn/) {
						my $cpdid = $2;
						my $sign = $1;
						my $bio = $model->biomasses()->[0];
						my $biocpds = $bio->biomasscompounds();
						my $found = 0;
						for (my $i=0; $i < @{$biocpds}; $i++) {
							my $biocpd = $biocpds->[$i];
							if ($biocpd->modelcompound()->compound()->id() eq $cpdid) {
								$bio->remove("biomasscompounds",$biocpd);
								$found = 1;
								push(@{$self->biomassRemovals()},$biocpd->modelcompound());
								push(@{$self->biomassRemoval_uuids()},$biocpd->modelcompound()->uuid());	
							}
						}
						if ($found == 0) {
							ModelSEED::utilities::ERROR("Could not find compound to remove from biomass ".$cpdid."!");
						}
					}
				}
			}
			
		}
	}
	$self->solutionCost($count);
}


__PACKAGE__->meta->make_immutable;
1;
