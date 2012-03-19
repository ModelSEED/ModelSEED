########################################################################
# ModelSEED::MS::DB::CompoundStructure - This is the moose object corresponding to the CompoundStructure object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-03-19T19:49:19
########################################################################
use strict;
use Moose;
use namespace::autoclean;
use ModelSEED::MS::BaseObject;
use ModelSEED::MS::Compound;
package ModelSEED::MS::DB::CompoundStructure;
extends ModelSEED::MS::BaseObject;


# PARENT:
#has parent => (is => 'rw',isa => 'ModelSEED::MS::Compound',weak_ref => 1);


# ATTRIBUTES:
has compound_uuid => ( is => 'rw', isa => 'uuid', type => 'attribute', metaclass => 'Typed', required => 1 );
has structure => ( is => 'rw', isa => 'Str', type => 'attribute', metaclass => 'Typed', required => 1 );
has cksum => ( is => 'rw', isa => 'varchar', type => 'attribute', metaclass => 'Typed', default => '' );
has type => ( is => 'rw', isa => 'Str', type => 'attribute', metaclass => 'Typed', required => 1 );




# BUILDERS:


# CONSTANTS:
sub _type { return 'CompoundStructure'; }


__PACKAGE__->meta->make_immutable;
1;
