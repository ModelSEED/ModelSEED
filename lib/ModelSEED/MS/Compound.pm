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
use ModelSEED::utilities;
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
	if (length($formula) == 0) {
		$atoms->{error} = "No formula";
	} else {
		$formula =~ s/([A-Z][a-z]*)/|$1/g;
		$formula =~ s/([\d]+)/:$1/g;
		my $array = [split(/\|/,$formula)];
		for (my $i=1; $i < @{$array}; $i++) {
			my $arrayTwo = [split(/:/,$array->[$i])];
			if (defined($arrayTwo->[1])) {
				if ($arrayTwo->[1] !~ m/^\d+$/) {
					$atoms->{error} = "Invalid formula:".$self->formula();
				}
				$atoms->{$arrayTwo->[0]} = $arrayTwo->[1];
			} else {
				$atoms->{$arrayTwo->[0]} = 1;
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
	$InName =~ s/’//g;
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
