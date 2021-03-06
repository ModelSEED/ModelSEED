########################################################################
# ModelSEED::Database::MongoDBSimple - Dumb impl. of MongoDB interface
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development locations:
#   Mathematics and Computer Science Division, Argonne National Lab;
#   Computation Institute, University of Chicago
#
# Date of module creation: 2012-04-01
########################################################################
package ModelSEED::Database::MongoDBSimple;
use Moose;
use common::sense;
use MongoDB;
use JSON::XS;
use Tie::IxHash;
use FileHandle;
use Data::UUID;
use ModelSEED::Reference;

use Data::Dumper; # DEBUG

with 'ModelSEED::Database';

has db_name  => (is => 'ro', isa => 'Str', required => 1);
has host     => (is => 'ro', isa => 'Str');
has username => (is => 'ro', isa => 'Str');
has password => (is => 'ro', isa => 'Str');

# Internal attributes
has conn => (
    is        => 'ro',
    isa       => 'MongoDB::Connection',
    builder   => '_build_conn',
    lazy      => 1,
    init_arg  => undef
);
has db => (
    is        => 'ro',
    isa       => 'MongoDB::Database',
    builder   => '_build_db',
    lazy      => 1,
    init_arg  => undef
);
has JSON => (
    is       => 'ro',
    isa      => 'JSON::XS',
    builder  => '_build_json',
    lazy     => 1,
    init_arg => undef,
);

$ModelSEED::Database::MongoDBSimple::aliasCollection = "aliases";
$ModelSEED::Database::MongoDBSimple::ancestorCollection = "ancestors";

sub init_database {
    my ($self) = @_;
    my $alias_collection = $ModelSEED::Database::MongoDBSimple::aliasCollection;
    my $ancestor_collection = $ModelSEED::Database::MongoDBSimple::ancestorCollection;
    $self->db->$alias_collection->ensure_index({ uuid => 1 });
    $self->db->$alias_collection->ensure_index({ owner => 1 });
    $self->db->$alias_collection->ensure_index({ viewers => 1 });
    $self->db->$alias_collection->ensure_index({ alias => 1 });
    $self->db->$ancestor_collection->ensure_index({ uuid => 1 });
    $self->db->$ancestor_collection->ensure_index({ ancestors => 1 });
    $self->db->$ancestor_collection->ensure_index({ modDate => 1 });
    my $t = Tie::IxHash->new(type => 1, owner => 1, alias => 1);
    $self->db->$alias_collection->ensure_index($t);
    return 1;
}

sub delete_database {
    my ($self, $config) = @_;
    return 1 if(defined $config && $config->{keep_data});
    $self->db->drop();
    return 1;
}

sub has_data {
    my ($self, $ref, $auth) = @_;
    $ref = $self->_cast_ref($ref);
    my $uuid = $self->_get_uuid($ref, $auth);
    return 0 unless(defined($uuid));
    my $fh = $self->db->get_gridfs->files->find_one({ uuid => $uuid });
    return (defined($fh)) ? 1 : 0;
}

sub get_data {
    my ($self, $ref, $auth) = @_;
    $ref = $self->_cast_ref($ref);
    my $uuid = $self->_get_uuid($ref, $auth);
    return unless(defined($uuid));
    my $fh = $self->db->get_gridfs->find_one({ uuid => $uuid });
    return unless(defined($fh));
    my $ob = $self->_gfs_fh_to_object($fh);
    return $ob;
}

sub save_data {
    my ($self, $ref, $object, $auth, $config) = @_;
    $config = {} unless defined $config;
    $ref = $self->_cast_ref($ref);
    my ($oldUUID, $update_alias);
    if ($ref->id_type eq 'alias') {
        $oldUUID = $self->_get_uuid($ref, $auth);    
        # cannot write to alias not owned by callee
        return unless($auth->username eq $ref->alias_username);
    } elsif($ref->id_type eq 'uuid') {
        # cannot save to existing uuid
        if(!$config->{schema_update} && $self->has_data($ref, $auth)) {
             $oldUUID = $ref->id;
        }
    }
    if(!defined($object->{ancestor_uuids})) {
        $object->{ancestor_uuids} = [];
    }
    if(defined($oldUUID)) {
        # We have an existing alias, so must:
        # - insert uuid in ancestors if we're not merging
        unless($config->{is_merge}) {
            $object->{ancestor_uuids} = [ $oldUUID ];
        }
        # - set to new UUID if that hasn't been done
        if($object->{uuid} eq $oldUUID) {
            $object->{uuid} = Data::UUID->new()->create_str();
        }
        # - update alias, but wait until after object write
        if($ref->id_type eq 'alias') {
            $update_alias = 1;
        }
    }
    # Schema Update - mark existing files with "toRemove" flag
    if ($config->{schema_update}) {
        my $uuid = $ref->id;
        $self->db->get_gridfs->files->update({ "uuid" => $uuid }, { '$set' => { "toRemove" => 1 } }, undef, "multi");
    }
    # Now save object to collection
    my $fh = $self->_object_to_fh($object);
    $self->db->get_gridfs->insert($fh, { uuid => $object->{uuid} });
    # Schema Update - remove existing files that were marked with "toRemove" flag
    if ($config->{schema_update}) {
        my $uuid = $ref->id;
        $self->db->get_gridfs->files->remove({ "uuid" => $uuid, "toRemove" => 1 });
    }
    # Update the ancestor and descendant data if we have an old UUID
    if(defined($oldUUID)) {
        $self->_update_ancestors_and_descendants(
            $ref->base_types->[0],        # type
            $object->{ancestor_uuids},    # old_uuids
            $object->{uuid},              # new_uuid
            $auth                         # auth obj
        );
    # Otherwise, construct the basic ancestor object
    } else {
        $self->_construct_ancestor_object($ref, $auth);
    }

    if($update_alias) {
        # update alias to new uuid
        my $rtv = $self->update_alias($ref, $object->{uuid}, $auth);
        return unless($rtv);
    } elsif(!defined($oldUUID) && $ref->id_type eq 'alias') {
        # alias is new, so create it
        my $rtv = $self->update_alias($ref, $object->{uuid}, $auth);
        return unless($rtv);
    }
    return $object->{uuid};
}

sub delete_data {
    my ($self, $ref, $auth) = @_;
    $ref = $self->_cast_ref($ref);
    my $uuid = $self->_get_uuid($ref, $auth);
    return unless(defined($uuid));
    # TODO - do we actually want to delete objects?
    return 1;
}

sub find_data {
    my ($self, $ref, $auth) = @_;
}

## Alias functions

sub get_aliases {
    my ($self, $ref, $auth) = @_;
    my $query = {};
    if(defined($ref) && ref($ref) eq 'HASH') {
        $query = $ref;
    } elsif(defined($ref)) {
        $ref = $self->_cast_ref($ref);
        #$self->_die_if_bad_ref($ref);
        if($ref->type eq 'collection') {
            if(defined $ref->base_types->[0]) {
                $query->{type} = $ref->base_types->[0];
            }
            if($ref->has_owner) {
                $query->{owner} = $ref->owner;
            }
        } else {
            $query->{type} = $ref->base_types->[0];
            if ($ref->id_type eq 'uuid') {
                $query->{uuid} = $ref->id;
            }
            if ($ref->id_type eq 'alias') {
                $query->{alias} = $ref->alias_string;
                $query->{owner} = $ref->alias_username;
            }
        }
    } 
    return $self->_aliases_query($query, $auth);
}

sub alias_uuid {
    my ($self, $ref, $auth) = @_;
    return $self->_alias_query($ref, 'uuid', $auth);
}

sub alias_viewers {
    my ($self, $ref, $auth) = @_;
    return $self->_alias_query($ref, 'viewers', $auth);
}

sub alias_public {
    my ($self, $ref, $auth) = @_;
    return $self->_alias_query($ref, 'public', $auth);
}

sub alias_owner {
    my ($self, $ref, $auth) = @_;
    return $self->_alias_query($ref, 'owner', $auth);
}

sub update_alias {
    my ($self, $ref, $uuid, $auth) = @_;
    my $update = { '$set' => { 'uuid' => $uuid }};
    my $val = $self->_alias_update($ref, $update, $auth);
    if($val == -1) {
        # create alias if it alias doesn't exist
        return $self->_alias_create($ref, $uuid, $auth);
    }
    return $val;
}

sub remove_viewer {
    my ($self, $ref, $viewerName, $auth) = @_;
    my $update = { '$pull' => { 'viewers' => $viewerName }};
    return $self->_alias_update($ref, $update, $auth);
}

sub set_public {
    my ($self, $ref, $bool, $auth) = @_;
    my $update = { '$set' => { 'public' => $bool }};
    return $self->_alias_update($ref, $update, $auth);
}

sub add_viewer {
    my ($self, $ref, $viewerName, $auth) = @_;
    my $update = { '$push' => { 'viewers' => $viewerName }};
    return $self->_alias_update($ref, $update, $auth);
}

## Ancestor & Descendant Functions

sub ancestors {
    my ($self, $ref, $auth, $config) = @_;
    my $o = $self->_get_ancestor_object($ref, $auth);
    return $o->{ancestors} if defined $o;
    # Construct ancestors and return if not defined
    ($o) = $self->_construct_ancestor_object($ref, $auth, $config);
    return $o->{ancestors} if defined $o;
    return undef;
}

sub ancestor_graph {
    my ($self, $ref, $auth, $config) = @_;
    my $o = $self->_get_ancestor_object($ref, $auth);
    return $o->{ancestor_graph} if defined $o;
    ($o) = $self->_construct_ancestor_object($ref, $auth, $config);
    return $o->{ancestor_graph} if defined $o;
    return undef;
}

sub descendants {
    my ($self, $ref, $auth) = @_;
    my $uuid = $self->_get_uuid($ref, $auth);
    return undef unless defined $uuid;
    my $ancestor_collection = $ModelSEED::Database::MongoDBSimple::ancestorCollection;
    my $o = $self->db->$ancestor_collection->find_one({ uuid => $uuid }); 
    return undef unless defined $o;
    return $o->{descendants};
}

sub descendant_graph {
    my ($self, $ref, $auth) = @_;
    my $uuid = $self->_get_uuid($ref, $auth);
    return undef unless defined $uuid;
    my $ancestor_collection = $ModelSEED::Database::MongoDBSimple::ancestorCollection;
    my $o = $self->db->$ancestor_collection->find_one({ uuid => $uuid }); 
    return undef unless defined $o;
    return $o->{descendant_graph} 
}

sub _get_ancestor_object {
    my ($self, $ref, $auth) = @_;
    my $uuid = $self->_get_uuid($ref, $auth);
    return undef unless defined $uuid;
    my $ancestor_collection = $ModelSEED::Database::MongoDBSimple::ancestorCollection;
    my $o = $self->db->$ancestor_collection->find_one({ uuid => $uuid });
    return $o if defined $o;
    return undef;
}

sub _ancestor_graph {
    my ($self, $ref, $auth, $config) = @_;
    my $o = $self->_get_ancestor_object($ref, $auth);
    return ($o, []) if defined $o;
    return $self->_construct_ancestor_object($ref, $auth, $config);
}

sub _update_ancestors_and_descendants {
    my ($self, $type, $old_uuids, $new_uuid, $auth) = @_;
    # Construct the ancestors for the current object
    my $new_ref = ModelSEED::Reference->new(type => $type, uuid => $new_uuid);
    $self->ancestors($new_ref, $auth);
    # Get all of the ancestors for the new uuid object.
    my $ancestors = { map { $_ => 1 } @$old_uuids };
    foreach my $uuid (@$old_uuids) {
        my $ref = ModelSEED::Reference->new( type => $type, uuid => $uuid );
        map { $ancestors->{$_} = 1 } @{$self->ancestors($ref, $auth)};
    }
    # Update the descendant sets for each ancestor to include the current uuid
    my $ancestor_collection = $ModelSEED::Database::MongoDBSimple::ancestorCollection;
    $ancestors = [ keys %$ancestors ];
    $self->db->$ancestor_collection->update(
        { "uuid" => { '$in' => $ancestors } },
        { '$addToSet' => { descendants => $new_uuid } },
    );
    # Update the descendant graph for each ancestor by adding the child
    # uuid to the descendant_graph under the parent uuid
    foreach my $uuid (@$old_uuids) {
        $self->db->$ancestor_collection->update(
            { "uuid" => { '$in' => $ancestors } },
            { '$addToSet' => { "descendant_graph.$uuid" => $new_uuid } },
        );
    }
}

sub _construct_ancestor_object {
    my ($self, $ref, $auth, $config) = @_;
    my $newConfig = $config;
    $newConfig = { doNotSave => 1 } unless defined $newConfig;
    my $uuid = $self->_get_uuid($ref, $auth);
    # Error out if we can't get the ref object
    return undef unless defined $uuid;
    my $current = $self->get_data($ref, $auth);
    # Build the initial object with ancestor tree
    my $parent_uuids = $current->{ancestor_uuids};
    $parent_uuids = [] unless defined $parent_uuids;
    # -- Basis
    my $objectsToSave = [];
    my $ancestors     = [@$parent_uuids];
    my $parentGraphs  = [ { $uuid => $parent_uuids } ];
    # -- Recursion
    foreach my $parent_uuid (@$parent_uuids) {
        my $ref = ModelSEED::Reference->new(
            type => $ref->base_types->[0],
            uuid => $parent_uuid,
        );
        my ($sub, $subs) = $self->_ancestor_graph($ref, $auth, $newConfig);
        # subs will be undefined if current parent already in database
        $subs = [] unless defined $subs;
        push(@$parentGraphs, $sub->{ancestor_graph});
        push(@$ancestors, @{$sub->{ancestors}});
        push(@$objectsToSave, @$subs);
    }
    # -- Merge
    # remove duplicate ancestors in list
    $ancestors = [ keys %{{ map { $_ => 1 } @$ancestors }} ];
    # merge graph hashes
    my $graph = {};
    $graph = _merge_hash($graph, $_) for @$parentGraphs;
    my $o = {
        uuid => $uuid,
        modDate => $current->{modDate},
        ancestors => $ancestors,
        ancestor_graph => $graph,
        descendants => [],
        descendant_graph => {},
    };
    if (!defined($config) || !$config->{doNotSave}) {
        push(@$objectsToSave, $o);
        my $ancestor_collection = $ModelSEED::Database::MongoDBSimple::ancestorCollection;
        $self->db->$ancestor_collection->batch_insert($objectsToSave);
    }
    return ($o, $objectsToSave);
}

## Helper Functions

sub _alias_create {
    my ($self, $ref, $uuid, $auth) = @_;
    $ref = $self->_cast_ref($ref);
    my $type = $ref->parent_collections->[0];
    my $validAliasTypes = {
        biochemistry => 1,
        model => 1,
        mapping => 1,
        annotation => 1,
    };
    return 0 unless(defined($validAliasTypes->{$type}));
    return 0 unless($ref->id_type eq 'alias');
    return 0 unless($ref->alias_username eq $auth->username);
    my $obj = {
        type => $type,
        alias => $ref->alias_string,
        owner => $auth->username,
        public => 0,
        uuid => $uuid,
        viewers => [],
    };
    my $query = {
        type => $type,
        alias => $ref->alias_string,
        owner => $auth->username,
    };
    my $aliasCollection = $ModelSEED::Database::MongoDBSimple::aliasCollection;
    $self->db->$aliasCollection->update($query, $obj, {upsert => 1});
    # this is 'upsert', which inserts one document if nothing matches
    return 0 if $self->_update_error(1);
    return 1;
}

sub _alias_update {
    my ($self, $ref, $update, $auth) = @_;
    $ref = $self->_cast_ref($ref);
    # can only update ref that is an alias
    return 0 unless($ref->id_type eq 'alias');
    # can only update ref that is owned by caller
    return 0 unless($ref->alias_username eq $auth->username);
    my $aliasCollection = $ModelSEED::Database::MongoDBSimple::aliasCollection;
    my $o = $self->db->$aliasCollection->update(
        {   alias => $ref->alias_string,
            type  => $ref->alias_type,
            owner => $auth->username,
        },
        # push viewer on viewers
        $update,
        {safe => 0}
    );
    return -1 if $self->_update_error(1);
    return 1;
}

sub _aliases_query {
    my ($self, $query, $auth) = @_;
    my $permission_query = {
        '$and' => [
            $query,
            {   '$or' => [
                    {'owner'   => $auth->username},
                    {'viewers' => $auth->username},
                    {'public'  => 1}
                ]
            }
        ]
    };
    my $aliasCollection = $ModelSEED::Database::MongoDBSimple::aliasCollection;
    my @objs = $self->db->$aliasCollection->find($permission_query)->all;
    return [
        map {
            {   type  => $_->{type},
                owner => $_->{owner},
                alias => $_->{alias},
                uuid  => $_->{uuid}
            }
            } @objs

    ];
}

sub _alias_query {
    my ($self, $ref, $attribute, $auth) = @_;
    $ref = $self->_cast_ref($ref);
    # can only update ref that is an alias
    return unless($ref->id_type eq 'alias');
    my $aliasCollection = $ModelSEED::Database::MongoDBSimple::aliasCollection;
    my $o = $self->db->$aliasCollection->find_one(
        {   alias => $ref->alias_string,
            type  => $ref->alias_type,
            owner => $ref->alias_username,
        }
    );
    # return unless we are allowed to see alias
    #     either because it is (1) public, (2) owned by us
    #     or (3) we are in the list of viewers
    return unless(defined($o));
    unless($o->{public}
        || $o->{owner} eq $auth->username)
    {
        my $authorized = 0;
        foreach my $viewer (@{$o->{viewers}}) {
            if($viewer eq $auth->username) {
                $authorized = 1;
                last;
            }
        }
        return unless($authorized);
    }
    return $o->{$attribute};
}

sub _get_uuid {
    my ($self, $ref, $auth) = @_;
    $ref = $self->_cast_ref($ref);
    if($ref->id_type eq 'alias') {
        return $self->alias_uuid($ref, $auth);
    } else {
        return $ref->id;
    }
}

sub _error {
    my ($self, $count) = @_;
    my $errObj = $self->db->last_error();
    unless (!defined($errObj->{err}) && $errObj->{ok}) {
        return 1;
    }
    return 0;
}
sub _update_error {
    my ($self, $count) = @_;
    return 1 if $self->_error;
    my $e = $self->db->last_error();
    return 1 if $e->{n} != $count;
    return 0;
}

sub _object_to_fh {
    my ($self, $obj) = @_;
    my $j = $self->JSON->encode($obj);
    open(my $basic_fh, "<", \$j);
    my $fh = FileHandle->new;
    $fh->fdopen($basic_fh, 'r');
    return $fh;
}

sub _gfs_fh_to_object {
    my ($self, $gfs_fh) = @_;
    my $string = $gfs_fh->slurp();
    return $self->JSON->decode($string);
}

sub _cast_ref {
    my ($self, $ref) = @_;
    if(ref($ref) && $ref->isa("ModelSEED::Reference")) {
        return $ref;
    } else {
        return ModelSEED::Reference->new(ref => $ref);
    }
}

sub _merge_hash {
    my ($a, $b) = @_;
    my %a = %$a;
    foreach my $k (keys %$b) {
        $a{$k} = [] unless defined $a{$k}; 
        push(@{$a{$k}}, @{$b->{$k}});
    }
    return \%a;
}

## Builders

sub _build_json {
    return JSON::XS->new->utf8(1);
}

sub _build_conn {
    my ($self) = @_;
    my $config = {
        db_name        => $self->db_name,
        auto_connect   => 1,
        auto_reconnect => 1
    };
    $config->{host} = $self->host if $self->host;
    $config->{username} = $self->username if $self->username;
    $config->{password} = $self->password if $self->password;
    my $conn = MongoDB::Connection->new(%$config);
    die "Unable to connect: $@" unless $conn;
    return $conn;
}

sub _build_db {
    my ($self) = @_;
    my $db_name = $self->db_name;
    return $self->conn->$db_name;
}

1;
