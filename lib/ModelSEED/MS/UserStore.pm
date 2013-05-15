########################################################################
# ModelSEED::MS::UserStore - This is the moose object corresponding to the UserStore object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2013-04-01T03:28:27
########################################################################
use strict;
use ModelSEED::MS::DB::UserStore;
package ModelSEED::MS::UserStore;
use Moose;
use namespace::autoclean;
use ModelSEED::Auth::Basic;
use ModelSEED::KBaseStore;
extends 'ModelSEED::MS::DB::UserStore';
#***********************************************************************************************************
# ADDITIONAL ATTRIBUTES:
#***********************************************************************************************************
has msauth => ( is => 'rw', isa => 'Ref',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildmsauth');
has msstore => ( is => 'rw', isa => 'ModelSEED::Store',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildmsstore');
has wsstore => ( is => 'rw', isa => 'ModelSEED::KBaseStore',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildwsstore');
has wsworkspace => ( is => 'rw', isa => 'Str',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildwsworkspace');
has wsauth => ( is => 'rw', isa => 'Str',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildwsauth');
has defaultMapping => ( is => 'rw', isa => 'ModelSEED::MS::Mapping',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_builddefaultMapping');
has defaultBiochemistry => ( is => 'rw', isa => 'ModelSEED::MS::Biochemistry',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_builddefaultBiochemistry');
has objectManager => ( is => 'rw', isa => 'Ref',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildobjectManager');
has wsTypeTrans => ( is => 'rw', isa => 'Ref',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildwsTypeTrans');

#***********************************************************************************************************
# BUILDERS:
#***********************************************************************************************************
sub _buildmsstore {
	my ($self) = @_;
	return  ModelSEED::Store->new(auth => $self->msauth());
}
sub _buildwsauth {
	my ($self) = @_;
	if ($self->accountType() eq "seed") {
		return $self->login()."\t".$self->password();
	} elsif ($self->accountType() eq "kbase") {
		require "Bio/KBase/AuthToken.pm";
		my $token = Bio::KBase::AuthToken->new(user_id => $self->login(), password => $self->password());
		if (!defined($token->token())) {
			ModelSEED::utilities::error("KBase login failed!");
		}
		return $token->token();
	}
}
sub _buildwsworkspace {
	my ($self) = @_;
	my $wsstore = $self->wsstore();
	my $settings = $wsstore->workspace()->get_user_settings({
		auth => $self->wsauth()
	});
	return $settings->{workspace};
}
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
sub _buildwsstore {
	my ($self) = @_;
	my $ws;
	if ($self->associatedStore()->url() eq "localhost") {
		require "Bio/KBase/workspaceService/Impl.pm";
		$ws = Bio::KBase::workspaceService::Impl->new({
			"accounttype" => "modelseed",
			"mongodb-host" => $self->associatedStore()->url(),
			"mongodb-database" => $self->associatedStore()->database()
		});
	} else {
		require "Bio/KBase/workspaceService/Client.pm";
		$ws = Bio::KBase::workspaceService::Client->new($self->associatedStore()->url());
	}
	if ($self->login() eq "Public") {
		return ModelSEED::KBaseStore->new({
			auth => "",
			workspace => $ws
		});
	} else {
		return ModelSEED::KBaseStore->new({
			auth => $self->wsauth(),
			workspace => $ws
		});
	}
}
sub _builddefaultMapping {
	my ($self) = @_;
	my $ref = $self->parseReference($self->defaultMapping_ref(),"Mapping");
	return $self->get_object({
		type => "Mapping",
		id => $ref->{id},
		workspace => $ref->{workspace}
	});
}
sub _builddefaultBiochemistry {
	my ($self) = @_;
	my $ref = $self->parseReference($self->defaultBiochemistry_ref(),"Biochemistry");
	return $self->get_object({
		type => "Biochemistry",
		id => $ref->{id},
		workspace => $ref->{workspace}
	});
}
sub _buildobjectManager {
	my ($self) = @_;
	my $store = $self->associatedStore();
    if ($store->type() eq "filedb" || $store->type() eq "mongo") {
    	return $self->msstore();
    } else {
    	return $self->wsstore();
    }
}
sub _buildwsTypeTrans {
	my ($self) = @_;
	return {
		Biochemistry => "Biochemistry",
		Model => "Model",
		Annotation => "Annotation",
		Mapping => "Mapping",
		FBA => "FBAFormulation",
		Media => "Media",
		GapFill => "GapfillingFormulation",
		GapGen => "GapgenFormulation",
		PromConstraints => "PROMModel",
		ModelTemplate => "ModelTemplate",
		RegulatoryModel => "RegulatoryModel"
	};
}

#***********************************************************************************************************
# CONSTANTS:
#***********************************************************************************************************

#***********************************************************************************************************
# FUNCTIONS:
#***********************************************************************************************************
=head3 reconcileReference

Definition:
	<type>/<workspace>/<id> reconcileReference(string reference,string type);
Description:
	Standardizes the input reference
	
=cut

sub reconcileReference {
	my ($self,$reference,$intype) = @_;
	my $refs = [split(/\//,$reference)];
	my $id;
	my $type;
	my $context;
	if (defined($intype)) {
		$type = $intype;
	}
	if (@{$refs} == 1) {
		$id = $refs->[0];
	} elsif (@{$refs} == 2) {
		$id = $refs->[1];
		if ($type ne $refs->[0]) {
			$context = $refs->[0];
		}
	} elsif (@{$refs} == 3) {
		$id = $refs->[2];
		$context = $refs->[1];
		$type = $refs->[0];
	}
	if (!defined($context)) {
		if ($id !~ m/[A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12}/) {
			if ($self->associatedStore()->type() eq "filedb" || $self->associatedStore()->type() eq "mongo") {
				$context = $self->login();
			} else {
				$context = $self->wsworkspace();
			}
		}
	}
	if (!defined($context)) {
		return $type."/".$id;
	} else {
		return $type."/".$context."/".$id;
	}
}

=head3 parseReference

Definition:
	{id,type,context} parseReference(string reference,string type);
Description:
	Parses the input reference
	
=cut

sub parseReference {
	my ($self,$reference,$intype) = @_;
	$reference = $self->reconcileReference($reference,$intype);
	my $refs = [split(/\//,$reference)];
	my $output = {
		reference => $reference
	};
	if (@{$refs} == 2) {
		$output->{id} = $refs->[1];
		$output->{type} = $refs->[0];
	} elsif (@{$refs} == 3) {
		$output->{id} = $refs->[2];
		$output->{workspace} = $refs->[1];
		$output->{type} = $refs->[0];
	}
	return $output;
}

=head3 setDefaultMapping

Definition:
	ModelSEED::MS::? get_object({
		workspace => string,
		type => string,
		id => string
	});
Description:
	Retrieves an object from the specified store
	
=cut

sub setDefaultMapping {
	my ($self,$mapping) = @_;
	$mapping = $self->reconcileReference($mapping,"Mapping");
	$self->defaultMapping_ref($mapping);
}

=head3 get_object

Definition:
	ModelSEED::MS::? get_object({
		workspace => string,
		type => string,
		id => string
	});
Description:
	Retrieves an object from the specified store
	
=cut
sub get_object {
    my $self = shift;
    my $args = ModelSEED::utilities::args(["type","id"], {
		workspace => undef
    }, @_);
    my $store = $self->associatedStore();
    if ($store->type() eq "filedb" || $store->type() eq "mongo") {
    	my $msstore = $self->msstore();
    	my $ref;
    	my $id;
    	if ($args->{id} =~ m/[A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12}/) {
    		$ref = ModelSEED::Reference->new("ref" => $args->{type}."/".$args->{id});
    		$id = $args->{type}."/".$self->login()."/".$msstore->get_aliases($ref)->[0];
    	} else {
    		$id = $args->{type}."/".$self->login()."/".$args->{id};
	    	$ref = ModelSEED::Reference->new("ref" => $args->{type}."/".$self->login()."/".$args->{id});
    	}
	    if(defined($ref)) {
	    	my $obj = $msstore->get_object($ref);
	    	$obj->{_msStoreID} = $id;
	    	$obj->{_msStoreRef} = $args->{type}."/".$obj->uuid();
	       	return $obj;
	    } else {
	       	return (undef);
	    }
    } else {
    	my $wsstore = $self->wsstore();
    	my $ws = $self->wsworkspace();
    	if (defined($args->{workspace})) {
    		$ws = $args->{workspace};
    	}
    	if ($args->{id} =~ m/[A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12}/) {
    		return $wsstore->get_object($args->{type},$args->{id});
    	} else {
    		return $wsstore->get_object($args->{type},$ws."/".$args->{id});
    	}
    	
    }
	return undef;
}
=head3 get_data

Definition:
	{} get_data({
		workspace => string,
		type => string,
		id => string
	});
Description:
	Retrieves object data from the specified store
	
=cut

sub get_data {
    my $self = shift;
    my $args = ModelSEED::utilities::args(["type","id"], {
		workspace => undef
    }, @_);
    my $store = $self->associatedStore();
    if ($store->type() eq "filedb" || $store->type() eq "mongo") {
    	my $msstore = $self->msstore();
    	my $refstr = $args->{type}."/".$self->login()."/".$args->{id};
    	my $ref = ModelSEED::Reference->new(ref => $refstr);  	
      	if(defined($ref)) {
        	return $msstore->get_data($ref);
    	} else {
        	return (undef);
    	}
    } else {
    	my $wsstore = $self->wsstore();
    	my $ws = $self->wsworkspace();
    	if (defined($args->{workspace})) {
    		$ws = $args->{workspace};
    	}
    	return $wsstore->get_object($args->{type},$ws."/".$args->{id},1);
    }
	return undef;
}
=head3 save_object

Definition:
	void save_object({
		workspace => string,
		type => string,
		id => string,
		object => ModelSEED::MS::?
	});
Description:
	Saves an object in the store
	
=cut

sub save_object {
    my $self = shift;
    my $args = ModelSEED::utilities::args(["type","id","object"], {
		workspace => undef
    }, @_);
    my $data = $args->{object}->serializeToDB(); 
    $self->save_data({
    	type => $args->{type},
    	workspace => $args->{workspace},
    	id => $args->{id},
    	data => $data,
    });
}
=head3 save_data

Definition:
	ModelSEED::MS::? save_data({
		workspace => string,
		type => string,
		id => string
	});
Description:
	Saves object data in the store
	
=cut

sub save_data {
    my $self = shift;
    my $args = ModelSEED::utilities::args(["type","id","data"], {
		workspace => undef
    }, @_);
    my $store = $self->associatedStore();
    if ($store->type() eq "filedb" || $store->type() eq "mongo") {
    	my $msstore = $self->msstore();
    	my $refstr = $args->{type}."/".$self->login()."/".$args->{id};
    	my $ref = ModelSEED::Reference->new(ref => $refstr);  	
      	$store->save_data($ref,$args->{data});
    } else {
    	my $wsstore = $self->wsstore();
    	my $ws = $self->wsworkspace();
    	if (defined($args->{workspace})) {
    		$ws = $args->{workspace};
    	}
    	my $wsmeta;
    	eval {
	    	$wsmeta = $wsstore->workspace()->get_workspacemeta({
	    		id => $args->{id},
				workspace => $ws,
				auth => $self->wsauth()
	    	});
    	};
    	if (!defined($wsmeta)) {
    		$wsstore->workspace()->create_workspace({
    			workspace => $ws,
				auth => $self->wsauth(),
				default_permission => "r"
    		});
    	}
    	return $wsstore->workspace()->save_object({
			id => $args->{id},
			workspace => $ws,
			type => $args->{type},
			auth => $self->wsauth(),
			data => $args->{data},
			command => "save_object"
		});
    }
}
=head3 list

Definition:
	[[]] list({
		reference => string,
		mine => 0/1,
		fields => [],
		query => {},
	});
Description:
	Saves object data in the store
	
=cut

sub list {
    my $self = shift;
    my $args = ModelSEED::utilities::args([], {
		reference => undef,
		fields => ["Reference"],
		query => {}
    }, @_);
    my $output = {
    	headings => ["References"],
    	data => []
    };
    my $store = $self->associatedStore();
    if (!defined($args->{reference}) || length($args->{reference}) == 0) {
    	$output->{headings} = ["References","Count"];
    	my $types = {};
    	if ($store->type() eq "filedb" || $store->type() eq "mongo") {
	    	my $aliases = $self->objectManager()->get_aliases({});
	        foreach my $alias (@$aliases) {
	            $types->{$alias->{type}} = 0 unless(defined($types->{$alias->{type}}));
	            $types->{$alias->{type}} += 1;
	        }
    	} else {
    		my $wsc = $self->wsstore()->workspace();
    		my $wss = $wsc->list_workspaces({
    			auth => $self->wsauth()
    		});
    		foreach my $ws (@{$wss}) {
    			my $objs = $wsc->list_workspace_objects({
	    			workspace => $ws->[0],
	    			auth => $self->wsauth()
	    		});
	    		foreach my $obj (@{$objs}) {
	    			if (defined($self->wsTypeTrans()->{$obj->[1]})) {
	    				$types->{$self->wsTypeTrans()->{$obj->[1]}} = 0 unless(defined($self->wsTypeTrans()->{$obj->[1]}));
	            		$types->{$self->wsTypeTrans()->{$obj->[1]}} += 1;
	    			}
	    		}
    		}
    	}
    	foreach my $type (keys %$types) {
	       	push(@{$output->{data}},[$type."/",$types->{$type}]);
	    }
    	return $output;
    }
    my $refs = [split(/\//,$args->{reference})];
    my $size = (@{$refs}-1);
    if (length($refs->[$size]) == 0) {
    	pop(@{$refs});
    }
    if (@{$refs} == 1) {
    	if ($store->type() eq "filedb" || $store->type() eq "mongo") {
	    	my $aliases = $self->objectManager()->get_aliases({type => $refs->[0]});
	        foreach my $alias (@$aliases) {
	            push(@{$output->{data}},[$alias->{type}."/".$alias->{owner}."/".$alias->{alias}]);
	        }
    	} else {
    		my $wsc = $self->wsstore()->workspace();
    		my $wss = $wsc->list_workspaces({
    			auth => $self->wsauth()
    		});
    		foreach my $ws (@{$wss}) {
    			my $objs = $wsc->list_workspace_objects({
	    			workspace => $ws->[0],
	    			auth => $self->wsauth(),
	    		});
	    		foreach my $obj (@{$objs}) {
	    			if (defined($self->wsTypeTrans()->{$obj->[1]}) && $self->wsTypeTrans()->{$obj->[1]} eq $refs->[0]) {
	    				push(@{$output->{data}},[$refs->[0]."/".$ws->[0]."/".$obj->[0]]);
	    			}
	    		}
    		}
    	}
    } elsif (@{$refs} == 2 && $refs->[1] !~ m/[A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12}/) {
    	if ($store->type() eq "filedb" || $store->type() eq "mongo") {
	    	my $aliases = $self->objectManager()->get_aliases({type => $refs->[0]});
	        foreach my $alias (@$aliases) {
	            if ($alias->{owner} eq $refs->[1]) {
	            	push(@{$output->{data}},[$alias->{type}."/".$alias->{owner}."/".$alias->{alias}]);
	            }
	        }
    	} else {
    		my $wsc = $self->wsstore()->workspace();
    		my $objs = $wsc->list_workspace_objects({
	    		workspace => $refs->[1],
	    		auth => $self->wsauth()
	    	});
	    	foreach my $obj (@{$objs}) {
	    		if ($self->wsTypeTrans()->{$obj->[1]} eq $refs->[0]) {
	    			push(@{$output->{data}},[$refs->[0]."/".$refs->[1]."/".$obj->[0]]);
	    		}
	    	}
       	}
    } elsif (@{$refs} == 2 || (@{$refs} == 3 && $refs->[1] !~ m/[A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12}/)) {
    	$output->{headings} = ["References","Count"];
		my $data;
		if (@{$refs} == 2) {
			$data = $self->get_data({type => $refs->[0],id => $refs->[1]});
		} else {
			$data = $self->get_data({type => $refs->[0],workspace => $refs->[1],id => $refs->[2]});
		}
		foreach my $k ( keys %$data ) {
			my $v = $data->{$k};
			if(ref($v) eq 'ARRAY') {
				push(@{$output->{data}},[$args->{reference}."/".$k,scalar(@$v)]);
			} elsif ($k =~ m/.+_uuid$/) {
				push(@{$output->{data}},[$args->{reference}."/".$k,$v]);
			}
		}
    } else {
    	$output->{headings} = $args->{fields};
    	my $object;
    	my $refIndex = 3;
    	my $ref;
    	if ($refs->[1] =~ m/[A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12}/) {
    		$ref = $refs->[0]."/".$refs->[1];
    		$refIndex = 2;
    		$object = $self->get_object({type => $refs->[0],id => $refs->[1]});
    	} else {
    		$ref = $refs->[0]."/".$refs->[1]."/".$refs->[2];
    		$object = $self->get_object({type => $refs->[0],workspace => $refs->[1],id => $refs->[2]});
    	}
    	my $subobject = $refs->[$refIndex];
    	my $objs;
    	if (keys(%{$args->{query}}) == 0) {
    		$objs = $object->$subobject();
    	} else {
    		$objs = $object->queryObjects($subobject,$args->{query});
    	}
    	foreach my $obj (@{$objs}) {
    		my $row = [];
    		foreach my $heading (@{$args->{fields}}) {
    			if ($heading eq "Reference") {
    				push(@{$row},$ref."/".$subobject."/".$obj->uuid());
    			} else {
    				push(@{$row},$obj->$heading());
    			}
    		}
    		push(@{$output->{data}},$row);
    	}
    }
    return $output;
}

__PACKAGE__->meta->make_immutable;
1;
