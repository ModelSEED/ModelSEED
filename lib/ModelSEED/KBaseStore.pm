########################################################################
# ModelSEED::KBaseStore - A class for managing ModelSEED object retrieval from KBase
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location:
#   Mathematics and Computer Science Division, Argonne National Lab;
#   Computation Institute, University of Chicago
#
# Date of module creation: 2013-01-27
########################################################################

=head1 ModelSEED::KBaseStore 

Class for managing ModelSEED object retreival from KBase

=head2 ABSTRACT

=head2 NOTE


=head2 METHODS

=head3 new

    my $Store = ModelSEED::KBaseStore->new(\%);
    my $Store = ModelSEED::KBaseStore->new(%);

This initializes a Storage interface object. This accepts a hash
or hash reference to configuration details:

=over

=item auth

Authentication token to use when retrieving objects

=item workspace

Client or server class for accessing a KBase workspace

=back

=head3 Object Methods

=cut

package ModelSEED::KBaseStore;
use Moose;
use ModelSEED::utilities;

use Class::Autouse qw(
    Bio::KBase::workspaceService::Client
    Bio::KBase::workspaceService::Impl
    ModelSEED::MS::Biochemistry
    ModelSEED::MS::Annotation
    ModelSEED::MS::Media
    ModelSEED::MS::ModelTemplate
    ModelSEED::MS::PROMModel
    ModelSEED::MS::RegulatoryModel
    ModelSEED::MS::Mapping
    ModelSEED::MS::Classifier
    ModelSEED::MS::BiochemistryStructures
    ModelSEED::MS::GapfillingFormulation
    ModelSEED::MS::FBAFormulation
    ModelSEED::MS::GapgenFormulation
);
use Module::Load;

#***********************************************************************************************************
# ATTRIBUTES:
#***********************************************************************************************************
has auth => ( is => 'rw', isa => 'Str', required => 1);
has workspace => ( is => 'rw', isa => 'Ref', required => 1);
has cache => ( is => 'rw', isa => 'HashRef',default => sub { return {}; });

#***********************************************************************************************************
# BUILDERS:
#***********************************************************************************************************

#***********************************************************************************************************
# CONSTANTS:
#***********************************************************************************************************
sub _mstypetrans {
	return {
		Biochemistry => "Biochemistry",
		Annotation => "Annotation",
		Mapping => "Mapping",
		FBAFormulation => "FBA",
		Model => "Model",
		GapfillingFormulation => "GapFill",
		GapgenFormulation => "GapGen",
		PROMModel => "PromConstraints",
		Media => "Media",
		ModelTemplate => "ModelTemplate"
	};
}
sub _wstypetrans {
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
		ModelTemplate => "ModelTemplate"
	};
}
#***********************************************************************************************************
# FUNCTIONS:
#***********************************************************************************************************
sub get_object {
    my ($self,$type,$ref,$dataOnly) = @_;
    if (!defined($dataOnly)) {
    	$dataOnly = 0;
    }
    #If the object is cached, returning the cached object
    if (defined($self->cache()->{$type}->{$ref})) {
    	return $self->cache()->{$type}->{$ref};
    }
    #If this is a ModelSEED type, we identify the class and translate to a workspace type
    my $class;
    if (defined($self->_mstypetrans()->{$type})) {
    	$class = "ModelSEED::MS::".$type;
    	$type = $self->_mstypetrans()->{$type};
    } elsif (defined($self->_wstypetrans()->{$type})) {
    	$class = "ModelSEED::MS::".$self->_wstypetrans()->{$type};
    }
    #Setting the auth
    my $auth;
	if ($self->auth() ne "") {
		$auth = $self->auth();	
	}
    #Getting the data out of the workspace
    my $output;
    if ($ref =~ m/(.+)\/([^\/]+)$/) {
		my $id = $2;
		my $ws = $1;
		if ($ws eq "kbase" && $id eq "default" && $type eq "Mapping") {
			$id = "default-mapping";
		}
		$output = $self->workspace()->get_object({
			id => $id,
			workspace => $ws,
			type => $type,
			auth => $auth
		});
	} else {
		$output = $self->workspace()->get_object_by_ref({
			reference => $ref
		});
	}
	#Checking if object successfully retreived
	if (!defined($output) || !defined($output->{data}) || !defined($output->{metadata})) {
		my $msg = "Unable to retrieve object:".$type."/".$ref;
		ModelSEED::utilities::error($msg);
	}
    #Instantiating object
    my $object = $output->{data};
    if (defined($class) && $dataOnly == 0) {
    	$object = $class->new($object);
    	if ($type ne "Media") {
    		$object->parent($self);
    	}
    	if ($type eq "PROMModel") {
    		$object->uuid($output->{metadata}->[8]);
    	}
    	$object->uuid($ref);
    }
    #Setting workspace data in object
    if (defined($output)) {
		$object->{_kbaseWSMeta}->{wsid} = $output->{metadata}->[0];
		$object->{_kbaseWSMeta}->{ws} = $output->{metadata}->[7];
		$object->{_kbaseWSMeta}->{wsinst} = $output->{metadata}->[3];
		$object->{_kbaseWSMeta}->{wsref} = $output->{metadata}->[8];
		$object->{_kbaseWSMeta}->{wsmeta} = $output->{metadata};
		$object->{_msStoreID} = $type."/".$output->{metadata}->[7]."/".$output->{metadata}->[0];
		$object->{_msStoreRef} = $type."/".$output->{metadata}->[8];
	}
    #Adding object to cache
    if ($type ne "Media" && $dataOnly == 0) {
    	$self->cache()->{$type}->{$ref} = $object;
    }
    if ($type eq "Model" && !defined($object->annotation_uuid())) {
    	$object->annotation_uuid("B4159688-E9E9-11E2-87AF-43F64331C093");
    }
    return $object;
}

sub get_objects {
	my ($self, $type, $refs,$dataOnly) = @_;
    if (!defined($dataOnly)) {
    	$dataOnly = 0;
    }
    my $output = [];
    #If the object is cached, returning the cached object
    my $finalrefs = [];
    my $refindecies = {};
    if ($dataOnly == 0) {
	    for (my $i=0; $i < @{$refs}; $i++) {
	    	if (defined($self->cache()->{$type}->{$refs->[$i]})) {
	    		$output->[$i] = $self->cache()->{$type}->{$refs->[$i]};
	    	} else {
	    		push(@{$finalrefs},$refs->[$i]);
	    		$refindecies->{$refs->[$i]} = $i;
	    	}
	    }
    } else {
    	for (my $i=0; $i < @{$refs}; $i++) {
    		$refindecies->{$refs->[$i]} = $i;
    	}
    	$finalrefs = $refs;
    }
    #If this is a ModelSEED type, we identify the class and translate to a workspace type
    my $class;
    if (defined($self->_mstypetrans()->{$type})) {
    	$class = "ModelSEED::MS::".$type;
    	$type = $self->_mstypetrans()->{$type};
    } elsif (defined($self->_wstypetrans()->{$type})) {
    	$class = "ModelSEED::MS::".$self->_wstypetrans()->{$type};
    }
    #Setting the auth
    my $auth;
	if ($self->auth() ne "") {
		$auth = $self->auth();	
	}
    #Getting the data out of the workspace
    my $input = {
    	ids => [],
    	types => [],
    	workspaces => [],
		auth => $auth
    };
    for (my $i=0; $i < @{$finalrefs}; $i++) {
    	my $ref = $finalrefs->[$i];
    	if ($ref =~ m/(.+)\/([^\/]+)$/) {
			push(@{$input->{ids}},$2);
			push(@{$input->{workspaces}},$1);
			push(@{$input->{types}},$type);
		} else {
			push(@{$input->{ids}},$ref);
			push(@{$input->{workspaces}},"NO_WORKSPACE");
			push(@{$input->{types}},$type);
		}
    }
    my $objs = $self->workspace()->get_objects($input);
    if (!defined($objs)) {
		ModelSEED::utilities::error("Unable to retrieve objects!");
    }
    for (my $i=0; $i < @{$objs}; $i++) {
    	$output->[$refindecies->{$refs->[$i]}] = $objs->[$i]->{data};
    	if (defined($class) && $dataOnly == 0) {
	    	$output->[$refindecies->{$refs->[$i]}] = $class->new($output->[$refindecies->{$refs->[$i]}]);
	    	if ($type ne "Media") {
	    		$output->[$refindecies->{$refs->[$i]}]->parent($self);
	    	}
	    	if ($type eq "PROMModel") {
	    		$output->[$refindecies->{$refs->[$i]}]->uuid($objs->[$i]->{metadata}->[8]);
	    	}
	    	$output->[$refindecies->{$refs->[$i]}]->uuid($refs->[$i]);
	    }
	    if (defined($objs->[$i]->{metadata})) {
			$output->[$refindecies->{$refs->[$i]}]->{_kbaseWSMeta}->{wsid} = $objs->[$i]->{metadata}->[0];
			$output->[$refindecies->{$refs->[$i]}]->{_kbaseWSMeta}->{ws} = $objs->[$i]->{metadata}->[7];
			$output->[$refindecies->{$refs->[$i]}]->{_kbaseWSMeta}->{wsinst} = $objs->[$i]->{metadata}->[3];
			$output->[$refindecies->{$refs->[$i]}]->{_kbaseWSMeta}->{wsref} = $objs->[$i]->{metadata}->[8];
			$output->[$refindecies->{$refs->[$i]}]->{_kbaseWSMeta}->{wsmeta} = $objs->[$i]->{metadata};
			$output->[$refindecies->{$refs->[$i]}]->{_msStoreID} = $type."/".$objs->[$i]->{metadata}->[7]."/".$objs->[$i]->{metadata}->[0];
			$output->[$refindecies->{$refs->[$i]}]->{_msStoreRef} = $type."/".$objs->[$i]->{metadata}->[8];
		}
    }
    #Adding object to cache
    if ($type ne "Media" && $dataOnly == 0) {
    	for (my $i=0; $i < @{$refs}; $i++) {
	    	$self->cache()->{$type}->{$refs->[$i]} = $output->[$i];
	    }
    }
    return $output;
}

sub save_object {
    my ($self, $ref, $object, $config) = @_;
    #TODO
}

no Moose;
__PACKAGE__->meta->make_immutable;
1;
