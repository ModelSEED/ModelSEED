package ModelSEED::App::bio::Command::addmedia;
use base 'App::Cmd::Command';
use Class::Autouse qw(
    ModelSEED::Store
    ModelSEED::Auth::Factory
    ModelSEED::Reference
    ModelSEED::Configuration
    ModelSEED::App::Helpers
    ModelSEED::MS::Factories::ExchangeFormatFactory
);
sub abstract { return "Adds a specified media condition to the database"; }
sub usage_desc { return "bio addmedia [< biochemistry | biochemistry] [name] [compounds] [options]"; }
sub opt_spec {
    return (
        ["verbose|v", "Print verbose status information"],
        ["isdefined","Media is defined"],
        ["isminimal","Media is a minimal media"],
        ["type:s","Type of the media"],
        ["concentrations|n:s", "',' delimited array of concentrations"],
        ["saveas|a:s", "New alias for altered biochemistry"],
        ["namespace|n:s", "Namespace under which IDs will be added"],
    );
}

sub execute {
    my ($self, $opts, $args) = @_;
    my $auth  = ModelSEED::Auth::Factory->new->from_config;
    my $store = ModelSEED::Store->new(auth => $auth);
    my $helper = ModelSEED::App::Helpers->new();
    my ($biochemistry,my $ref) = $helper->get_object("biochemistry", $args, $store);
    $self->usage_error("Must specify an biochemistry to use") unless(defined($biochemistry));
    $self->usage_error("Must specify a name for the media") unless(defined($args->[1]));
    $self->usage_error("Must specify compounds in the media") unless(defined($args->[2]));
    my $data = {
    	name => $args->[1],
    	compounds => $args->[2]
    };
    foreach my $option (keys(%{$opts})) {
    	$data->{$option} = $opts->{$option};
    }
    my $factory = ModelSEED::MS::Factories::ExchangeFormatFactory->new();
    my $obj = $factory->createFromAPI("Media",$biochemistry,$data);
    my $existingMedia = $biochemistry->queryObject("media",{id => $obj->id()});
    if (defined($existingMedia)) {
    	$obj->uuid($existingMedia->uuid());
    	$biochemistry->remove("media",$existingMedia);
    }
    $biochemistry->add("media",$obj);
    if (defined($opts->{saveas})) {
    	$ref = $helper->process_ref_string($opts->{saveas}, "biochemistry", $auth->username);
    	print STDERR "Saving biochemistry with new media as ".$ref."...\n" if($opts->{verbose});
		$store->save_object($ref,$biochemistry);
    } else {
    	print STDERR "Saving over original biochemistry with new media...\n" if($opts->{verbose});
    	$store->save_object($ref,$biochemistry);
    }
}

1;
