########################################################################
# ModelSEED::MS::Genome - This is the moose object corresponding to the Genome object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-03-26T23:22:35
########################################################################

=head1 ModelSEED::MS::Genome

Genome object, contained within an annotation set.

=head2 METHODS

=head3 features

    \@features = $self->features;

Return an ArrayRef of L<ModelSEED::MS::Feature> objects
that are associated with this genome.

=head3 compartments

    \@cmps = $self->compartments;

Return an ArrayRef of strings that are the compartment ids
associated with the features of this genome.

=head3 featuresByRole

    \%ftr_by_role = $self->featuresByRole;

Returns a HashRef where the value is a role UUID and the
value is an ArrayRef of L<ModelSEED::MS::Feature> objects
that are annotated with that role.

=cut

use strict;
use ModelSEED::MS::DB::Genome;
package ModelSEED::MS::Genome;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::DB::Genome';

sub features {
    my $self = shift;
    my $anno_features = $self->parent->features;
    my $uuid = $self->uuid;
    return [ grep { $_->genome_uuid eq $uuid } @$anno_features ];
}

sub compartments {
    my $self = shift;
    my $anno_features = $self->features;
    my $cmps = {};
    foreach my $feature (@$anno_features) {
        my $ftr_roles = $feature->featureroles;
        foreach my $ftr_role (@$ftr_roles) {
            $cmps->{ $ftr_role->compartment } = 1;
        }
    }
    return [ keys %$cmps ];
}

sub featuresByRole {
    my $self = shift;
    return $self->parent->featuresByRole(
        features => $self->features
    );
}


__PACKAGE__->meta->make_immutable;
1;
