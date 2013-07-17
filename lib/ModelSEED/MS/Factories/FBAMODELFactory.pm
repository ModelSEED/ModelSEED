########################################################################
# ModelSEED::MS::Factories::FBAMODELFactory
# 
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location:
#   Mathematics and Computer Science Division, Argonne National Lab;
#   Computation Institute, University of Chicago
#
# Date of module creation: 2012-06-03
########################################################################

=head1 ModelSEED::MS::Factories::FBAMDOELFactory

A Factory that uses an FBAMODEL server to pull construct a model.

=head2 Methods

=head3 listAvailableModels

    \@ids = $fact->listAvailableModels;

Return an arrayref of model IDs.

=head3 createModel

    $model = $fact->createModel(\%config);

Construct a L<ModelSEED::MS::Model> object. Config is
a hash ref that accepts the following:

=over 4

=item id

The string ID of a model to import. Required.

=item annotation

A L<ModelSEED::MS::Annotation> object. Required.

=back

=cut

package ModelSEED::MS::Factories::FBAMODELFactory;
use ModelSEED::Client::FBAMODEL;
use ModelSEED::utilities;
use Class::Autouse qw(
    ModelSEED::Auth::Factory
    ModelSEED::Auth
    ModelSEED::MS::Model
    ModelSEED::MS::Biomass
);
use Try::Tiny;
use Moose;
use namespace::autoclean;

has auth => ( is => 'ro', isa => "ModelSEED::Auth", required => 1);
has store => ( is => 'ro', isa => "ModelSEED::Store", required => 1);
has client => ( is => 'ro', isa => "ModelSEED::Client::FBAMODEL", lazy => 1, builder => '_build_client');
has auth_config => ( is => 'ro', isa => 'HashRef', lazy => 1, builder => '_build_auth_config');

sub listAvailableModels {
    my ($self) = @_;
    my $ids = $self->client->get_model_id_list($self->auth_config);
    return $ids;
}

sub createModel {
    my $self = shift;
    my $args = ModelSEED::utilities::args(["id", "annotation"], { verbose => 0 }, @_);
    # Get basic model data
    my $data;
    my $config = \%{$self->auth_config};
    $config->{id} = $args->{id};
    print "Getting model metadata...\n" if($args->{verbose});
    try {
        $data = $self->client->get_model_stats($config);
    };
    if(!defined($data) || !defined($data->{data}) || @{$data->{data}} == 0) {
        die "Unable to find model with id ". $args->{id}."\n";
    }
    my $model_data;
    foreach my $entry (@{$data->{data}}) {
        if($entry->{id} eq $args->{id}) {
            $model_data = $entry;
            last;
        }
    }
    print "Loading linked objects...\n" if($args->{verbose});
    my $annotation = $args->{annotation};
    my $genomes = $annotation->genomes;
    my $genome_id = $genomes->[0]->id;
    my $mapping      = $annotation->mapping;
    my $biochemistry = $mapping->biochemistry;
    my $model = $self->store->create("Model", {
		locked => 0,
		public => $model_data->{public} || 0,
		id => $model_data->{id},
		name => $model_data->{name},
		type => "Singlegenome",
		mapping_uuid => $mapping->uuid,
		biochemistry_uuid => $biochemistry->uuid,
		annotation_uuid => $annotation->uuid,
    });
    print "Getting model reactions...\n" if($args->{verbose});
    $config = \%{$self->auth_config};
    $config->{id} = $args->{id};
    my $rxn_obj = $self->client->get_model_reaction_data($config);
    unless(defined($rxn_obj) && defined($rxn_obj->{data})) {
        die "Error in getting reaction data for " . $args->{id} . "\n";
    }
    my $rxns = $rxn_obj->{data};
    my $biomassIndex = 0;
    foreach my $rxn (@$rxns) {
        my $id = $rxn->{DATABASE}->[0];
        if ( $id =~ m/bio\d+/ ) {

	    if ($args->{id} eq 'iSO783') {
		# SO: change scientific notation to decimal
		$rxn->{EQUATION}->[0] =~ s/5e-05/.00005/g;
		$rxn->{EQUATION}->[0] =~ s/6e-06/.000006/g;
		$rxn->{EQUATION}->[0] =~ s/6\.9e-05/.000069/g;
		$rxn->{EQUATION}->[0] =~ s/3e-06/.000003/g;
		# SO: get rid of acyl-glycerophosphoethanolamine and acyl-glycerophosphoglycerol
		# from the biomass because they are products of phospholipases and couldn't get
		# them to grow on BU0_AF
		$rxn->{EQUATION}->[0] =~ s/0\.010152 cpd15647 \+ //g;
		$rxn->{EQUATION}->[0] =~ s/0\.000421 cpd15648 \+ //g;
		# keep peptidoglycan inside the cell
		$rxn->{EQUATION}->[0] =~ s/\[e\]//g;
	    }
	    elsif ($args->{id} eq 'iJR904') {
		$rxn->{EQUATION}->[0] = "0.050000 cpd00345 + 0.000050 cpd00022 + 0.488000 cpd00035 + 0.001000 cpd00018 + 0.281000 cpd00051 + 0.229000 cpd00132 + 0.229000 cpd00041 + 0.000129 cpd15650 + 0.000006 cpd00010 + 0.126000 cpd00052 + 0.087000 cpd00084 + 0.024700 cpd00115 + 0.025400 cpd00356 + 0.025400 cpd00241 + 0.024700 cpd00357 + 0.000010 cpd00015 + 0.250000 cpd00053 + 0.250000 cpd00023 + 0.582000 cpd00033 + 0.203000 cpd00038 + 0.090000 cpd00119 + 0.276000 cpd00322 + 0.428000 cpd00107 + 0.008400 cpd15652 + 0.326000 cpd00039 + 0.146000 cpd00060 + 0.002150 cpd00003 + 0.000050 cpd00004 + 0.000130 cpd00006 + 0.000400 cpd00005 + 0.001935 cpd15653 + 0.027600 cpd15654 + 0.000464 cpd15655 + 0.176000 cpd00066 + 0.210000 cpd00129 + 0.000052 cpd15657 + 0.035000 cpd00118 + 0.205000 cpd00054 + 0.007000 cpd00264 + 0.000003 cpd00078 + 0.241000 cpd00161 + 0.054000 cpd00065 + 0.131000 cpd00069 + 0.003000 cpd00026 + 0.136000 cpd00062 + 0.402000 cpd00156 => 45.5608 cpd00008 + 45.56035 cpd00067 + 45.5628 cpd00009 + 0.7302 cpd00012";
	    }

            # Add as a biomass equation
	    my $bioobj = $model->add("biomasses", ModelSEED::MS::Biomass->new({
		name => sprintf("bio%05d", $biomassIndex),
									      }));
            $bioobj->loadFromEquation({
                equation => $rxn->{EQUATION}->[0],
                aliasType => "ModelSEED"
				      });
	    $biomassIndex++;
	} else {
	    my $rxnObj = $biochemistry->getObjectByAlias(
                "reactions", 
                $id,
                "ModelSEED"
		);
	    my $direction = $rxn->{DIRECTION}->[0];
            if($direction eq "=>") {
                $direction = ">";
            } elsif ($direction eq "<=") {
                $direction = "<";
            } else {
                $direction = "=";
            }
            if(!defined($rxnObj)) {
                warn "Could not find rxn_instance for $id!\n";
                next;
            }
	    my @pegs;
	    # SO: pegs are separated by AND and OR; for now just collect all the pegs
	    if ($args->{id} eq 'iSO783' || $args->{id} eq 'iJR904') {
		foreach my $peg (@{$rxn->{PEGS}}) {
		    while ($peg =~ /(peg\.\d+)/g) {
			push @pegs, "fig|".$genome_id.".".$1;
		    }
		}

	    } else {
		foreach my $peg (@{$rxn->{PEGS}}) {
		    push @pegs, map { /^peg/ ? "fig|".$genome_id.".".$_ : $_} (split '\+', $peg);
		}
	    }
	    $model->addReactionToModel({
		reaction => $rxnObj,
		direction => $direction,
		gpr => \@pegs});
	}
	# SO: add reaction for transporters so it can grow on BU0_AF without using biosynthetic genes
	# which appear to be turned off based on gxp data
	if ($args->{id} eq 'iSO783') {
	    foreach my $id (qw//) {
		my $rxnObj = $biochemistry->getObjectByAlias(
		    "reactions", 
		    $id,
		    "ModelSEED"
		    );
		$model->addReactionToModel({
		    reaction => $rxnObj,
		    direction => '=',
		    gpr => ['Manual']});
	    }
	}
    }
    return $model;
}

sub _build_client {
    return ModelSEED::Client::FBAMODEL->new();
}
sub _build_auth_config {
    my ($self) = @_;
    if($self->auth->isa("ModelSEED::Auth::Basic")) {
        return { user => $self->auth->username,
                 password => $self->auth->password,
               };
    } else {
        return {};
    }
}

sub _get_uuid_from_alias {
    my ($self, $ref) = @_;
    return unless(defined($ref));
    my $alias_objects = $self->store->get_aliases($ref);
    if(defined($alias_objects->[0])) {
        return $alias_objects->[0]->{uuid}
    } else {
        return;
    }
}

1;
