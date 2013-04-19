package ModelSEED::App::bio::Command::addmedia;
use strict;
use common::sense;
use ModelSEED::App::bio;
use base 'ModelSEED::App::BioBaseCommand';
use Class::Autouse qw(
    ModelSEED::MS::Factories::ExchangeFormatFactory
);
use ModelSEED::utilities qw( config error args verbose set_verbose translateArrayOptions);
sub abstract { return "Adds a specified media condition to the database"; }
sub usage_desc { return "bio addmedia [ biochemistry id ] [name] [compounds] [options]"; }
sub options {
    return (
        ["isdefined","Media is defined"],
        ["isminimal","Media is a minimal media"],
        ["type:s","Type of the media"],
        ["concentrations|n:s", "',' delimited array of concentrations"],
        ["namespace|n:s", "Namespace under which IDs will be added"],
    );
}
sub sub_execute {
    my ($self, $opts, $args,$bio) = @_;
    $self->usage_error("Must specify a name for the media") unless(defined($args->[0]));
    $self->usage_error("Must specify compounds in the media") unless(defined($args->[1]));
    my $data = {
    	name => $args->[0],
    	compounds => $args->[1]
    };
    foreach my $option (keys(%{$opts})) {
    	$data->{$option} = $opts->{$option};
    }
    my $factory = ModelSEED::MS::Factories::ExchangeFormatFactory->new();
    my $obj = $factory->createFromAPI("Media",$bio,$data);
    my $existingMedia = $bio->queryObject("media",{id => $obj->id()});
    if (defined($existingMedia)) {
    	$obj->uuid($existingMedia->uuid());
    	$bio->remove("media",$existingMedia);
    }
    $bio->add("media",$obj);
    $self->save_bio($bio);
}

1;
