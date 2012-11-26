#!/usr/bin/perl 
use strict;
use warnings;
use ModelSEED::Store;
use ModelSEED::Auth::Factory;

my $auth  = ModelSEED::Auth::Factory->new->from_config;
my $store = ModelSEED::Store->new(auth => $auth);
my $map_ref = shift @ARGV;
my $bio_ref = shift @ARGV;

my $map   = $store->get_object($map_ref);
my $bio   = $store->get_object($bio_ref);
$map->biochemistry_uuid($bio->uuid);
$store->save_object($map_ref, $map);
