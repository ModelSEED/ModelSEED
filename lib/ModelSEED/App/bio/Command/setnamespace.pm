package ModelSEED::App::bio::Command::setnamespace;
use strict;
use common::sense;
use ModelSEED::App::bio;
use base 'ModelSEED::App::BioBaseCommand';
use Class::Autouse qw(
    ModelSEED::MS::Factories::ExchangeFormatFactory
    ModelSEED::MS::Model
);
use ModelSEED::utilities qw( config error args verbose set_verbose translateArrayOptions);
sub abstract { return "Changes the default namespace of a biochemistry object for use when printing ids" };
sub usage_desc { return "bio setnamespace [ biochemistry id ] [namespace]"; }
sub options {
    return ();
}
sub sub_execute {
    my ($self, $opts, $args,$bio) = @_;
    $self->usage_error("Must specify a namespace to use") unless(defined($args->[0]));
    $bio->defaultNameSpace($args->[0]);
    $self->save_bio($bio);
}

1;
