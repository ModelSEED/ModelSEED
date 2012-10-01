package ModelSEED::App::bio::Command::cmddemo;
use strict;
use common::sense;
use base 'ModelSEED::App::BaseCommand';
use Class::Autouse qw(
	ModelSEED::MS::Factories::TableFileFactory
);
sub abstract { return "Demonstration of command inheritance" }
sub usage_desc { return "bio cmddemo [< biochemistry | biochemistry] [options]"; }
sub options {
    return (
        ["saveas|a:s", "New alias for altered biochemistry"],
        ["namespace|n:s", "Name space for aliases added"],
    );
}

sub sub_execute {
    my ($self, $opts, $args) = @_;
    ModelSEED::utilities::VERBOSEMSG("Testing that verbose works!");
	return;
}

1;
