########################################################################
# ModelSEED::MS::Complex - This is the moose object corresponding to the Complex object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-03-26T23:22:35
########################################################################
use strict;
use ModelSEED::MS::DB::Complex;
package ModelSEED::MS::Complex;
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::DB::Complex';
has roleList => (
    is         => 'rw',
    isa        => 'Str',
    printOrder => '2',
    type       => 'msdata',
    metaclass  => 'Typed',
    lazy       => 1,
    builder    => '_build_roleList'
);
has reactionList => (
    is         => 'rw',
    isa        => 'Str',
    printOrder => '3',
    type       => 'msdata',
    metaclass  => 'Typed',
    lazy       => 1,
    builder    => '_build_reactionList'
);
has roleTuples => (
    is         => 'rw',
    isa        => 'ArrayRef',
    printOrder => '3',
    type       => 'msdata',
    metaclass  => 'Typed',
    lazy       => 1,
    builder    => '_build_roleTuples'
);

sub isActivatedWithRoles {
    my ($self, $args) = @_;
    $args = ModelSEED::utilities::ARGS($args, ["roles"], {});
    my $roles = $args->{roles};
    my $uuid_roles = {};
    # Reduce roles to the simple uuid
    foreach my $role (@$roles) {
        if (ref($role) && eval { $role->isa('ModelSEED::MS::Role') }) {
            $uuid_roles->{$role->uuid} = 1;
        } else {
            $uuid_roles->{$role} = 1;
        }
    }
    # Match against complexrole
    foreach my $cpx_role (@{$self->complexroles}) {
        if ( defined($uuid_roles->{$cpx_role->role_uuid}) ) {
            return 1; 
        }
    }
}
sub createModelReactionProtein {
    my ($self, $args) = @_;
    $args = ModelSEED::utilities::ARGS(
        $args, [], { features => [], note => undef }
    );
    # Generate subunits for each complexRole (takes same args as this function)
    my $subunits = [ map { $_->createProteinSubunit($args) } @{$self->complexroles} ];
    my $hash = {
        modelReactionProteinSubunits => $subunits,
        complex_uuid => $self->uuid,
    };
    $hash->{note} = $args->{note} if defined $args->{note};
    return ModelSEED::MS::ModelReactionProtein->new($hash);
}
sub _build_roleList {
	my ($self) = @_;
	my $roleList = "";
	for (my $i=0; $i < @{$self->complexroles()}; $i++) {
		if (length($roleList) > 0) {
			$roleList .= ";";
		}
		my $cpxroles = $self->complexroles()->[$i];
		$roleList .= $cpxroles->role()->name()."[".$cpxroles->optional()."_".$cpxroles->triggering()."]";		
	}
	return $roleList;
}
sub _build_reactionList {
	my ($self) = @_;
	my $reactionList = "";
	my $cpxrxns = $self->reactions();
	for (my $i=0; $i < @{$cpxrxns}; $i++) {
		if (length($reactionList) > 0) {
			$reactionList .= ";";
		}
		$reactionList .= $cpxrxns->[$i]->id();		
	}
	return $reactionList;
}
sub _build_roleTuples {
    my ($self) = @_;
    my $roletuples = [];
    my $roles = $self->complexroles();
    for (my $i=0; $i < @{$roles}; $i++) {
    	my $role = $roles->[$i];
    	push(@{$roletuples},[$role->role()->id(),$role->type(),$role->optional(),$role->triggering()]);
    }
    return $roletuples;
}

__PACKAGE__->meta->make_immutable;
1;
