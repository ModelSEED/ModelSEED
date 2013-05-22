package ModelSEED::App::bio::Command::printdbfiles;
use strict;
use common::sense;
use ModelSEED::App::bio;
use base 'ModelSEED::App::BioBaseCommand';
use Class::Autouse qw(
    ModelSEED::MS::Factories::ExchangeFormatFactory
    ModelSEED::MS::Model
);
use ModelSEED::utilities;
sub abstract { return "Prints FBA database files used by the MFAToolkit" }
sub usage_desc { return "bio printdbfiles [ biochemistry id ] [options]"; }
sub options {
    return (
        ["directory|d", "Print files into this directory"],
    );
}
sub sub_execute {
    my ($self, $opts, $args,$bio) = @_;
    my $dbfiles_args = { forceprint => 1 };
    if (defined $opts->{directory}) {
        $dbfiles_args->{directory} = $opts->{directory};
    }
    $bio->printDBFiles($dbfiles_args);
}
1;
