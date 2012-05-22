########################################################################
# ModelSEED::MS::DB::Experiment - This is the moose object corresponding to the Experiment object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
########################################################################
use strict;
use ModelSEED::MS::IndexedObject;
package ModelSEED::MS::DB::Experiment;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::IndexedObject';


# PARENT:
has parent => (is => 'rw', isa => 'ModelSEED::Store', type => 'parent', metaclass => 'Typed');


# ATTRIBUTES:
has uuid => ( is => 'rw', isa => 'ModelSEED::uuid', type => 'attribute', metaclass => 'Typed', lazy => 1, builder => '_builduuid' );
has genome_uuid => ( is => 'rw', isa => 'ModelSEED::uuid', type => 'attribute', metaclass => 'Typed' );
has name => ( is => 'rw', isa => 'Str', type => 'attribute', metaclass => 'Typed' );
has description => ( is => 'rw', isa => 'Str', type => 'attribute', metaclass => 'Typed' );
has institution => ( is => 'rw', isa => 'Str', type => 'attribute', metaclass => 'Typed' );
has source => ( is => 'rw', isa => 'Str', type => 'attribute', metaclass => 'Typed' );


# ANCESTOR:
has ancestor_uuid => (is => 'rw',isa => 'uuid', type => 'acestor', metaclass => 'Typed');


# LINKS:
has genome => (is => 'rw',lazy => 1,builder => '_buildgenome',isa => 'ModelSEED::MS::Genome', type => 'link(ModelSEED::Store,Genome,uuid,genome_uuid)', metaclass => 'Typed',weak_ref => 1);


# BUILDERS:
sub _builduuid { return Data::UUID->new()->create_str(); }
sub _buildgenome {
	my ($self) = @_;
	return $self->getLinkedObject('ModelSEED::Store','Genome','uuid',$self->genome_uuid());
}


# CONSTANTS:
sub _type { return 'Experiment'; }

my $attributes = ['uuid', 'genome_uuid', 'name', 'description', 'institution', 'source'];
sub _attributes {
	return $attributes;
}

my $subobjects = [];
sub _subobjects {
	return $subobjects;
}


__PACKAGE__->meta->make_immutable;
1;
