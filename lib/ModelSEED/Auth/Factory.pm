########################################################################
# ModelSEED::Auth::Factory - Generate an Auth from various sources
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development locations:
#   Mathematics and Computer Science Division, Argonne National Lab;
#   Computation Institute, University of Chicago
#
# Date of module creation: 2012-05-16
########################################################################

=head1 ModelSEED::Auth::Factory

Generate a L<ModelSEED::Auth> from varous sources.

=head1 Abstract

This is a factory which returns a L<ModelSEED::Auth> object.

=head2 Methods

=head3 from_http_request

    $auth = $factory->from_http_request($req)

Returns an auth from an http request. If Basic Authorization is
used, this returns a L<ModelSEED::Auth::Basic>. If no authorization
is used, this reutrns a L<ModelSEED::Auth::Public>. In the future,
we will include OAuth support.

=head3 from_dancer_request

    $auth = $factory->from_dancer_request($req)

Returns an auth from an L<Dancer::Request>. If Basic Authorization is
used, this returns a L<ModelSEED::Auth::Basic>. If no authorization
is used, this reutrns a L<ModelSEED::Auth::Public>. In the future,
we will include OAuth support.

=head3 from_config

    $auth = $factory->from_config()

Returns an auth from the L<ModelSEED::Configuration> information.

=head2 Notes

It looks like the L<HTTP::Request> "Authorization" header inserts
an additional colon while the L<Dancer::Request> respects the
HTTP spec and does not. So where L<Dancer::Request> has:

    Authorization: Basic <base64 encoded username:password >

L<HTTP::Request> has:

    Authorization: Basic: <base64 encoded username:password >

=cut

package ModelSEED::Auth::Factory;
use Moose;
use ModelSEED::Auth;
use MIME::Base64;
use Class::Autouse qw(
    ModelSEED::Configuration
    ModelSEED::Auth::Basic
    ModelSEED::Auth::Public
    HTTP::Request
);

sub from_http_request {
    my ($self, $req) = @_;
    die "Unknown request type" unless($req->isa("HTTP::Request"));
    my $authorization = $req->header("Authorization");
    my $Auth;
    if(defined($authorization) && $authorization =~ /Basic\S* (.*)/) {
        my $base64 = $1;
        my $string = decode_base64($base64);
        my ($username, $password) = split(/:/, $string);
        if(defined($username) && defined($password)) {
            $Auth = ModelSEED::Auth::Basic->new(
                username => $username,
                password => $password
            );
        }
    }
    if(!defined($Auth)) {
        $Auth = ModelSEED::Auth::Public->new();
    }
    return $Auth;
}
sub from_dancer_request {
    my ($self, $req) = @_;
    die "Unknown request type" unless($req->isa("Dancer::Request"));
    my $authorization = $req->header("Authorization");
    my $Auth;
    if(defined($authorization) && $authorization =~ /Basic\S* (.*)/) {
        my $base64 = $1;
        my $string = decode_base64($base64);
        my ($username, $password) = split(/:/, $string);
        if(defined($username) && defined($password)) {
            $Auth = ModelSEED::Auth::Basic->new(
                username => $username,
                password => $password
            );
        }
    }
    if(!defined($Auth)) {
        $Auth = ModelSEED::Auth::Public->new();
    }
    return $Auth;
}

sub from_config {
    my $Config = ModelSEED::Configuration->instance;
    my $Auth;
    if(defined($Config->config->{login})) {
        my $info = $Config->config->{login};
        if (defined($info->{username}) && defined($info->{password})) {
            $Auth = ModelSEED::Auth::Basic->new(
                username => $info->{username},
                password => $info->{password}
            );
        }
    }
    if(!defined($Auth)) {
        $Auth = ModelSEED::Auth::Public->new();
    }
    return $Auth;
}
1;
