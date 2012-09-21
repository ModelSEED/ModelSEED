########################################################################
# ModelSEED::MS::GapgenSolution - This is the moose object corresponding to the GapgenSolution object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-08-07T07:31:48
########################################################################
use strict;
use ModelSEED::MS::DB::GapgenSolution;
package ModelSEED::MS::GapgenSolution;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::DB::GapgenSolution';
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

=head3 loadFromData

Definition:
	void ModelSEED::MS::Model->loadFromData();
Description:
	Loads gapgen results from file

=cut

sub loadFromData {
	my ($self,$args) = @_;
	$args = ModelSEED::utilities::ARGS($args,["objective","reactions"],{
		model => $self->model()
	});
	my $model = $args->{model};
	$self->solutionCost($args->{objective});
	for (my $m=0; $m < @{$args->{reactions}}; $m++) {
		if ($args->{reactions}->[$m] =~ m/([\-\+])(rxn\d\d\d\d\d)/) {
			my $rxnid = $2;
			my $sign = $1;
			my $rxn = $model->biochemistry()->queryObject("reactions",{id => $rxnid});
			if (!defined($rxn)) {
				ModelSEED::utilities::ERROR("Could not find gapgen reaction ".$rxnid."!");
			}
			my $mdlrxn = $model->queryObject("modelreactions",{reaction_uuid => $rxn->uuid()});
			my $direction = ">";
			if ($sign eq "-") {
				$direction = "<";
			}
			$self->add("gapgenSolutionReactions",{
				modelreaction_uuid => $mdlrxn->uuid(),
				modelreaction => $mdlrxn,
				direction => $direction
			});
			if ($mdlrxn->direction() eq $direction) {
				$model->remove("modelreactions",$mdlrxn);
			} elsif ($direction eq ">") {
				$mdlrxn->direction("<");
			} elsif ($direction eq "<") {
				$mdlrxn->direction(">");
			}
		}
	}
}

__PACKAGE__->meta->make_immutable;
1;
