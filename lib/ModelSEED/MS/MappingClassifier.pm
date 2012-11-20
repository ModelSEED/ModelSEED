########################################################################
# ModelSEED::MS::MappingClassifier - This is the moose object corresponding to the MappingClassifier object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-11-15T18:17:11
########################################################################
use strict;
use ModelSEED::MS::DB::MappingClassifier;
package ModelSEED::MS::MappingClassifier;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::DB::MappingClassifier';
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
