package ModelSEED::DB::Media;

use strict;

use base qw(ModelSEED::DB::DB::Object::AutoBase2);

__PACKAGE__->meta->setup(
    table   => 'media',

    columns => [
        uuid    => { type => 'character', length => 36, not_null => 1 },
        modDate => { type => 'datetime' },
        locked  => { type => 'integer' },
        id      => { type => 'varchar', length => 32 },
        name    => { type => 'varchar', length => 255 },
        type    => { type => 'character', length => 1 },
    ],

    primary_key_columns => [ 'uuid' ],

    relationships => [
        biochemistry_media => {
            class      => 'ModelSEED::DB::BiochemistryMedia',
            column_map => { uuid => 'media_uuid' },
            type       => 'one to many',
        },

        media_compounds => {
            class      => 'ModelSEED::DB::MediaCompound',
            column_map => { uuid => 'media_uuid' },
            type      => 'one to many',
        },

        modelfbas => {
            class      => 'ModelSEED::DB::Modelfba',
            column_map => { uuid => 'media_uuid' },
            type       => 'one to many',
        },
    ],
);

1;

