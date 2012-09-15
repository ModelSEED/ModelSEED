########################################################################
# ModelSEED::MS::BiochemistryStructures - This is the moose object corresponding to the BiochemistryStructures object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-09-11T20:47:01
########################################################################
use strict;
use ModelSEED::MS::DB::BiochemistryStructures;
package ModelSEED::MS::BiochemistryStructures;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::DB::BiochemistryStructures';
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
