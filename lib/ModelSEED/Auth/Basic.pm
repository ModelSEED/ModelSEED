########################################################################
# ModelSEED::Auth::Basic - Basic Auth ( username + password )
# Authorization
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development locations:
#   Mathematics and Computer Science Division, Argonne National Lab;
#   Computation Institute, University of Chicago
#
# Date of module creation: 2012-05-16
########################################################################

=head1 ModelSEED::Auth::Basic

Do basic authentication ( username + password )

=head1 Methods

=head2 new

    $auth = ModelSEED::Auth::Basic->new({
        username => $username,
        password => $password
    });

C<Username> and C<Password> are required.

=head2 wrap_http_request 

    $bool = $auth->wrap_http_request($request)

Given a HTTP::Request object, wrap that object in authentication
info and return success (1). If there are problems, this returns
false (0). The request object is modified by this call.

=head2 username

    $string = $auth->username();

Returns the username, a string.

=head2 check_password

    $bool = $auth->check_password($store);

Check the username + password pair against user data
located in a L<ModelSEED::Store>. Returns true if the
password was correct. Otherwise it returns false.

=cut

package ModelSEED::Auth::Basic;
use Moose;
use common::sense;
use namespace::autoclean;
use MIME::Base64;
use ModelSEED::Auth;
use Class::Autouse qw(
    HTTP::Request
    ModelSEED::Configuration
    ModelSEED::Client::MSSeedSupport
);

has username => ( is => 'ro', isa => 'Str', required => 1);
has password => ( is => 'ro', isa => 'Str', required => 1);

around 'BUILDARGS' => sub {
    my $orig = shift @_;
    my $self = shift @_;
    my $args;
    if(ref($_[0]) eq 'HASH') {
        $args = shift @_;
    } else {
        $args = { @_ };
    }
    unless(defined($args->{username}) && $args->{password}) {
        my $Config = ModelSEED::Configuration->instance; 
        $args->{username} = $Config->{login}->{username};
        $args->{password} = $Config->{login}->{password};
    }
    return $self->$orig($args);
};

sub wrap_http_request {
    my ($self, $req) = @_;
    die "Not a HTTP::Request" unless($req->isa("HTTP::Request"));
    my ($username, $password) = ($self->username, $self->password);
    my $base64 = encode_base64("$username:$password");
    $req->header( "Authorization" => "Basic: $base64" ); 
    return 1;
}

# TODO - do these functions:
# _download_from_seed and check_password
# really belong here?
# What is the relationship between Auth and MS::User objects?

sub check_password {
    my ($self, $Store) = @_;
    my $username = $self->username;
    my $user = $Store->get_object("user/$username");
    $user = $self->_download_from_seed() if(!defined($user));
    my $authorized = 0;
    if(defined($user)) {
        # Check if plaintext password passed
        if($user->check_password($self->password)) {
            $authorized = 1;
        # Check if crypt + salted password passed
        } elsif($user->password eq $self->password) {
            $authorized = 1;
        }
    }
    return 1 if($authorized);
}

sub _download_from_seed {
    my ($self, $Store) = @_;
    my $svr = ModelSEED::Client::MSSeedSupport->new();
    my $info = $svr->get_user_info({
        username => $self->username,
        password => $self->password
    });
    if(defined($info->{username})) {
        my $user = ModelSEED::MS::User->new({
                login => $info->{username},
                password => $info->{password},
                firstname => $info->{firstname},
                lastname => $info->{lastname},
                email => $info->{email},
            });
        $Store->save_object($user);
        return $user;
    }
    return 0;
}

with 'ModelSEED::Auth';
__PACKAGE__->meta->make_immutable;
1;
