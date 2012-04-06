package ModelSEED::Database;

use Moose::Role;

=head has_object
(exists) = $db->has_object(id);
=cut
requires 'has_object';

=head get_object
(object) = $db->get_object(id);
=cut
requires 'get_object';

=head save_object
(success) = $db->save_object(id, object);
=cut
requires 'save_object';

=head delete_object
(success) = $db->delete_object(id);
=cut
requires 'delete_object';

=head get_metadata
(metadata) = $db->get_metadata(id, subset);

subset can be specified to limit the fields returned by the query
and uses dot notation to select inside sub-objects

ex:
    $db->get_metadata('0123', {name => 1, 'users.paul' => 1});
    would return: {name => 'foo', users => {paul => 'bar'}}
=cut
requires 'get_metadata';

=head set_metadata
(success) = $db->set_metadata(id, data, selection);

data is the metadata you want to set for the object,
and selection specifies where to save the data (uses dot notation)
if selection is undef or the empty string, will set the whole metadata to data
(in this case data has to be a hash)

ex:
    $db->set_metadata('0123', {paul => 'bar'}, 'users');
    or
    $db->set_metadata('0123', 'bar', 'users.paul');

    difference here is that the first will replace 'users',
    while the second adds the user named 'paul'
=cut
requires 'set_metadata';

=head remove_metadata
(success) = $db->remove_metadata(id, selection);

deletes the data at selection (uses dot notation)

ex:
    $db->remove_metadata('0123', 'users.paul');

=cut
requires 'remove_metadata';

=head find_objects
([ids]) = $db->find_objects(query);

allows you to query for objects based on the metadata
will use query syntax similar to mongodb
=cut
requires 'find_objects';

1;
