########################################################################
# ModelSEED::MS::Biomass - This is the moose object corresponding to the Biomass object
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 2012-03-26T23:22:35
########################################################################
use strict;
use ModelSEED::MS::DB::Biomass;
package ModelSEED::MS::Biomass;

=head1 ModelSEED::MS::Biomass

=head2 METHODS

=head2 loadFromEquation

    $biomass->buildFromEquation(\%config);

Replaces the existing biomass object with one constructed from an
equation string. Config is a hash-ref with the following required parameters:

=over 4

=item equation

The equation string.


=item aliasType

The alias type to use for finding the appropriate
L<ModelSEED::MS::Compound> from the biochemistry
L<ModelSEED::MS::AliasSet> objects.

=back

=cut

use Moose;
use namespace::autoclean;
extends 'ModelSEED::MS::DB::Biomass';
has definition => ( is => 'rw', isa => 'Str',printOrder => '2', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_build_definition' );
has equation => ( is => 'rw', isa => 'Str',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_build_equation' );
has equationCode => ( is => 'rw', isa => 'Str',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_build_equationcode' );
has mapped_uuid  => ( is => 'rw', isa => 'ModelSEED::uuid',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_build_mapped_uuid' );
has id  => ( is => 'rw', isa => 'Str',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_build_id' );
has index  => ( is => 'rw', isa => 'Int',printOrder => '-1', type => 'msdata', metaclass => 'Typed', lazy => 1, builder => '_build_index' );


# _equation_builder : builds a biomass equation from a configuration
# format : type of ids to use, default uuid
# hashed : boolean, if true, return a md5 sum of the string in place of the string
sub _equation_builder {
    my ($self,$args) = @_;
    $args = ModelSEED::utilities::ARGS($args,[],{
        format => "uuid",
        hashed => 0
    });
    my $cpds = $self->biomasscompounds();
    my $rgtHash;
    for (my $i=0; $i < @{$cpds}; $i++) {
        my $id = $cpds->[$i]->modelcompound()->compound()->uuid();
        if ($args->{format} eq "name" || $args->{format} eq "id") {
            my $function = $args->{format};
            $id = $cpds->[$i]->modelcompound()->compound()->$function();
        } elsif ($args->{format} ne "uuid") {
            $id = $cpds->[$i]->modelcompound()->compound()->getAlias($args->{format});
        }
        if (!defined($rgtHash->{$id}->{$cpds->[$i]->modelcompound()->modelcompartment()->label()})) {
            $rgtHash->{$id}->{$cpds->[$i]->modelcompound()->modelcompartment()->label()} = 0;
        }
        $rgtHash->{$id}->{$cpds->[$i]->modelcompound()->modelcompartment()->label()} += $cpds->[$i]->coefficient();
    }
    my $reactcode = "";
    my $productcode = "";
    my $sign = "=>";
    my $sortedCpd = [sort(keys(%{$rgtHash}))];
    for (my $i=0; $i < @{$sortedCpd}; $i++) {
        my $indecies = [sort(keys(%{$rgtHash->{$sortedCpd->[$i]}}))];
        for (my $j=0; $j < @{$indecies}; $j++) {
            my $compartment = "";
            if ($indecies->[$j] ne "c0") {
                $compartment = "[".$indecies->[$j]."]";
            }
            if ($rgtHash->{$sortedCpd->[$i]}->{$indecies->[$j]} < 0) {
                my $coef = -1*$rgtHash->{$sortedCpd->[$i]}->{$indecies->[$j]};
                if (length($reactcode) > 0) {
                    $reactcode .= "+";
                }
                $reactcode .= "(".$coef.")".$sortedCpd->[$i].$compartment;
            } elsif ($rgtHash->{$sortedCpd->[$i]}->{$indecies->[$j]} > 0) {
                if (length($productcode) > 0) {
                    $productcode .= "+";
                }
                $productcode .= "(".$rgtHash->{$sortedCpd->[$i]}->{$indecies->[$j]}.")".$sortedCpd->[$i].$compartment;
            }
        }
    }
    if ($args->{hashed} == 1) {
        return Digest::MD5::md5_hex($reactcode.$sign.$productcode);
    }
    return $reactcode.$sign.$productcode;
}

# _parse_equation_string :
#     given a string, return an arrayref with the following hashes:
#
#     {
#         compound    => string,
#         compartment => string,
#         coefficient => float,
#     }
# TODO : MS::Bimoass _parse_equation_string compartment isn't right ... need to capture [\S^\]]
# TODO : MS::Bimoass _parse_equation_string compound needs to capture more than alphanumeric
sub _parse_equation_string {
    my ($self, $string) = @_;
    my $reagents = [];
    my @TempArray = split(/\s/, $string);
    my $CurrentlyOnReactants = 1;
    my $coefficient = 1;
    for (my $i = 0; $i < @TempArray; $i++) {
        # Coefficient strings (123.4) or 123.4
        if ($TempArray[$i] =~ m/^\(([\.\d]+)\)$/ ||
            $TempArray[$i] =~ m/^([\.\d]+)$/ ) {
            $coefficient = $1;
        # reactant strings are anything else
        } elsif ( $TempArray[$i] =~ m/(^[a-zA-Z0-9]+)/ ) {
            $coefficient *= -1 if ($CurrentlyOnReactants);
            my $compound    = $1;
            my $compartment = "c0";
            # match compound[comparment]
            if ( $TempArray[$i] =~ m/^[a-zA-Z0-9]+\[([a-zA-Z]+)\]/ ) {
                $compartment = lc($1);
                if ( length($compartment) == 0 ) {
                    $compartment .= "0";
                }
            }
            # push onto array
            push(@$reagents, {
                compound => $compound,
                compartment => $compartment,
                coefficient => $coefficient,
            });
            # reset coefficient
            $coefficient = 1;
        # switch flag for reactant / product sign
        } elsif ($TempArray[$i] =~ m/=/) {
            $CurrentlyOnReactants = 0;
        }
    }
    return $reagents;
}

sub loadFromEquation {
    my ($self,$args) = @_;
    $args = ModelSEED::utilities::ARGS($args,["equation","aliasType"],{});
    my $mod = $self->parent();
    my $bio = $self->parent()->biochemistry();
    my $reagentHashes = $self->_parse_equation_string($args->{equation});
    foreach my $reagent (@$reagentHashes) {
        my $compound    = $reagent->{compound};
        my $compartment = $reagent->{compartment};
        my $coefficient = $reagent->{coefficient};
        my $comp = $mod->queryObject("modelcompartments",{label => $compartment});
        if (!defined($comp)) {
            ModelSEED::utilities::USEWARNING("Unrecognized compartment '".$compartment."' used in biomass equation!");
            my $biocompid = substr($compartment,0,1);
            my $compindex = substr($compartment,1,1);
            my $biocomp = $bio->queryObject("compartments",{id => $biocompid});
            if (!defined($biocomp)) {
                $biocomp = $bio->add("compartments",{
                    locked => "0",
                    id => $biocompid,
                    name => $biocompid,
                    hierarchy => 3
                });
            }
            $comp = $mod->add("modelcompartments",{
                locked => "0",
                compartment_uuid => $biocomp->uuid,
                compartmentIndex => $compindex,
                label => $compartment,
                pH => 7,
                potential => 0
            });
        }
        my $cpd;
        if ($args->{aliasType} eq "uuid" || $args->{aliasType} eq "name") {
            $cpd = $bio->queryObject("compounds",{$args->{aliasType} => $compound});
        } else {
            $cpd = $bio->getObjectByAlias("compounds",$compound,$args->{aliasType});
        }
        if (!defined($cpd)) {
            ModelSEED::utilities::USEWARNING("Unrecognized compound '".$compound."' used in biomass equation!");
            $cpd = $bio->add("compounds",{
                locked => "0",
                name => $compound,
                abbreviation => $compound
            });
        }
        my $modcpd = $mod->queryObject("modelcompounds",{
            compound_uuid => $cpd->uuid(),
            modelcompartment_uuid => $comp->uuid()
        });
        if (!defined($modcpd)) {
            $modcpd = $mod->add("modelcompounds",{
                compound_uuid => $cpd->uuid(),
                charge => $cpd->defaultCharge(),
                formula => $cpd->formula(),
                modelcompartment_uuid => $comp->uuid()
            });
        }
        $self->add("biomasscompounds",{
            modelcompound_uuid => $modcpd->uuid(),
            coefficient => $coefficient,
        });
    }
}

sub _build_definition {
    my ($self) = @_;
    return $self->_equation_builder({format=>"name",hashed=>0});
}

sub _build_equation {
    my ($self) = @_;
    return $self->_equation_builder({format=>"id",hashed=>0});
}

sub _build_equationcode {
    my ($self,$args) = @_;
    return $self->_equation_builder({format=>"uuid",hashed=>1});
}

sub _build_mapped_uuid {
    my ($self) = @_;
    return "00000000-0000-0000-0000-000000000000";
}
sub _build_id {
    my ($self) = @_;
    my $prefix = "bio";
    return sprintf("${prefix}%05d", $self->index);
}

sub _build_index {
    my ($self) = @_;
    my $index = 1;
    if (defined($self->parent())) {
        my $biomasses = $self->parent->biomasses;
        map { $_->index($index); $index++ } @$biomasses;
    }
}

__PACKAGE__->meta->make_immutable;
1;
