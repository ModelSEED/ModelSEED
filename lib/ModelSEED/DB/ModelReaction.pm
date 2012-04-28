package ModelSEED::DB::ModelReaction;

use strict;

use base qw(ModelSEED::DB::DB::Object::AutoBase2);

__PACKAGE__->meta->setup(
    table   => 'model_reactions',

    columns => [
        model_uuid             => { type => 'character', length => 36, not_null => 1 },
        reaction_uuid          => { type => 'character', length => 36, not_null => 1 },
        direction              => { type => 'character', length => 1 },
        transproton            => { type => 'scalar' },
        protons                => { type => 'scalar' },
        modelcompartment_uuid => { type => 'character', length => 36, not_null => 1 },
    ],

    primary_key_columns => [ 'model_uuid', 'reaction_uuid', 'modelcompartment_uuid' ],

    foreign_keys => [
        model => {
            class       => 'ModelSEED::DB::Model',
            key_columns => { model_uuid => 'uuid' },
        },

        model_compartment => {
            class       => 'ModelSEED::DB::ModelCompartment',
            key_columns => { modelcompartment_uuid => 'uuid' },
        },

        reaction => {
            class       => 'ModelSEED::DB::Reaction',
            key_columns => { reaction_uuid => 'uuid' },
        },
        
        rawGPR => {
            class       => 'ModelSEED::DB::ModelReactionRawGPR',
            key_columns => {
                model_uuid => 'model_uuid',
                reaction_uuid => 'reaction_uuid',
                modelcompartment_uuid => 'modelcompartment_uuid',
            },
        },
    ],
);

1;
