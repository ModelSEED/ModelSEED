########################################################################
# ModelSEED::Database - Abstract role / interface for Database drivers
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development locations:
#   Mathematics and Computer Science Division, Argonne National Lab;
#   Computation Institute, University of Chicago
#
# Date of module creation: 2012-04-01
########################################################################
=pod

=head1 ModelSEED::Database

An abstract role / interface for database drivers.

=head2 Methods

=head3 has_data

    $bool = $db->has_data(ref, auth);

=head3 get_data

    $obj = $db->get_data(ref, auth);

=head3 get_data_collection

    $collection = $db->get_data_collection(ref, auth);

=head3 get_data_collection_iterator

    $iterator = $db->get_data_collection_itorator(ref, auth);

=head3 save_data

    $ref = $db->save_data(ref, data, auth, config);

Where config is a hash that currently accepts one parameter:

=over 4

=item is_merge

This is a boolean value that, if true, results in the save operation
not overwriting the ancestor_uuids field in the object. If it is
false or not present, the ancestor_uuids field will be overwritten
with the current object's uuid if that object already exists in the
data store.

=back

=head3 save_data_collection

    $bool = save_data_collection(ref, collection, auth);

=head3 delete_data

    $count = $db->delete_object(ref, auth);

=head3 delete_collection

    $count = $db->delete_object(ref, auth);

=head3 find_objects

    ([ids]) = $db->find_objects(ref, query, auth);

Allows you to query for objects based on the metadata will use query
syntax similar to MongoDB.

Uses MongoDB syntax like here:
L<http://search.cpan.org/~kristina/MongoDB/lib/MongoDB/Tutorial.pod#Queries>
L<http://www.mongodb.org/display/DOCS/Advanced+Queries>

=head2 Alias Functions

These functions manage aliases, which are special pointers to
objects. These pointers have viewing permissions and can only be
moved to a different object by their owner. Alias strings have the
form of "username/arbitraryString" and are used in place of uuids
in some specific objects (biochemistry, mapping and model for now).
So a reference to a biochemistry would look like
C<biochemistry/chenry/main>.

In these functions:

=over 4

=item C<ref> is a L<ModelSEED::Reference>

=item C<auth> is a L<ModelSEED::Auth>

=item C<arbitraryString> is the free-form portion of the alias

=item C<viewerUsername> is a username

=back

=head3 get_aliases

    $arrayRef = $db->get_aliases(query, auth)

Query for aliases. The query object is a HashRef that may contain
the following keys: type, owner, alias, uuid.  The return value is
an array ref of alias objects that have the following structure:

    {
        type  => $string,
        owner => $string,
        alias => $string,
        uuid  => $uuid,
    }

=head3 update_alias

    $bool = $db->update_alias(ref, uuid, auth)

=head3 add_viewer

    $bool = $db->add_viewer(ref, viewerUsername, auth)

=head3 remove_viewer

    $bool = $db->remove_viewer(ref, viewerUsername, auth)

=head3 set_public

    $bool = $db->set_public(ref, boolean, auth)

=head2 Ancestor and Decendant Functions

These functions provide access to the ancestor and decnendant
information on provenance objects. Each object stores a reference
to its direct parents through the C<{ ancestor_uuids }> array.
However, to access ancestors further back, one must walk through
the database at least once. These functions do so in a reasonably
efficient manner.

=head3 ancestors

    \@ = $db->ancestors(ref, auth)

Return an array-ref of ancestor uuids that are the complete list
of ancestors (parents, grandparents, etc.) for a reference.

=head3 ancestor_graph 

    \% = $db->ancestor_graph(ref, auth)

Return a hash-ref of uuid to array-ref of parent uuids for each
object that is an ancestor of the current object. This hash includes
the current object uuid as a key. So for an object with no parents,
and therefore no further ancestors, the graph would be:

    { $uuid => [] }

And for an object with a parent C<$uuid2>:

    { $uuid => [ $uuid2 ], $uuid2 => [] }

=head3 descendants

    \@ = $db->descendants(ref, auth)

Return an array-ref of descendant object uuids.

=head3 descendant_graph

    \% = $db->descendant_graph(ref, auth)

Return a hash-ref of uuid to array-ref of parent uuids for each
object that is a descendant of the current object. This hash includes
the current object uuid as a key.

=cut
package ModelSEED::Database;
use Moose::Role;
# Data access functions
requires 'has_data';
requires 'get_data';
requires 'save_data';
#requires 'delete_data';
requires 'find_data';
# Alias functions
requires 'get_aliases';
requires 'update_alias';
requires 'alias_viewers';
requires 'alias_owner';
requires 'alias_public';
requires 'add_viewer';
requires 'remove_viewer';
requires 'set_public';

1;
