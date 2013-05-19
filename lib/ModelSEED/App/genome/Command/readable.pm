package ModelSEED::App::genome::Command::readable;
use strict;
use common::sense;
use ModelSEED::App::genome;
use base 'ModelSEED::App::GenomeBaseCommand';
sub abstract { return "Prints a readable format for the object" }
sub usage_desc { return "genome readable [genome id] [options]" }
sub options {
    return ();
}
sub sub_execute {
    my ($self, $opts, $args,$anno) = @_;
    print $anno->toReadableString();
}

1;
