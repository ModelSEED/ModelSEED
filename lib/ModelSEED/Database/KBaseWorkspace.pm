########################################################################
# ModelSEED::Database::KBaseWorkspace - Wrapper for to access KBase
# workspace data pertaining to models
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development locations:
#   Mathematics and Computer Science Division, Argonne National Lab;
#   Computation Institute, University of Chicago
#
# Date of module creation: 2012-09-27
########################################################################
package ModelSEED::Database::KBaseRPC;
use strict;
use common::sense;
use Moose;
use Module::Load;
use JSON::XS;
use Try::Tiny;
with 'ModelSEED::Database';
 
has url        => ( is => 'ro', isa => 'Str', required => 1 );
has workspace  => ( is => 'ro', isa => 'Str', required => 1 );
has rpc => (
    is       => 'ro',
    init_arg => undef,
    builder  => '_build_rpc'
);

sub init_database {
    return 1;
}

sub delete_database {
    return 0;
}

sub ancestors {
    # TODO : workspace needs ancestor functions
    return [];
}

sub descendants {
    # TODO : workspace needs dscendant functions
    return [];
}

sub has_data {
    my ($self, $ref, $auth) = @_;
    my ($id, $type) = _inspect_ref($ref);
    my $bool;
    try {
        ($bool) = $self->rpc->has_object(
            $id, $type, $self->workspace
        );
    } catch {
        $bool = 0;
    };
    return $bool;
}

sub get_data {
    my ($self, $ref, $auth) = @_;
    my ($id, $type) = _inspect_ref($ref);
    my ($data, $meta);
    try {
        ($data, $meta) = $self->rpc->get_data(
            $id, $type, $self->workspace
        );
    };
    return $data;
}

sub save_data {
    my ($self, $ref, $data, $config, $auth) = @_;
    my ($id, $type) = _inspect_ref($ref);
    my $meta;
    my $options;
    try {
        ($meta) = $self->rpc->save_object(
            $id, $type, $data, $self->workspace, $options
        );

    };
    return (defined $meta) ? 1 : 0;
}

# Alias Functions

sub get_aliases {
    my ($self, $query, $auth) = @_;
    my $metas;
    my $options = {};
    # Restring to a specific type
    my $query_type = _map_ref_type($query->{type});
    $options->{type} = $query_type if defined $query_type;
    try {
        ($metas) = $self->rpc->list_workspace_objects(
            $self->workspace, $options
        );
    };
    my @metas = @$metas;
    # Restrict to just those that are owned by the owner
    if (defined $query->{owner}) {
        @metas = grep { $_[6] =~ $query->{owner} } @metas;
    }
    # Restrict to a particular alias
    if (defined $query->{alias}) {
        @metas = grep { $_[0] =~ $query->{alias} } @metas;
    }
    # Transform into a hash and filter out all undefined results
    return [ grep { defined $_ } map { _meta_to_alias $_ } @metas ];
}

sub update_alias {
    my ($self, $ref, $uuid, $auth) = @_;
    # TODO : can't call update_alias unless I can handle UUIDs
    return 0;
}

sub alias_viewers {
    my ($self, $ref, $auth) = @_;
    # TODO : no way to list all the users who have access to a workspace?
    return [];
}

sub alias_owner {
    my ($self, $ref, $auth) = @_;
    my ($id, $type) = _inspect_ref($ref);
    my $meta;
    try {
        ($meta) = $self->rpc->get_objectmeta(
            $id, $type, $self->workspace        
        );
    };
    return undef unless defined $meta;
    return $meta->[6];
}

sub alias_public {
    my ($self, $ref, $auth) = @_;
    my $metas = [];
    try {
        ($metas) = $self->rpc->list_workspaces; 
    };
    foreach my $meta (@$metas) {
        $meta = _ws_meta($meta);
        next unless $meta->{workspace_id} eq $self->workspace;
        if ($meta->{global_permission} eq "n") {
            return 0;
        } else {
            return 1;
        }
    }
    return 0;
}

sub add_viewer {
    my ($self, $ref, $username, $auth) = @_;
    # TODO : Need better viewer functions
}

sub remove_viewer {
    my ($self, $ref, $username, $auth) = @_;
    # TODO : Need better viewer functions
}

sub set_public {
    my ($self, $ref, $username, $auth) = @_;
    # TODO : Need better viewer functions
}

# Builders / Helpers

sub _build_ws {
    my $self = shift;
    # Do this here because it will error out if we
    # don't have a Bio::KBase::fbaModel::Data
    load Bio::KBase::workspaceService;
    return Bio::KBase::workspaceService->new($self->url);
}

sub _unpack_one {
    return shift @_; 
}

sub _remove_auth {
    my @args = ();
    foreach my $arg (@_) {

        if(!ref($arg) || !eval { $arg->does("ModelSEED::Auth") } ) {
            push(@args, $arg);
        }
    }
    return @args;
}

sub _transform_refs {
    my @args = ();
    foreach my $arg (@_) {
        if(ref($arg) && eval { $arg->isa("ModelSEED::Reference") } ) {
            push(@args, $arg->ref);
        } else {
            push(@args, $arg);
        }
    }
    return @args;
}

# map from reference type to type in workspaces:
# e.g. "biochemistry" to "ModelSEED::Biochemistry"
sub _map_ref_type {
    my $ref_type = shift;
    my $map = {
        biochemistry => "ModelSEED::Biochemistry",
        model        => "ModelSEED::Model",
        mapping      => "ModelSEED::Mapping",
        annotation   => "ModelSEED::Annotation",
    };
    return $map->{$ref_type};
}

sub _map_type_ref {
    my $type = shift;
    my $map = {
        'ModelSEED::Biochemistry' => "biochemistry",
        'ModelSEED::Model'        => "model",
        'ModelSEED::Mapping'      => "mapping",
        'ModelSEED::Annotation'   => "annotation",
    };
    return $map->{$type};
}

sub _meta_to_alias {
    my $meta = shift;
    my $type = _map_type_ref($meta->[1]);
    return undef unless defined $type;
    return {
        uuid  => undef,
        type  => $type,
        alias => $meta->[0],
        owner => $meta->[6],
    };
}

# given an object_meta return a reference string
sub _map_meta_to_ref {
    my $meta  = shift;
    my $id    = $meta->[0];
    my $owner = $meta->[6];
    my $type  = _map_type_ref($meta->[1]);
    return undef unless defined $type;
    return "$type/$owner/$id";
}

sub _merge_arrays_as_hash {
    my ($keys, $values) = @_;
    my %hash;
    @hash{@$keys} = @$values;
}

sub _ws_meta {
    my $values = shift;
    my $keys = [qw(
        workspace_id
        modification_timestamp
        number_of_objects
        user_permission
        global_permission
    )];
    return _merge_arrays_as_hash($keys, $values);
}

sub _obj_meta {
    my $values = shift;
    my $keys = [qw(
        object_id
        object_type
        modification_timestamp
        instance
        command
        last_modifier_used
        owner_username
    )];
    return _merge_arrays_as_hash($keys, $values);
}

1;
