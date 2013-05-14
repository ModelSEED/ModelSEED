########################################################################
# ModelSEED::MS::TemplateBiomassComponent - This is the moose object corresponding to the TemplateBiomassComponent object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2013-04-26T17:03:40
########################################################################
use strict;
use ModelSEED::MS::DB::TemplateBiomassComponent;
package ModelSEED::MS::TemplateBiomassComponent;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::DB::TemplateBiomassComponent';
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
