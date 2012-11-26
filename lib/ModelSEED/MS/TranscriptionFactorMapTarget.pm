########################################################################
# ModelSEED::MS::TranscriptionFactorMapTarget - This is the moose object corresponding to the TranscriptionFactorMapTarget object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-11-26T20:33:53
########################################################################
use strict;
use ModelSEED::MS::DB::TranscriptionFactorMapTarget;
package ModelSEED::MS::TranscriptionFactorMapTarget;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::DB::TranscriptionFactorMapTarget';
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


__PACKAGE__->meta->make_immutable;
1;
