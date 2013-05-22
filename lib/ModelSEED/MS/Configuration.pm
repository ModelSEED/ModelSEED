########################################################################
# ModelSEED::MS::Configuration - This is the moose object corresponding to the Configuration object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2013-03-26T04:50:36
########################################################################
package ModelSEED::MS::Configuration;
use strict;
use ModelSEED::MS::DB::Configuration;
use ModelSEED::utilities;
use Try::Tiny;
use Moose;
use ModelSEED::MS::User;
use namespace::autoclean;
extends 'ModelSEED::MS::DB::Configuration';

#***********************************************************************************************************
# ADDITIONAL ATTRIBUTES:
#***********************************************************************************************************
has currentUser => ( is => 'rw', isa => 'ModelSEED::MS::User',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildcurrentUser');

#***********************************************************************************************************
# BUILDERS:
#***********************************************************************************************************
sub _buildcurrentUser {
	my ($self) = @_;
	my $user = $self->queryObject("users",{login => $self->username()});
	if (!defined($user)) {
		ModelSEED::utilities::error("Currently logged user ".$self->username()." does not exist!");
	}
	$user->check_password($self->password());
	return $user;
}

#***********************************************************************************************************
# CONSTANTS:
#***********************************************************************************************************

#***********************************************************************************************************
# FUNCTIONS:
#***********************************************************************************************************
=head3 authenticate

Definition:
	string:username authenticate({token => string});
Description:
	Authenticates against the local user store
	
=cut

sub authenticate {
	my ($self,$args) = @_;
	$args = ModelSEED::utilities::args(["token"], {}, $args);
	if ($args->{token} =~ m/^(.+)\t(.+)$/) {
		my $user = $1;
		my $token = $2;
		my $obj = $self->queryObject("users",{login => $user});
		if (!defined($obj)) {
			ModelSEED::utilities::error("User ".$user." not found!");
		}
		$obj->authenticate($token);
		return $user;
	}
    ModelSEED::utilities::error("Illformed token in authentication!");
}

=head3 add_store

Definition:
	ModelSEED::MS::User = add_store({
		type => string,
		url => string,
		database => string,
		name => string
	});
Description:
	Creates a new store according to input specs
	
=cut

sub add_store {
    my $self = shift;
    my $args = ModelSEED::utilities::args(["name"], {
    	type => "workspace",
    	url => "localhost",
    	database => "msws",
    	login => $self->username(),
    	password => $self->password(),
    	accounttype => "seed"
    }, @_);
	my $store = $self->queryObject("stores",{name => $args->{name}});
	if (defined($store)) {
		ModelSEED::utilities::error("A store with name ".$args->{name}." already exists!");
	}
	$self->validate_store_type($args->{type});
	$store = $self->add("stores",$args);
	$self->currentUser()->add_user_store({
		store => $store,
		login => $args->{login},
		password => $args->{password},
		accounttype => $args->{accounttype}
	});
	return $store;
}

=head3 remove_store

Definition:
	void remove_store({
		name => string,
		delete => 0
	});
Description:
	Removes a store specified by name
	
=cut

sub remove_store {
    my $self = shift;
    my $args = ModelSEED::utilities::args(["name"], {
    	"delete" => 0
    }, @_);
	my $store = $self->queryObject("stores",{name => $args->{name}});
	if (!defined($store)) {
		ModelSEED::utilities::error("A store with name ".$args->{name}." does not exist!");
	}
	if ($args->{delete} == 1) {
		ModelSEED::utilities::error("Cannot delete stores yet!");
	}
	$self->currentUser()->remove_user_store({
		store => $store,
	});
	return $self->remove("stores",$store);
}

=head3 select_store

Definition:
	void select_store(string name);
Description:
	Selects a store by name.
	
=cut

sub select_store {
    my $self = shift;
    my $name = shift;
	my $store = $self->queryObject("stores",{name => $name});
	if (!defined($store)) {
		ModelSEED::utilities::error("A store with name ".$name." does not exist!");
	}
	$self->currentUser()->primaryStoreName($name);
}

=head3 validate_store_type

Definition:
	void validate_store_type(string type);
Description:
	Throws an error if the input type is invalid
	
=cut

sub validate_store_type {
    my $self = shift;
    my $type = shift;
	my $types = {
		workspace => 1,
		filedb => 1,
		mongodb => 1
	};
	if (!defined($types->{$type})) {
		ModelSEED::utilities::error($type." is not a valid type of store!");
	}
}

=head3 logout

Definition:
	void logout();
Description:
	Logs out to the public user
	
=cut

sub logout {
    my $self = shift;
    $self->login({username=>"Public",password=>""});
}

=head3 login

Definition:
	void login({
		username => string,
		password => string
	});
Description:
	Logs in a new user
	
=cut

sub login {
    my $self = shift;
    my $args = ModelSEED::utilities::args(["username","password"], {}, @_);
    my $user = $self->queryObject("users",{login => $args->{username}});
    if (!defined($user)) {
    	$user = $self->import_seed_account({
    		username => $args->{username},
    		password => $args->{password}
    	});
    }
    $user->check_password($args->{password});
    $self->username($args->{username});
    $self->password($user->password());
}

=head3 import_seed_account

Definition:
	void import_seed_account({
		username => string,
		password => string
	});
Description:
	Imports user account from SEED
	
=cut

sub import_seed_account {
    my $self=shift;
    my $args = ModelSEED::utilities::args(["username","password"], {}, @_);
    my $svr = ModelSEED::Client::MSAccountManagement->new();
    my $output;
    try {
        $output = $svr->get_user_info({ username => $args->{username} });
    } catch {
        die "Error in communicating with SEED authorization service.";
    };
    if (defined($output->{error})) {
        ModelSEED::utilities::error($output->{error});
    }
    my $user = ModelSEED::MS::User->new({
        login => $output->{username},
        password => $output->{password},
        firstname => $output->{firstname},
        lastname => $output->{lastname},
        email => $output->{email},
    });
    $user->check_password($args->{password});
    $self->add("users",$user);
}

=head3 save_to_file

Definition:
	void save_to_file({
		filename => string,
	});
Description:
	Saves the configuration to file
	
=cut

sub save_to_file {
    my $self = shift;
    my $args = ModelSEED::utilities::args([], { filename => $ENV{HOME}."/.modelseed2" }, @_);
	my $data = $self->export({format => "json"});
	ModelSEED::utilities::PRINTFILE($args->{filename},[$data]);
}

__PACKAGE__->meta->make_immutable;
1;
