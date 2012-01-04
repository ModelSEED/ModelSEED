package ModelSEED::DB::Compartment;

use strict;
use Data::UUID;
use DateTime;

use base qw(ModelSEED::DB::DB::Object::AutoBase2);

__PACKAGE__->meta->setup(
    table   => 'compartment',

    columns => [
        uuid    => { type => 'character', length => 36, not_null => 1 },
        modDate => { type => 'datetime' },
        id      => { type => 'varchar', length => 2 },
        name    => { type => 'varchar', length => 255 },
    ],

    primary_key_columns => [ 'uuid' ],

    relationships => [
        mapping_compartment => {
            class      => 'ModelSEED::DB::MappingCompartment',
            column_map => { uuid => 'compartment' },
            type       => 'one to many',
        },

        model_compartment => {
            class      => 'ModelSEED::DB::ModelCompartment',
            column_map => { uuid => 'compartment' },
            type       => 'one to many',
        },

        model_reaction => {
            class      => 'ModelSEED::DB::ModelReaction',
            column_map => { uuid => 'in' },
            type       => 'one to many',
        },

        model_reaction_objs => {
            class      => 'ModelSEED::DB::ModelReaction',
            column_map => { uuid => 'out' },
            type       => 'one to many',
        },

        reaction => {
            class      => 'ModelSEED::DB::Reaction',
            column_map => { uuid => 'defaultOUT' },
            type       => 'one to many',
        },

        reaction_complex => {
            class      => 'ModelSEED::DB::ReactionComplex',
            column_map => { uuid => 'in' },
            type       => 'one to many',
        },

        reaction_complex_objs => {
            class      => 'ModelSEED::DB::ReactionComplex',
            column_map => { uuid => 'out' },
            type       => 'one to many',
        },

        reaction_compound => {
            class      => 'ModelSEED::DB::ReactionCompound',
            column_map => { uuid => 'compartment' },
            type       => 'one to many',
        },

        reaction_objs => {
            class      => 'ModelSEED::DB::Reaction',
            column_map => { uuid => 'defaultIN' },
            type       => 'one to many',
        },
    ],
);

__PACKAGE__->meta->column('uuid')->add_trigger(
    deflate => sub {
        my $uuid = $_[0]->uuid;
        if(ref($uuid) && ref($uuid) eq 'Data::UUID') {
            return $uuid->to_string();
        } elsif($uuid) {
            return $uuid;
        } else {
            return Data::UUID->new()->create_str();
        }   
});

__PACKAGE__->meta->column('modDate')->add_trigger(
    deflate => sub {
        unless(defined($_[0]->modDate)) {
            return DateTime->now();
        }
});
1;

