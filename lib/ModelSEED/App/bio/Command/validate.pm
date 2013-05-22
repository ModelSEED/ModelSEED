package ModelSEED::App::bio::Command::validate;
use strict;
use common::sense;
use ModelSEED::App::bio;
use base 'ModelSEED::App::BioBaseCommand';
use Class::Autouse qw(
    ModelSEED::MS::Factories::ExchangeFormatFactory
    ModelSEED::MS::Model
);
use ModelSEED::utilities;
sub abstract { return "Validates the biochemistry data searching for inconsistencies" }
sub usage_desc { return "bio validate [ biochemistry id ] [options]"; }
sub opt_spec {
    return ();
}
sub sub_execute {
    my ($self, $opts, $args,$bio) = @_;
    my $errors = $bio->validate();
    if (@{$errors} == 0) {
    	print "Biochemistry validation complete. No errors found!";
    } else {
    	print "Biochemistry validation complete. ".@{$errors}." errors found:\n".join("\n",@{$errors});
    }
}

1;
