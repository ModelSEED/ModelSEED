########################################################################
# ModelSEED::MS::ModelReaction - This is the moose object corresponding to the ModelReaction object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-03-26T23:22:35
########################################################################
use strict;
use ModelSEED::MS::DB::ModelReaction;
package ModelSEED::MS::ModelReaction;
use Moose;
use ModelSEED::utilities;
use namespace::autoclean;
extends 'ModelSEED::MS::DB::ModelReaction';
#***********************************************************************************************************
# ADDITIONAL ATTRIBUTES:
#***********************************************************************************************************
has equation => ( is => 'rw', isa => 'Str',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildequation' );
has definition => ( is => 'rw', isa => 'Str',printOrder => '3', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_builddefinition' );
has name => ( is => 'rw', isa => 'Str',printOrder => '2', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildname' );
has abbreviation => ( is => 'rw', isa => 'Str',printOrder => '2', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildabbreviation' );
has modelCompartmentLabel => ( is => 'rw', isa => 'Str',printOrder => '4', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildmodelCompartmentLabel' );
has gprString => ( is => 'rw', isa => 'Str',printOrder => '6', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildgprString' );
has exchangeGPRString => ( is => 'rw', isa => 'Str',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildexchangeGPRString' );
has id => ( is => 'rw', isa => 'Str',printOrder => '1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildid' );
has missingStructure => ( is => 'rw', isa => 'Bool',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildmissingStructure' );
has biomassTransporter => ( is => 'rw', isa => 'Bool',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildbiomassTransporter' );
has isTransporter => ( is => 'rw', isa => 'Bool',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildisTransporter' );
has mapped_uuid  => ( is => 'rw', isa => 'ModelSEED::uuid',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildmapped_uuid' );
has translatedDirection  => ( is => 'rw', isa => 'Str',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildtranslatedDirection' );
has featureIDs  => ( is => 'rw', isa => 'ArrayRef',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildfeatureIDs' );
has featureUUIDs  => ( is => 'rw', isa => 'ArrayRef',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildfeatureUUIDs' );

#***********************************************************************************************************
# BUILDERS:
#***********************************************************************************************************
sub _buildid {
	my ($self) = @_;
	return $self->reaction()->id()."_".$self->modelCompartmentLabel();
}
sub _buildname {
	my ($self) = @_;
	return $self->reaction->name()."_".$self->modelCompartmentLabel();
}
sub _buildabbreviation {
	my ($self) = @_;
	return $self->reaction->abbreviation()."_".$self->modelCompartmentLabel();
}
sub _builddefinition {
	my ($self) = @_;
	my $reactants = "";
	my $products = "";
	my $rgts = $self->modelReactionReagents();
	for (my $i=0; $i < @{$rgts}; $i++) {
		my $rgt = $rgts->[$i];
		if ($rgt->coefficient() < 0) {
			my $coef = -1*$rgt->coefficient();
			if (length($reactants) > 0) {
				$reactants .= " + ";	
			}
			if ($coef ne "1") {
				$reactants .= "(".$coef.")";
			}
			$reactants .= $rgt->modelcompound()->compound()->name()."[".$rgt->modelcompound()->modelCompartmentLabel()."]";
		} else {
			if (length($products) > 0) {
				$products .= " + ";	
			}
			if ($rgt->coefficient() ne "1") {
				$products .= "(".$rgt->coefficient().")";
			}
			$products .= $rgt->modelcompound()->compound()->name()."[".$rgt->modelcompound()->modelCompartmentLabel()."]";
		}
		
	}
	$reactants .= " ".$self->translatedDirection()." ";
	return $reactants.$products;
}
sub _buildequation {
	my ($self) = @_;
	my $reactants = "";
	my $products = "";
	my $rgts = $self->modelReactionReagents();
	for (my $i=0; $i < @{$rgts}; $i++) {
		my $rgt = $rgts->[$i];
		if ($rgt->coefficient() < 0) {
			my $coef = -1*$rgt->coefficient();
			if (length($reactants) > 0) {
				$reactants .= " + ";	
			}
			if ($coef ne "1") {
				$reactants .= "(".$coef.")";
			}
			$reactants .= $rgt->modelcompound()->id();
		} else {
			if (length($products) > 0) {
				$products .= " + ";	
			}
			if ($rgt->coefficient() ne "1") {
				$products .= "(".$rgt->coefficient().")";
			}
			$products .= $rgt->modelcompound()->id();
		}
	}
	$reactants .= " ".$self->translatedDirection()." ";
	return $reactants.$products;
}
sub _buildmodelCompartmentLabel {
	my ($self) = @_;
	return $self->modelcompartment()->label();
}
sub _buildgprString {
	my ($self) = @_;
	my $gpr = "";
	foreach my $protein (@{$self->modelReactionProteins()}) {
		if (length($gpr) > 0) {
			$gpr .= " or ";	
		}
		$gpr .= $protein->gprString();
	}
	if (@{$self->modelReactionProteins()} > 1) {
		$gpr = "(".$gpr.")";	
	}
	if (length($gpr) == 0) {
		$gpr = "Unknown";
	}
	return $gpr;
}
sub _buildexchangeGPRString {
	my ($self) = @_;
	my $gpr = "MSGPR{";
	foreach my $protein (@{$self->modelReactionProteins()}) {
		if (length($gpr) > 6) {
			$gpr .= "/";	
		}
		$gpr .= $protein->exchangeGPRString();
	}
	$gpr .= "}";
	return $gpr;
}
sub _buildmissingStructure {
	my ($self) = @_;
	my $rgts = $self->modelReactionReagents();
	for (my $i=0; $i < @{$rgts}; $i++) {
		my $rgt = $rgts->[$i];
		if (@{$rgt->modelcompound()->compound()->structures()} == 0) {
			return 1;	
		}
	}
	return 0;
}
sub _buildbiomassTransporter {
	my ($self) = @_;
	my $rgts = $self->modelReactionReagents();
	for (my $i=0; $i < @{$rgts}; $i++) {
		my $rgt = $rgts->[$i];
		if ($rgt->modelcompound()->isBiomassCompound() == 1) {
			for (my $j=$i+1; $j < @{$rgts}; $j++) {
				my $rgtc = $rgts->[$j];
				if ($rgt->modelcompound()->compound_uuid() eq $rgtc->modelcompound()->compound_uuid()) {
					if ($rgt->modelcompound()->modelcompartment_uuid() ne $rgtc->modelcompound()->modelcompartment_uuid()) {
						return 1;
					}
				}
			}
		}
	}
	return 0;
}
sub _buildisTransporter {
	my ($self) = @_;
	my $rgts = $self->modelReactionReagents();
	my $initrgt = $rgts->[0];
	for (my $i=1; $i < @{$rgts}; $i++) {
		my $rgt = $rgts->[$i];
		if ($rgt->modelcompound()->modelcompartment_uuid() ne $initrgt->modelcompound()->modelcompartment_uuid()) {
			return 1;	
		}
	}
	return 0;
}
sub _buildmapped_uuid {
	my ($self) = @_;
	return "00000000-0000-0000-0000-000000000000";
}
sub _buildtranslatedDirection {
	my ($self) = @_;
	if ($self->direction() eq "=") {
		return "<=>";	
	} elsif ($self->direction() eq ">") {
		return "=>";
	} elsif ($self->direction() eq "<") {
		return "<=";
	}
	return $self->direction();
}
sub _buildfeatureIDs {
	my ($self) = @_;
	my $featureHash = {};
	foreach my $protein (@{$self->modelReactionProteins()}) {
		foreach my $subunit (@{$protein->modelReactionProteinSubunits()}) {
			foreach my $gene (@{$subunit->modelReactionProteinSubunitGenes()}) {
				$featureHash->{$gene->feature()->id()} = 1;
			}
		}
	}
	return [keys(%{$featureHash})];
}
sub _buildfeatureUUIDs {
	my ($self) = @_;
	my $featureHash = {};
	foreach my $protein (@{$self->modelReactionProteins()}) {
		foreach my $subunit (@{$protein->modelReactionProteinSubunits()}) {
			foreach my $gene (@{$subunit->modelReactionProteinSubunitGenes()}) {
				$featureHash->{$gene->feature()->uuid()} = 1;
			}
		}
	}
	return [keys(%{$featureHash})];
}

#***********************************************************************************************************
# CONSTANTS:
#***********************************************************************************************************

#***********************************************************************************************************
# FUNCTIONS:
#***********************************************************************************************************

=head3 addReagentToReaction
Definition:
	ModelSEED::MS::Model = ModelSEED::MS::Model->addReagentToReaction({
		coefficient => REQUIRED,
		modelcompound_uuid => REQUIRED
	});
Description:
	Add a new ModelCompound object to the ModelReaction if the ModelCompound is not already in the reaction

=cut

sub addReagentToReaction {
    my $self = shift;
    my $args = args(["coefficient","modelcompound_uuid"],{}, @_);
	my $rgts = $self->modelReactionReagents();
	for (my $i=0; $i < @{$rgts}; $i++) {
		if ($rgts->[$i]->modelcompound_uuid() eq $args->{modelcompound_uuid}) {
			return $self->modelReactionReagents()->[$i];
		}
	}
	my $mdlrxnrgt = $self->add("modelReactionReagents",{
		coefficient => $args->{coefficient},
		modelcompound_uuid => $args->{modelcompound_uuid}
	});
	return $mdlrxnrgt;
}

=head3 addModelReactionProtein
Definition:
	ModelSEED::MS::Model = ModelSEED::MS::Model->addModelReactionProtein({
		proteinDataTree => REQUIRED:{},
		complex_uuid => REQUIRED:ModelSEED::uuid
	});
Description:
	Adds a new protein to the reaction based on the input data tree

=cut

sub addModelReactionProtein {
    my $self = shift;
    my $args = args(["proteinDataTree","complex_uuid"], {}, @_);
	my $prots = $self->modelReactionProteins();
	for (my $i=0; $i < @{$prots}; $i++) {
		if ($prots->[$i]->complex_uuid() eq $args->{complex_uuid}) {
			return $prots->[$i];
		}
	}
	my $protdata = {complex_uuid => $args->{complex_uuid}};
	if (defined($args->{proteinDataTree}->{note})) {
		$protdata->{note} = $args->{proteinDataTree}->{note};
	}
	if (defined($args->{proteinDataTree}->{subunits})) {
		my $subunitData;
		foreach my $subunit (keys(%{$args->{proteinDataTree}->{subunits}})) {
			my $data = {
				triggering => $args->{proteinDataTree}->{subunits}->{$subunit}->{triggering},
				optional => $args->{proteinDataTree}->{subunits}->{$subunit}->{optional},
				role_uuid => $subunit
			};
			if (defined($args->{proteinDataTree}->{subunits}->{$subunit}->{note})) {
				$data->{note} = $args->{proteinDataTree}->{subunits}->{$subunit}->{note};
			}
			if (defined($args->{proteinDataTree}->{subunits}->{$subunit}->{genes})) {
				my $genelist;
				foreach my $gene (keys(%{$args->{proteinDataTree}->{subunits}->{$subunit}->{genes}})) {
					push(@{$genelist},{
						feature_uuid => $gene
					});
				}
				$data->{modelReactionProteinSubunitGenes} = $genelist; 
			}
			push(@{$subunitData},$data);
		}
		$protdata->{modelReactionProteinSubunits} = $subunitData;
	}
	my $mdlrxnprot = $self->add("modelReactionProteins",$protdata);
	return $mdlrxnprot;
}

=head3 setGPRFromArray
Definition:
	ModelSEED::MS::Model = ModelSEED::MS::Model->setGPRFromArray({
		gpr => []
	});
Description:
	Sets the GPR of the reaction from three nested arrays

=cut

sub setGPRFromArray {
	my $self = shift;
    my $args = args(["gpr"],{}, @_);
	my $anno = $self->parent()->annotation();
	$self->modelReactionProteins([]);
	foreach my $prot (@{$self->modelReactionProteins()}) {
		$self->remove("modelReactionProteins",$prot);
	}
	for (my $i=0; $i < @{$args->{gpr}}; $i++) {
    	if (defined($args->{gpr}->[$i]) && ref($args->{gpr}->[$i]) eq "ARRAY") {
	    	my $prot = $self->add("modelReactionProteins",{
	    		complex_uuid => "00000000-0000-0000-0000-000000000000",
	    		note => "Manually specified GPR"
	    	});
	    	for (my $j=0; $j < @{$args->{gpr}->[$i]}; $j++) {
	    		if (defined($args->{gpr}->[$i]->[$j]) && ref($args->{gpr}->[$i]->[$j]) eq "ARRAY") {
		    		my $subunit = $prot->add("modelReactionProteinSubunits",{
			    		role_uuid => "00000000-0000-0000-0000-000000000000",
			    		triggering => 0,
			    		optional => 0,
			    		note => "Manually specified GPR"
			    	});
		    		for (my $k=0; $k < @{$args->{gpr}->[$i]->[$j]}; $k++) {
		    			if (defined($args->{gpr}->[$i]->[$j]->[$k])) {
		    				my $ftr = $anno->queryObject("features",{id => $args->{gpr}->[$i]->[$j]->[$k]});
		    				if (!defined($ftr)) {
		    					error("Could not find feature '".$args->{gpr}->[$i]->[$j]->[$k]."' in model annotation!");
							}
		    				$subunit->add("modelReactionProteinSubunitGenes",{
					    		feature_uuid => $ftr->uuid()
					    	});
		    			}
		    		}
	    		}
	    	}
    	}
    }
}

__PACKAGE__->meta->make_immutable;
1;
