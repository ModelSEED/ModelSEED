########################################################################
# ModelSEED::MooseDB::media - This is the moose object corresponding to the media object in the database
# Author: Christopher Henry
# Author email: chenry@mcs.anl.gov
# Author affiliation: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 11/6/2011
########################################################################
use strict;
use ModelSEED::utilities;
use ModelSEED::MS::MediaCompound;
package ModelSEED::MS::Media;
use Moose;
use Moose::Util::TypeConstraints;
use namespace::autoclean;
use DateTime;
use Data::UUID;

#Attributes
has uuid    => (is => 'rw', isa => 'Str', lazy => 1, builder => '_buildUUID');
has modDate => (is => 'rw', isa => 'Str', lazy => 1, builder => '_buildModDate');
has id      => (is => 'rw', isa => 'Str', default => '');
has locked  => (is => 'rw', isa => 'Int', default => 0);
has name    => (is => 'rw', isa => 'Str', default => '');
has type    => (is => 'rw', isa => 'Str', default => '');

#Subobjects
has media_compounds => (
    is      => 'rw',
    isa     => 'ArrayRef|ArrayRef[ModelSEED::MS::MediaCompound]',
    default => sub { [] }
);

#Constants
has 'dbAttributes' => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    builder => '_buildDbAttributes'
);
has _type => (is => 'ro', isa => 'Str', default => 'Media');

sub BUILDARGS {
    my ($self, $params) = @_;
    delete $params->{type};
    my $attr = $params->{attributes};
    my $rels = $params->{relationships};
    my $bio  = $params->{biochemistry};
    delete $params->{biochemistry};
    if (defined($attr)) {
        map { $params->{$_} = $attr->{$_} }
            grep { defined($attr->{$_}) } keys %$attr;
        delete $params->{attributes};
    }
    if (defined($rels)) {
        foreach my $media_compound (@{$rels->{media_compounds}}) {
            $media_compound->{biochemistry} = $bio if (defined($bio));
            push(
                @{$params->{media_compounds}},
                ModelSEED::MS::MediaCompound->new($media_compound)
            );
        }
        delete $params->{relationships};
    }
    return $params;
}

sub minFluxes {
    return [map { $_->minflux } @{$_[0]->media_compounds}];
}

sub maxFluxes {
    return [map { $_->maxflux } @{$_[0]->media_compounds}];
}

sub compounds {
    return [map { $_->compound } @{$_[0]->media_compounds}];
}

sub compound_uuids {
    return [map { $_->compound_uuid } @{$_[0]->media_compounds}];
}

sub concentrations {
    return [map { $_->concentration } @{$_[0]->media_compounds}];
}

sub serializeToDB {
    my ($self) = @_;
	my $data = {};
	my $attributes = $self->dbAttributes();
	for (my $i=0; $i < @{$attributes}; $i++) {
		my $function = $attributes->[$i];
		$data->{attributes}->{$function} = $self->$function();
	}
	$data->{relationships}->{media_compounds} = [];
    foreach my $mediaCpd (@{$self->media_compounds}) {
		push(@{$data->{relationships}->{media_compounds}}, $mediaCpd->serializeToDB());
	}
	$data->{type} = $self->_type();
	return $data;
}

sub _buildDbAttributes {
    return [qw( uuid id name type modDate locked )];
}

sub printToFile {
	my ($self,$args) = @_;
	$args = ModelSEED::utilities::ARGS($args,[],{filename => undef});
	my $data = [
		"Attributes{",
		"id\t".$self->id(),
		"name\t".$self->name(),
		"type\t".$self->type(),
		"}",
		"Compounds{",
		"Compound ID\tConcentration\tMin flux\tMax flux"
	];
	my $compounds = $self->media_compounds();
	for (my $i=0; $i < @{$compounds}; $i++) {
		push(@{$data},$compounds->[$i]->compound()->id()."\t".$compounds->[$i]->concentration()."\t".$compounds->[$i]->minflux()."\t".$compounds->[$i]->maxflux());
	}
	push(@{$data},"}");
	if (defined($args->{filename})) {
		ModelSEED::utilities::PRINTFILE($args->{filename},$data);
	}
	return $data;
}

sub _buildUUID { return Data::UUID->new()->create_str(); }
sub _buildModDate { return DateTime->now()->datetime(); }

__PACKAGE__->meta->make_immutable;
1;
