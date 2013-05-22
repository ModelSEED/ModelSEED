package ModelSEED::App::mapping::Command::readable;
use strict;
use common::sense;
use ModelSEED::App::mapping;
use base 'ModelSEED::App::MappingBaseCommand';
sub abstract { return "Prints a readable format for the object" }
sub usage_desc { return "mapping readable [mapping id] [options]" }
sub options {
    return ();
}
sub sub_execute {
    my ($self, $opts, $args,$map) = @_;
    print $map->toReadableString;
}
1;
