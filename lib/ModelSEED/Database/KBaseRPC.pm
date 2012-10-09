########################################################################
# ModelSEED::Database::KBaseRPC - Wrapper for RPC implementation
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
with 'ModelSEED::Database';
 
has url => ( is => 'ro', isa => 'Str', required => 1 );
has rpc => (
    is       => 'ro',
    init_arg => undef,
    builder  => '_build_rpc'
);

sub init_database {
    my $self = shift @_;
    return _unpack_one $self->rpc->init_database(@_);
}

sub delete_database {
    my $self = shift @_;
    return 1;
}

sub ancestors {
    my $self = shift @_;
    return _unpack_one $self->rpc->ancestors(@_);
}

sub descendants {
    my $self = shift @_;
    return _unpack_one $self->rpc->descendants(@_);
}

sub has_data {
    my $self = shift @_;
    return _unpack_one $self->rpc->has_data(@_);
}

sub get_data {
    my $self = shift @_;
    my $str  = _unpack_one $self->rpc->get_data(@_);
    my $data = decode_json $str;
    return $data;
}

sub save_data {
    my $self = shift @_;
    my $data = shift @_;
    unshift @_, encode_json $data;
    return _unpack_one $self->rpc->save_data(@_);
}

# Alias Functions

sub get_aliases {
    my $self = shift @_;
    return _unpack_one $self->rpc->get_aliases(@_);
}

sub update_alias {
    my $self = shift @_;
    return _unpack_one $self->rpc->update_alias(@_);
}

sub alias_viewers {
    my $self = shift @_;
    return _unpack_one $self->rpc->alias_viewers(@_);
}

sub alias_owner {
    my $self = shift @_;
    return _unpack_one $self->rpc->alias_owner(@_);
}

sub alias_public {
    my $self = shift @_;
    return _unpack_one $self->rpc->alias_public(@_);
}

sub add_viewer {
    my $self = shift @_;
    return _unpack_one $self->rpc->add_viewer(@_);
}

sub remove_viewer {
    my $self = shift @_;
    return _unpack_one $self->rpc->remove_viewer(@_);
}

sub set_public {
    my $self = shift @_;
    return _unpack_one $self->rpc->set_public(@_);
}

# Builders / Helpers

sub _build_rpc {
    my $self = shift;
    # Do this here because it will error out if we
    # don't have a Bio::KBase::fbaModel::Data
    # TODO : Implement exception for ModelSEED::Database::KBaseRPC
    # if Bio::KBase::fbaModel::Data client lib is missing
    load Bio::KBase::fbaModel::Data;
    return Bio::KBase::fbaModel::Data->new($self->url);
}

sub _unpack_one {
    return shift @_; 
}

1;
