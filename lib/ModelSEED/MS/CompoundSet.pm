########################################################################
# ModelSEED::MS::CompoundSet - This is the moose object corresponding to the CompoundSet object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-03-26T23:22:35
########################################################################
use strict;
use ModelSEED::MS::DB::CompoundSet;
package ModelSEED::MS::CompoundSet;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::DB::CompoundSet';
#***********************************************************************************************************
# ADDITIONAL ATTRIBUTES:
#***********************************************************************************************************
has compoundListString => ( is => 'rw', isa => 'Str',printOrder => '1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildcompoundListString' );

#***********************************************************************************************************
# BUILDERS:
#***********************************************************************************************************
sub _buildcompoundListString {
	my ($self) = @_;
	my $compoundListString = "";
	my $cpds = $self->compounds();
	for (my $i=0; $i < @{$cpds}; $i++) {
		if (length($compoundListString) > 0) {
			$compoundListString .= ";"	
		}
		my $cpd = $cpds->[$i];
		$compoundListString .= $cpd->compound()->name();
	}
	return $compoundListString;
}


#***********************************************************************************************************
# CONSTANTS:
#***********************************************************************************************************

#***********************************************************************************************************
# FUNCTIONS:
#***********************************************************************************************************


__PACKAGE__->meta->make_immutable;
1;
