package ModelSEED::Database::FileDB;

use Moose;
use namespace::autoclean;

use ModelSEED::Database::FileDB::KeyValueStore;

with 'ModelSEED::Database';

my $SYSTEM_META = "__system__";

has kvstore => (
    is  => 'rw',
    isa => 'ModelSEED::Database::FileDB::KeyValueStore',
    required => 1
);

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;

    my $kvstore = ModelSEED::Database::FileDB::KeyValueStore->new(@_);

    return { kvstore => $kvstore };
};

sub BUILD {
    my ($self) = @_;

    my $kvstore = $self->kvstore();
    if ($kvstore->is_new()) {
        $kvstore->save_object("aliases", {});
        $kvstore->save_object($SYSTEM_META, {});
        $kvstore->set_metadata($SYSTEM_META, 'parents_children', 1);
    }

    # check for system metadata
    if (!$kvstore->has_object($SYSTEM_META)) {
        $kvstore->save_object($SYSTEM_META, {});
    }

    # now check if we have constructed the ancestor/descendant data
    my $sys_meta = $kvstore->get_metadata($SYSTEM_META);
    if (!defined($sys_meta->{parents_children})) {
        print STDERR "Rebuilding FileDB metadata, please wait (this will only happen once)\n";
        $self->_build_parents_and_children();
        $kvstore->set_metadata($SYSTEM_META, 'parents_children', 1);
        print STDERR "Finished rebuilding FileDB metadata.\n";
    }
}

sub has_data {
    my ($self, $ref, $auth) = @_;
    $ref = $self->_cast_ref($ref);
    my $uuid = $self->_get_uuid($ref, $auth);
    return 0 unless(defined($uuid));
    return $self->kvstore->has_object($uuid);
}

sub get_data {
    my ($self, $ref, $auth) = @_;
    $ref = $self->_cast_ref($ref);
    my $uuid = $self->_get_uuid($ref, $auth);
    return unless(defined($uuid));
    return $self->kvstore->get_object($uuid);
}

sub save_data {
    my ($self, $ref, $object, $auth, $config) = @_;
    $auth = $config unless(defined($auth));
    $ref = $self->_cast_ref($ref);
    my ($oldUUID, $update_alias);
    if ($ref->id_type eq 'alias') {
        $oldUUID = $self->_get_uuid($ref, $auth);
        # cannot write to alias not owned by callee
        return unless($auth->username eq $ref->alias_username);
    } elsif($ref->id_type eq 'uuid') {
        # cannot save to existing uuid
        if(!defined($config->{schema_update}) && $self->has_data($ref, $auth)) {
             $oldUUID = $ref->id;
        }
    }
    if(defined($oldUUID)) {
        # We have an existing alias, so must:
        # - insert uuid in ancestors if we're not merging
        if(!defined($object->{ancestor_uuids})) {
            $object->{ancestor_uuids} = [];
        }
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

    # now do the saving
    $self->kvstore->save_object($object->{uuid}, $object);
    # now save 'parents' and 'children' metadata
    my $meta = $self->kvstore->get_metadata($object->{uuid});
    $meta->{parents} = [];
    $meta->{children} = [];
    if (defined($oldUUID)) {
        foreach my $parent_uuid (@{$object->{ancestor_uuids}}) {
            my $parent_meta = $self->kvstore->get_metadata($parent_uuid);

            # set new object as child of parent
            push(@{$parent_meta->{children}}, $object->{uuid});

            # set old object as parent of child
            push(@{$meta->{parents}}, $parent_uuid);

            $self->kvstore->set_metadata($parent_uuid, "", $parent_meta);
        }
    }

    $self->kvstore->set_metadata($object->{uuid}, "", $meta);

    if($update_alias) {
        # update alias to new uuid
        my $rtv = $self->update_alias($ref, $object->{uuid}, $auth);
        return unless($rtv);
    } elsif(!defined($oldUUID) && $ref->id_type eq 'alias') {
        # alias is new, so create it
        my $alias = $self->_build_alias_meta($ref);
        my $info = {
            type => $ref->base_types->[0],
            alias => $ref->alias_string,
            uuid => $object->{uuid},
            owner => $auth->username,
            public => 0,
            viewers => {},
        };

        my $rtv = $self->kvstore->set_metadata('aliases', $alias, $info);
        return unless($rtv);
    }

    return $object->{uuid};
}

# not required, but probably should be
sub delete_data {
    # not yet
}

sub get_aliases {
    my ($self, $ref, $auth) = @_;

    my $query = {};
    if(defined($ref) && ref($ref) eq 'HASH') {
        $query = $ref;
    } elsif(defined($ref)) {
        $ref = $self->_cast_ref($ref);
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

    $query->{public} = 1 unless (defined($query->{public}) && ($query->{public} == 0));

    my $user = $auth->username;
    my $aliases = $self->kvstore->get_metadata('aliases');

    my $matched = [];
    foreach my $alias (keys %$aliases) {
        # match based on permissions
        my $info = $aliases->{$alias};
        if ($info->{owner} eq $user   ||
            $info->{viewers}->{$user} ||
            ($query->{public} && $info->{public})) {

            next if ($query->{type} && ($query->{type} ne $info->{type}));
            next if ($query->{owner} && ($query->{owner} ne $info->{owner}));
            next if ($query->{alias} && ($query->{alias} ne $info->{alias}));
            next if ($query->{uuid} && ($query->{uuid} ne $info->{uuid}));

            push(@$matched, $info);
        }
    }

    return $matched;
}

# not a required method... should it be?
sub alias_uuid {
    my ($self, $ref, $auth) = @_;

    my $alias = $self->_build_alias_meta($ref);
    return unless $alias;

    my $info = $self->kvstore->get_metadata('aliases', $alias);
    return unless defined($info);

    if ($self->_check_permissions($auth->username, $info)) {
        return $info->{uuid};
    } else {
        return;
    }
}

sub alias_owner {
    my ($self, $ref, $auth) = @_;

    my $alias = $self->_build_alias_meta($ref);
    return unless $alias;

    my $info = $self->kvstore->get_metadata('aliases', $alias);
    return unless defined($info);

    if ($self->_check_permissions($auth->username, $info)) {
        return $info->{owner};
    } else {
        return;
    }
}

sub alias_viewers {
    my ($self, $ref, $auth) = @_;

    my $alias = $self->_build_alias_meta($ref);
    return unless $alias;

    my $info = $self->kvstore->get_metadata('aliases', $alias);
    return unless defined($info);

    if ($self->_check_permissions($auth->username, $info)) {
        my @viewers;
        map {push(@viewers, $_)} keys %{$info->{viewers}};

        return \@viewers;
    } else {
        return;
    }
}

sub alias_public {
    my ($self, $ref, $auth) = @_;

    my $alias = $self->_build_alias_meta($ref);
    return unless $alias;

    my $info = $self->kvstore->get_metadata('aliases', $alias);
    return unless defined($info);

    if ($self->_check_permissions($auth->username, $info)) {
        return $info->{public};
    } else {
        return;
    }
}

sub update_alias {
    my ($self, $ref, $uuid, $auth) = @_;

    # can only update ref that is owned by caller
    return 0 unless($ref->alias_username eq $auth->username);

    # change alias to point to new uuid
    my $alias = $self->_build_alias_meta($ref);
    return unless $alias;

    my $info = $self->kvstore->get_metadata('aliases', $alias);
    return unless defined($info);
    $info->{uuid} = $uuid;

    return $self->kvstore->set_metadata('aliases', $alias, $info);
}

sub add_viewer {
    my ($self, $ref, $viewerName, $auth) = @_;

    # can only update ref that is owned by caller
    return 0 unless($ref->alias_username eq $auth->username);

    my $alias = $self->_build_alias_meta($ref);
    return unless $alias;

    my $info = $self->kvstore->get_metadata('aliases', $alias);
    return unless defined($info);
    $info->{viewers}->{$viewerName} = 1;

    return $self->kvstore->set_metadata('aliases', $alias, $info);
}

sub remove_viewer {
    my ($self, $ref, $viewerName, $auth) = @_;

    # can only update ref that is owned by caller
    return 0 unless($ref->alias_username eq $auth->username);

    my $alias = $self->_build_alias_meta($ref);
    return unless $alias;

    my $info = $self->kvstore->get_metadata('aliases', $alias);
    return unless defined($info);
    delete $info->{viewers}->{$viewerName};

    return $self->kvstore->set_metadata('aliases', $alias, $info);
}

sub set_public {
    my ($self, $ref, $bool, $auth) = @_;

    # can only update ref that is owned by caller
    return 0 unless($ref->alias_username eq $auth->username);

    my $alias = $self->_build_alias_meta($ref);
    return unless $alias;

    my $info = $self->kvstore->get_metadata('aliases', $alias);
    return unless defined($info);
    $info->{public} = $bool;

    return $self->kvstore->set_metadata('aliases', $alias, $info);
}

sub ancestors {
    my ($self, $ref, $auth) = @_;

    my $uuid = $self->_get_uuid($ref, $auth);
    return undef unless defined $uuid;

    my $graph = $self->_build_graph('parents', $uuid, {});
    delete $graph->{$uuid};

    my @ancestors = keys %$graph;
    return \@ancestors;
}

sub ancestor_graph {
    my ($self, $ref, $auth) = @_;

    my $uuid = $self->_get_uuid($ref, $auth);
    return undef unless defined $uuid;

    return $self->_build_graph('parents', $uuid, {});
}

sub descendants {
    my ($self, $ref, $auth) = @_;

    my $uuid = $self->_get_uuid($ref, $auth);
    return undef unless defined $uuid;

    my $graph = $self->_build_graph('children', $uuid, {});
    delete $graph->{$uuid};

    my @descendants = keys %$graph;
    return \@descendants;
}

sub descendant_graph {
    my ($self, $ref, $auth) = @_;

    my $uuid = $self->_get_uuid($ref, $auth);
    return undef unless defined $uuid;

    return $self->_build_graph('children', $uuid, {});
}

# required, but not defined yet
sub find_data {
    # not yet
}

sub _check_permissions {
    my ($self, $user, $info) = @_;

    if ($user eq $info->{owner} ||
        $info->{public}         ||
        $info->{viewers}->{$user}) {
        return 1;
    } else {
        return 0;
    }
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

sub _cast_ref {
    my ($self, $ref) = @_;
    if(ref($ref) && $ref->isa("ModelSEED::Reference")) {
        return $ref;
    } else {
        return ModelSEED::Reference->new(ref => $ref);
    }
}

sub _build_alias_meta {
    my ($self, $ref) = @_;

    my $t = $ref->base_types->[0];
    my $u = $ref->alias_username;
    my $a = $ref->alias_string;

    unless (defined($t) && defined($u) && defined($a)) {
        return 0;
    }

    return "$t/$u/$a";
}

sub _build_parents_and_children {
    my ($self) = @_;

    # assume no merges, deletions, or anything fancy,
    # start at alias and work way backwards
    my $alias_meta = $self->kvstore->get_metadata('aliases');
    foreach my $alias (keys %$alias_meta) {
        my $uuid = $alias_meta->{$alias}->{uuid};
        my $object = $self->kvstore->get_object($uuid);
        my $meta = $self->kvstore->get_metadata($uuid);

        $meta->{children} = [];

        while (defined($object->{ancestor_uuids}) &&
               scalar @{$object->{ancestor_uuids}} > 0) {
            my $parent_uuid = $object->{ancestor_uuids}->[0];
            my $parent = $self->kvstore->get_object($parent_uuid);
            my $parent_meta = $self->kvstore->get_metadata($parent_uuid);

            $meta->{parents} = [ $parent_uuid ];
            $parent_meta->{children} = [ $uuid ];

            $self->kvstore->set_metadata($uuid, "", $meta);

            $uuid = $parent_uuid;
            $object = $parent;
            $meta = $parent_meta;
        }

        $meta->{parents} = [];
        $self->kvstore->set_metadata($uuid, "", $meta);
    }
}

sub _build_graph {
    my ($self, $type, $uuid, $graph) = @_;

    my $meta = $self->kvstore->get_metadata($uuid);
    $graph->{$uuid} = $meta->{$type};
    foreach my $other_uuid (@{$meta->{$type}}) {
        $self->_build_graph($type, $other_uuid, $graph);
    }

    return $graph;
}

# TODO : replace with needed logic:
sub init_database {
    return 1;
}
sub delete_database {
    return 1;
}

1;
