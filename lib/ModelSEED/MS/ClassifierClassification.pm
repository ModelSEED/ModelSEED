########################################################################
# ModelSEED::MS::ClassifierClassification - This is the moose object corresponding to the ClassifierClassification object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-11-15T18:17:11
########################################################################
use strict;
use ModelSEED::MS::DB::ClassifierClassification;
package ModelSEED::MS::ClassifierClassification;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::DB::ClassifierClassification';
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
