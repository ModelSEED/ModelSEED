package ModelSEED::App::bio::Command::clonebio;
use strict;
use common::sense;
use ModelSEED::App::bio;
use base 'ModelSEED::App::BioBaseCommand';
use Class::Autouse qw(
    ModelSEED::MS::Factories::ExchangeFormatFactory
    ModelSEED::MS::Model
);
use ModelSEED::utilities qw( config error args verbose set_verbose translateArrayOptions);
sub abstract { return "Clone a biochemistry object, giving the copy a new name" }
sub usage_desc { return "bio clonebio [ biochemistry id ] name"; }
sub options {
    return ();
}
sub sub_execute {
    my ($self, $opts, $args,$bio) = @_;
    $self->usage_error("Must specify the name of the new biochemistry") unless(defined($args->[0]));
    $self->save_bio($bio);
}

1;
