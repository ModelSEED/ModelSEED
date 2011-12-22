package ModelSEED::DB::Roleset;

use strict;
use Data::UUID;
use DateTime;


use base qw(ModelSEED::DB::DB::Object::AutoBase2);

__PACKAGE__->meta->setup(
    table   => 'roleset',

    columns => [
        uuid       => { type => 'character', length => 36, not_null => 1 },
        modDate    => { type => 'datetime' },
        locked     => { type => 'integer' },
        public     => { type => 'integer' },
        id         => { type => 'varchar', length => 32 },
        name       => { type => 'varchar', length => 255 },
        searchname => { type => 'varchar', length => 255 },
        class      => { type => 'varchar', length => 255 },
        subclass   => { type => 'varchar', length => 255 },
        type       => { type => 'varchar', length => 32 },
    ],

    primary_key_columns => [ 'uuid' ],

    relationships => [
        roleset_role => {
            class      => 'ModelSEED::DB::RolesetRole',
            column_map => { uuid => 'roleset' },
            type       => 'one to many',
        },
        parents => {
            map_class  => 'ModelSEED::DB::RolesetParents',
            map_from   => 'parent_obj',
            map_to     => 'child_obj',
            type       => 'many to many',
        },
        children => {
            map_class  => 'ModelSEED::DB::RolesetParents',
            map_from   => 'child_obj',
            map_to     => 'parent_obj',
            type       => 'many to many',
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

