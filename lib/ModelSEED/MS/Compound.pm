########################################################################
# ModelSEED::MS::Reaction - This is the moose object corresponding to the Reaction object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-03-26T23:22:35
########################################################################
use strict;
use ModelSEED::MS::DB::Compound;
package ModelSEED::MS::Compound;
use ModelSEED::utilities qw( args );
use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::DB::Compound';
#***********************************************************************************************************
# ADDITIONAL ATTRIBUTES:
#***********************************************************************************************************
has mapped_uuid  => ( is => 'rw', isa => 'ModelSEED::uuid',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_build_mapped_uuid' );
has searchnames  => ( is => 'rw', isa => 'ArrayRef',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_build_searchnames' );

#***********************************************************************************************************
# BUILDERS:
#***********************************************************************************************************
sub _build_mapped_uuid {
	my ($self) = @_;
	return "00000000-0000-0000-0000-000000000000";
}
sub _build_searchnames {
	my ($self) = @_;
	my $hash = {$self->nameToSearchname($self->name()) => 1};
	my $names = $self->getAliases("name");
	foreach my $name (@{$names}) {
		$hash->{$self->nameToSearchname($name)} = 1;
	}
	return [keys(%{$hash})];
}

#***********************************************************************************************************
# CONSTANTS:
#***********************************************************************************************************

#***********************************************************************************************************
# FUNCTIONS:
#***********************************************************************************************************

=head3 addStructure

Definition:
	ModelSEED::MS::Structure = addStructure({
		data => string:structure data*
		type => string:type of structure*
		overwrite => 0/1(0)
	});
Description:
	Adds the specified structure to the compound
	
=cut

sub addStructure {
    my $self = shift;
    my $args = args(["data","type"], { overwrite => 0 }, @_);
	#Checking that parent exists and has linked BiochemistryStructures
	if (!defined($self->parent()) || !defined($self->parent()->biochemistrystructures())) {
		ModelSEED::utilities::ERROR("Cannot add structure to a compound with no accessible BiochemistryStructures object. Make sure you have a BiochemistryStructures object in the parent biochemistry.");
	}
	my $bs = $self->parent()->biochemistrystructures();
	#Checking if a structure of the same type already exists
	my $index = -1;
	if (defined($self->structure_uuids()->[0])) {
		my $structs = $self->structures();
		my $type = $args->{type};
		for (my $i=0; $i < @{$structs}; $i++) {
			if ($structs->[$i]->type() eq $args->{type}) {
				if ($args->{overwrite} == 1) {
					$index = $i;
					last;
				} else {
					ModelSEED::utilities::ERROR("Compound already has structure of type '$type'. Cannot overwrite without setting overwrite flag.");
				}
			}
		}
	}
	#Getting structure
	my $structure = $bs->getCreateStructure({
		data => $args->{data},
		type => $args->{type},
	});
	#Adding the structure
	if ($index == -1) {
		push(@{$self->structure_uuids()},$structure->uuid());
	} else {
		$self->structure_uuids()->[$index] = $structure->uuid();
	}
	$self->clear_structures();
	return $structure;
}

=head3 calculateAtomsFromFormula

Definition:
	{string:atom => int:count} = ModelSEED::MS::Reaction->calculateAtomsFromFormula();
Description:
	Determines the count of each atom type based on the formula

=cut

sub calculateAtomsFromFormula {
        my ($self) = @_;
	my $atoms = {};
	my $formula = $self->formula();
	if (length($formula) == 0 || $formula eq "noformula") {
		$atoms->{error} = "No formula";
	} else {
	    foreach my $component ( split(/\./,$formula) ){
		#remove problematic characters
		$component =~ s/\)n//g;
		$component =~ s/[\(\)]//g;
		$component =~ s/\*\d?//g;
		$component =~ s/([A-Z][a-z]*)/|$1/g;
		$component =~ s/([\d]+)/:$1/g;
		my $array = [split(/\|/,$component)];
		for (my $i=1; $i < @{$array}; $i++) {
			my $arrayTwo = [split(/:/,$array->[$i])];
			if (defined($arrayTwo->[1])) {
				if ($arrayTwo->[1] !~ m/^\d+$/) {
					$atoms->{error} = "Invalid formula:".$self->formula();
				}else{
				    $atoms->{$arrayTwo->[0]} += $arrayTwo->[1];
				}
			} else {
				$atoms->{$arrayTwo->[0]} += 1;
			}
		}
	    }
	}
	return $atoms;
}

#***********************************************************************************************************
# CLASS FUNCTIONS:
#***********************************************************************************************************

=head3 nameToSearchname

Definition:
	string:searchname = nameToSearchname(string:name);
Description:
	Converts input name into standard formated searchname

=cut

sub nameToSearchname {
	my ($self,$InName) = @_;
	if (!defined($InName) && !ref($self) && $self ne "ModelSEED::MS::Compound") {
		$InName = $self;
	}
	my $OriginalName = $InName;
	my $ending = "";
	if ($InName =~ m/-$/) {
		$ending = "-";
	}
	$InName = lc($InName);
	$InName =~ s/\s//g;
	$InName =~ s/,//g;
	$InName =~ s/-//g;
	$InName =~ s/_//g;
	$InName =~ s/\(//g;
	$InName =~ s/\)//g;
	$InName =~ s/\{//g;
	$InName =~ s/\}//g;
	$InName =~ s/\[//g;
	$InName =~ s/\]//g;
	$InName =~ s/\://g;
	$InName =~ s/�//g;
	$InName =~ s/'//g;
	$InName =~ s/\;//g;
	$InName .= $ending;
	$InName =~ s/icacid/ate/g;
	if($OriginalName =~ /^an? /){
		$InName =~ s/^an?(.*)$/$1/;
	}
	return $InName;
}

=head3 recognizeReference

Definition:
	string:formated ref = recognizeReference(string:rawref);
Description:
	Converts a raw reference into a fully formatted and typed reference

=cut

sub recognizeReference {
	my ($self,$reference) = @_;
	if (!defined($reference) && !ref($self) && $self ne "ModelSEED::MS::Compound") {
		$reference = $self;
	}
	if ($reference =~ m/^Compound\/[^\/]+\/[^\/]+$/) {
		return $reference;
	}
	if ($reference =~ m/^[^\/]+\/[^\/]+$/) {
		return "Compound/".$reference;
	}
	if ($reference =~ m/^Compound\/([^\/]+)$/) {
		$reference = $1;
	}
	my $type = "searchnames";
	if ($reference =~ m/[A-Fa-f0-9]{8}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{4}-[A-Fa-f0-9]{12}/) {
		$type = "uuid";
	} elsif ($reference =~ m/^cpd\d+$/) {
		$type = "ModelSEED";
	} elsif ($reference =~ m/^C\d+$/) {
		$type = "KEGG";
	}
	if ($type eq "searchnames") {
		$reference = ModelSEED::MS::Compound->nameToSearchname($reference);
	}
	return "Compound/".$type."/".$reference;
}

__PACKAGE__->meta->make_immutable;
1;
