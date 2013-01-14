########################################################################
# ModelSEED::MS::TranscriptionFactorMap - This is the moose object corresponding to the TranscriptionFactorMap object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-11-26T20:33:53
########################################################################
use strict;
use ModelSEED::MS::DB::TranscriptionFactorMap;
package ModelSEED::MS::TranscriptionFactorMap;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::DB::TranscriptionFactorMap';
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
