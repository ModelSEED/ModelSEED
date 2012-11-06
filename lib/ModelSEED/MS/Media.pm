########################################################################
# ModelSEED::MS::Media - This is the moose object corresponding to the Media object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-03-26T23:22:35
########################################################################
use strict;
use ModelSEED::MS::DB::Media;
package ModelSEED::MS::Media;
use Moose;
use namespace::autoclean;
use ModelSEED::utilities qw( args verbose error );
extends 'ModelSEED::MS::DB::Media';
#***********************************************************************************************************
# ADDITIONAL ATTRIBUTES:
#***********************************************************************************************************
has compoundListString => ( is => 'rw', isa => 'Str',printOrder => '3', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_buildcompoundListString' );

#***********************************************************************************************************
# BUILDERS:
#***********************************************************************************************************
sub _buildcompoundListString {
	my ($self) = @_;
	my $compoundListString = "";
	my $mediacpds = $self->mediacompounds();
	for (my $i=0; $i < @{$mediacpds}; $i++) {
		if (length($compoundListString) > 0) {
			$compoundListString .= ";"	
		}
		my $cpd = $mediacpds->[$i];
		$compoundListString .= $cpd->compound()->name();
	}
	return $compoundListString;
}


#***********************************************************************************************************
# CONSTANTS:
#***********************************************************************************************************

#***********************************************************************************************************
# FUNCTIONS:
#***********************************************************************************************************

=head3 export

Definition:
	string = ModelSEED::MS::Media->export({
		format => readable/html/json/exchange
	});
Description:
	Exports media data to the specified format.

=cut

sub export {
    my $self = shift;
	my $args = args(["format"], {}, @_);
	if (lc($args->{format}) eq "exchange") {
		return $self->printExchange();
	} elsif (lc($args->{format}) eq "readable") {
		return $self->toReadableString();
	} elsif (lc($args->{format}) eq "html") {
		return $self->createHTML();
	} elsif (lc($args->{format}) eq "json") {
		return $self->toJSON({pp => 1});
	}
	error("Unrecognized type for export: ".$args->{format});
}

=head3 printExchange

Definition:
	string:Exchange format = ModelSEED::MS::Model->printExchange();
Description:
	Returns a string with the media

=cut

sub printExchange {
    my $self = shift;
	my $output = "Media{\n";
	$output .= "attributes(in\tname\tisDefined\tisMinimal\ttype){\n";
	$output .= $self->id()."\t".$self->name()."\t".$self->isDefined()."\t".$self->isMinimal()."\t".$self->type()."\n";
	$output .= "}\n";
	$output .= "compounds(id\tminFlux\tmaxFlux\tconcentration){\n";
	my $mediacpds = $self->mediacompounds();
	foreach my $cpd (@{$mediacpds}) {
		$output .= $cpd->compound()->id()."\t".$cpd->minFlux()."\t".$cpd->maxFlux()."\t".$cpd->concentration()."\n";
	}
	$output .= "}\n";
	$output .= "}\n";
	return $output;
}

__PACKAGE__->meta->make_immutable;
1;
