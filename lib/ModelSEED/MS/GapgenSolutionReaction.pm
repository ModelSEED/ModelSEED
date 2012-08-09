########################################################################
# ModelSEED::MS::GapgenSolutionReaction - This is the moose object corresponding to the GapgenSolutionReaction object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-08-07T07:31:48
########################################################################
use strict;
use ModelSEED::MS::DB::GapgenSolutionReaction;
package ModelSEED::MS::GapgenSolutionReaction;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::DB::GapgenSolutionReaction';
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
