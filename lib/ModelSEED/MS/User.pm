########################################################################
# ModelSEED::MS::User - This is the moose object corresponding to the User object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-03-26T23:22:35
########################################################################
use strict;
use ModelSEED::MS::DB::User;
package ModelSEED::MS::User;
use ModelSEED::utilities;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::DB::User';
#***********************************************************************************************************
# ADDITIONAL ATTRIBUTES:
#***********************************************************************************************************
has msauth => ( is => 'rw', isa => 'Ref',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildmsauth');
has primaryStore => ( is => 'rw', isa => 'ModelSEED::MS::UserStore',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildprimaryStore');

#***********************************************************************************************************
# BUILDERS:
#***********************************************************************************************************
sub _buildmsauth {
	my ($self) = @_;
	if ($self->login() eq "Public") {
		return ModelSEED::Auth::Public->new();
	}
	return ModelSEED::Auth::Basic->new(
		username => $self->login(),
        password => $self->password()
	);
}
sub _buildprimaryStore {
	my ($self) = @_;
	my $stores = $self->userStores();
	foreach my $store (@{$stores}) {
		if ($store->associatedStore()->name() eq $self->primaryStoreName()) {
			return $store;
		}
	}
	return undef;
}

#***********************************************************************************************************
# CONSTANTS:
#***********************************************************************************************************

#***********************************************************************************************************
# FUNCTIONS:
#***********************************************************************************************************
=head3 authenticate

Definition:
	ModelSEED::MS::Store = authenticate(string:token);
Description:
	Authenticates the user account with the specified token
	
=cut

sub authenticate {
    my $self = shift;
    my $token = shift;
    if ($self->check_password($self->password())) {
    	ModelSEED::utilities::error("Authentication failed!");
    }
}


=head3 add_user_store

Definition:
	ModelSEED::MS::Store = add_user_store({
		store => ModelSEED::MS::Store,
		login => string,
		password => string
	});
Description:
	Add user store
	
=cut

sub add_user_store {
    my $self = shift;
    my $args = ModelSEED::utilities::args(["store"], {
		login => $self->login(),
    	password => $self->password(),
    	accounttype => "seed"
    }, @_);
    if ($args->{accounttype} ne "kbase") {
    	$args->{password} = $self->encrypt($self->password());
    }
    return $self->add("userStores",{
    	accountType => $args->{accounttype},
    	store_uuid => $args->{store}->uuid(),
    	login => $args->{login},
    	password => $args->{password}
    });
}

=head3 remove_user_store

Definition:
	void remove_user_store({
		store => ModelSEED::MS::Store
	});
Description:
	Removes a user store specified by store
	
=cut

sub remove_user_store {
    my $self = shift;
    my $args = ModelSEED::utilities::args(["store"], {}, @_);
	foreach my $store (@{$self->userStores()}) {
		if ($store->store_uuid() eq $args->{store}->uuid()) {
			$self->remove("userStores",$store);
			return;
		}
	}
}

=head3 findStore

Definition:
	void findStore({
		store => ModelSEED::MS::Store
	});
Description:
	Removes a user store specified by store
	
=cut

sub findStore {
    my $self = shift;
    my $name = shift;
	foreach my $store (@{$self->userStores()}) {
		if ($store->associatedStore()->name() eq $name) {
			return $store;
		}
	}
	return undef;
}



=head3 set_password

Definition:
	1 = set_password(string password);
Description:
	Sets a password
	
=cut

sub set_password {
    my ($self, $password) = @_;
    my $new_password = encrypt($password);
    $self->password($new_password);
    return 1;
}

=head3 check_password

Definition:
	void check_password(string password);
Description:
	Throws error if password does not match
	
=cut
sub check_password {
    my ($self, $password) = @_;
    if ($password ne $self->password && crypt($password, $self->password) ne $self->password) {
        ModelSEED::utilities::error("Password validation failed!");
    }
}

=head3 encrypt

Definition:
	string encrypt(string password);
Description:
	Encrypts passwords
	
=cut
sub encrypt {
    my ($password) = @_;
    my $seed = join '', ('.', '/', 0..9, 'A'..'Z', 'a'..'z')[rand 64, rand 64];
    return crypt($password, $seed);
}

__PACKAGE__->meta->make_immutable;
1;
