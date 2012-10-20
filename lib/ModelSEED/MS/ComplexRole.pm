########################################################################
# ModelSEED::MS::ComplexRole - This is the moose object corresponding to the ComplexRole object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-03-26T23:22:35
########################################################################
use strict;
use ModelSEED::MS::DB::ComplexRole;
package ModelSEED::MS::ComplexRole;
use ModelSEED::MS::ModelReactionProteinSubunit;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::DB::ComplexRole';

=head1 ModelSEED::MS::ComplexRole

=head2 METHODS

=head3 createProteinSubunit

    $cpxrole->createProteinSubunit({
        features => $f, note => $n
    });

Create L<ModelSEED::MS::ModelReactionProteinSubunit> object where
features is an array reference of Features, and note is
a string. Both features and note are optional.

=cut

sub createProteinSubunit {
    my ($self, $args) = @_;
    $args = ModelSEED::utilities::ARGS(
        $args, [], { features => [], note => undef}
    );
    my $feature_uuids = [ map { $_->uuid } @{$args->{features}} ];
    my $hash = {
        optional   => $self->optional,
        triggering => $self->triggering,
        role_uuid  => $self->role_uuid,
        modelReactionProteinSubunitGenes => 
    };
    $hash->{note} = $args->{note} if defined $args->{note};
    return ModelSEED::MS::ModelReactionProteinSubunit->new($hash);

}


__PACKAGE__->meta->make_immutable;
1;
