########################################################################
# ModelSEED::MS::ProvenanceObject - Inherited class for Provenance Objects (Biochemistry, Model, etc...)
# Author: Christopher Henry, Scott Devoid, and Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 3/11/2012
########################################################################

=head1 ModelSEED::MS::ProvenanceObject

=head2 METHODS

=head3 addProvenanceLink

Create a link to another provenance object.

Turns UUID subobject links into array index links.

=head3 removeProvenanceLink

Remove a link to another provenance object.

Turns index subobject links into UUID links.

=head3 createSubobjectAliasLinks

Turn subobject UUID links within self into alias links.

=head3 removeSubobjectAliasLinks

Turn subobject alias links within self into UUID links.

=head3 createSubobjectUUIDHash

Loop through all subobjects and create hash from UUID to array index (alias).

=head3 createSubobjectAliasHash

Loop through all subobjects and create hash from array index (alias) to UUID.

=cut

# NOTE: This is old, most of the code in here will probably be removed

package ModelSEED::MS::ProvenanceObject;

use Moose;
use namespace::autoclean;
use ModelSEED::MS::IndexedObject;

extends 'ModelSEED::MS::IndexedObject';

sub createSubobjectAliasLinks {
    my ($self) = @_;

    # implement this in update
#    if ($self->link_type eq 'alias') {
#        return; # already linking by alias
#    }

    my $uuid_hash = $self->createSubobjectUUIDHash();

    # recurse through object tree, looking for links with parent '$self->_type'
    my $type = $self->_type();
    $self->foreachSubobject(sub {
        my ($obj) = @_;

        foreach my $link (@{$obj->_links()}) {
            if ($link->{parent} eq $type) {
                # need to change link from uuid to alias
                my $link_attr = $link->{attribute};
                my $link_uuid = $obj->$link_attr();

                if (defined($link_uuid)) {
                    my $ind = $uuid_hash->{$link->{method}}->{$link_uuid};
                    my $alias = "foo/bar/$ind";
                    $obj->$link_attr($alias);
                }
            }
        }
    });
}

sub removeSubobjectAliasLinks {
    my ($self) = @_;

    if ($self->link_type eq 'uuid') {
        return; # already linking by uuid
    }

    my $alias_hash = $self->createSubobjectAliasHash();
}

sub createSubobjectUUIDHash {
    my ($self) = @_;

    my $hash = {};
    foreach my $sub_type (@{$self->_subobjects()}) {
        my $sub_name = $sub_type->{name};
        $hash->{$sub_name} = {};

        my $subs = $self->$sub_name();
        for (my $i=0; $i<scalar @$subs; $i++) {
            my $sub = $subs->[$i];
            if (defined($sub)) {
                $hash->{$sub_name}->{$sub->{uuid}} = $i;
            }
        }
    }

    return $hash;
}

sub createSubobjectAliasHash {
    my ($self) = @_;

    my $hash = {};
    foreach my $sub_type (@{$self->_subobjects()}) {
        my $sub_name = $sub_type->{name};
        $hash->{$sub_name} = {};

        my $subs = $self->$sub_name();
        for (my $i=0; $i<scalar @$subs; $i++) {
            my $sub = $subs->[$i];
            if (defined($sub)) {
                $hash->{$sub_name}->{$i} = $sub->{uuid};
            }
        }
    }

    return $hash;
}

1;
