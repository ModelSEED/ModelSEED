########################################################################
# ModelSEED::MS::ReactionSet - This is the moose object corresponding to the ReactionSet object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-03-26T23:22:35
########################################################################
use strict;
use ModelSEED::MS::DB::ReactionSet;
package ModelSEED::MS::ReactionSet;
use Moose;
use ModelSEED::utilities;
use namespace::autoclean;
extends 'ModelSEED::MS::DB::ReactionSet';
#***********************************************************************************************************
# ADDITIONAL ATTRIBUTES:
#***********************************************************************************************************
has reactionCodeList => ( is => 'rw', isa => 'Str',printOrder => '1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildreactionCodeList' );

#***********************************************************************************************************
# BUILDERS:
#***********************************************************************************************************
sub _buildreactionCodeList {
	my ($self) = @_;
	my $string = "";
	my $rxns = $self->reactions();
	for (my $i=0; $i < @{$rxns}; $i++) {
		if (length($string) > 0) {
			$string .= ";"	
		}
		my $rxn = $rxns->[$i];
		$string .= $rxn->uuid();
	}
	return $string;
}


#***********************************************************************************************************
# CONSTANTS:
#***********************************************************************************************************

#***********************************************************************************************************
# FUNCTIONS:
#***********************************************************************************************************

=head3 modelCoverage
Definition:
	fraction = ModelSEED::MS::ReactionSet->modelCoverage({
		model => ModelSEED::MS::Model(REQ)
	});
Description:
	Calculates the fraction of the reaction set covered by the model

=cut

sub modelCoverage {
    my $self = shift;
    my $args = ModelSEED::utilities::args(["model"],{}, @_);
	#TODO Implement modelCoverage function in ReactionSet
	return 1;
}

=head3 containsReaction
Definition:
	fraction = ModelSEED::MS::ReactionSet->containsReaction({
		model => ModelSEED::MS::Model(REQ)
	});
Description:
	Returns "1" if the reaction set contains the specified reaction

=cut

sub containsReaction {
    my $self = shift;
	my $args = ModelSEED::utilities::args(["reaction"], {}, @_);
	#TODO Implement containsReaction function in ReactionSet
	return 1;
}

__PACKAGE__->meta->make_immutable;
1;
