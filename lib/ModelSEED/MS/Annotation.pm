########################################################################
# ModelSEED::MS::Annotation - This is the moose object corresponding to the Annotation object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-03-26T23:22:35
########################################################################
use strict;
use ModelSEED::MS::DB::Annotation;
package ModelSEED::MS::Annotation;

=head1 ModelSEED::MS::Annotation

This object is a provenance object that encapsulates the
genome annotations used to construct a metabolic model.

=head2 METHODS

=head3 roles

    \@ = $anno->roles;

Return an arrayref of L<ModelSEED::MS::Role> objects
that are part of the annotation object. Each genome in
an annotation object has features that may be annotated with
one or more functional roles. This list is the non-redundant 
set of those roles.

=head3 subsystems

Return an arrayref of L<ModelSEED::MS::RoleSet> objects
that are the set of subsystems contained within the annotation
object.

=head3 featuresInRoleSet

    \@ = $anno->featuresInRoleSet($roleSet);

Return an arrayref of L<ModelSEED::MS::Feature> objects that are
the set of features that are annotated with roles in the
L<ModelSEED::MS::RoleSet> provided as an argument.  Note that since
"Subsystems" are implemented as RoleSets, this will return the
features in a subsystem for this annotation object.

=head3 createStandardFBAModel

	$model = $anno->createStandardFBAModel(\%config);

Construct a standard FBA Model from the annotation object. Config
is a hash-ref that currently supports the following parameters:

=over 4

=item prefix

A prefix to append to the annotation's ID for the model name

=item mapping

A L<ModelSEED::MS::Mapping> object to use in place of the default one
contained within the annotation object.

=back

=head3 classifyGenomeFromAnnotation

    $string = $anno->classifyGenomeFromAnnotation

Return a string that defines what "kind" of annotation this is.
TODO: This is not implemented yet and only returns "Gram negative"

=cut

use ModelSEED::MS::Model;
use ModelSEED::utilities qw( args );
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::DB::Annotation';
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

sub roles {
    my ($self) = @_;
    my $roles = {};
    my $features = $self->features;
    foreach my $feature (@$features) {
        map { $roles->{$_->role->name} =  $_->role } @{$feature->featureroles};
    }
    return [values %$roles];
}

sub subsystems {
    my ($self) = @_;
    my $subsystems = [];
    my $roles = $self->roles;
    foreach my $role (@$roles) {
        my $results = $role->sets_with_role({type => "SEED Subsystem"});
        push(@$subsystems, @$results);
    }
    return $subsystems;
}

sub featuresInRoleSet {
    my ($self, $roleSet) = @_;
    my $roleHash = {};
    my $results = [];
    foreach my $roleSetRoleUUID (@{$roleSet->role_uuids()}) {
        $roleHash->{$roleSetRoleUUID} = 1;
    }
    my $features = $self->features;
    foreach my $feature (@$features) {
        my $featureRoles = $feature->featureroles;
        foreach my $featureRole (@$featureRoles) {
            if(defined($roleHash->{$featureRole->role_uuid})) {
                push(@$results, $feature);
                last;
            }
        }
    }
    return $results;
}

sub createStandardFBAModel {
    my $self = shift;
	my $args = args([],{
		prefix => "Seed",
		mapping => $self->mapping(),
        verbose => 0,
	}, @_);
	my $mapping = $args->{mapping};
	my $biochem = $mapping->biochemistry();
	my $type = "Singlegenome";
	if (@{$self->genomes()} > 1) {
		$type = "Metagenome";
	}
	my $mdl = ModelSEED::MS::Model->new({
		id => $args->{prefix}.$self->genomes()->[0]->id(),
		version => 0,
		type => $type,
		name => $self->name(),
		growth => 0,
		status => "Reconstruction started",
		current => 1,
		mapping_uuid => $mapping->uuid(),
		mapping => $mapping,
		biochemistry_uuid => $biochem->uuid(),
		biochemistry => $biochem,
		annotation_uuid => $self->uuid(),
		annotation => $self
	});
	$mdl->buildModelFromAnnotation($args);
	return $mdl;
}

sub classifyGenomeFromAnnotation {
    my $self = shift;
	return "Gram negative";
}

__PACKAGE__->meta->make_immutable;
1;
