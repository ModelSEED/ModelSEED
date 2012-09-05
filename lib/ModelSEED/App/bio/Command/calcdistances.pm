package ModelSEED::App::bio::Command::calcdistances;
use base 'App::Cmd::Command';
use Class::Autouse qw(
    ModelSEED::Store
    ModelSEED::Auth::Factory
    ModelSEED::Reference
    ModelSEED::Configuration
    ModelSEED::App::Helpers
    ModelSEED::MS::Factories::ExchangeFormatFactory
);
sub abstract { return "Calculate pairwise distances between metabolites, reactions, and roles"; }
sub usage_desc { return "bio calcdistances [< biochemistry | biochemistry] [options]"; }
sub opt_spec {
    return (
        ["verbose|v", "Print verbose status information"],
        ["reactions|r","Calculate distances between reactions (metabolites default)"],
        ["roles|r","Calculate distances between roles (metabolites default)"],
        ["matrix|m","Print results as a matrix"],
        ["threshold|t:s","Only print pairs with distance under threshold"],
    );
}

sub execute {
    my ($self, $opts, $args) = @_;
    my $auth  = ModelSEED::Auth::Factory->new->from_config;
    my $store = ModelSEED::Store->new(auth => $auth);
    my $helper = ModelSEED::App::Helpers->new();
    my ($biochemistry,my $ref) = $helper->get_object("biochemistry", $args, $store);
    $self->usage_error("Must specify an biochemistry to use") unless(defined($biochemistry));
    #Standard commands to handle where output will be printed
    my $out_fh = \*STDOUT;
    #Performing computation
	print STDERR "Computing network distances...\n" if($opts->{verbose});
	my $tbl = $model->computeNetworkDistances({
		reactions => $opts->{reactions},
		roles => $opts->{roles}
	});
	#Printing results
	print STDERR "Printing results...\n" if($opts->{verbose});
	if ($opts->{matrix} == 1) {
		ModelSEED::utilities::PRINTTABLE("STDOUT",$tbl,"\t");
	} else {
		ModelSEED::utilities::PRINTTABLESPARSE("STDOUT",$tbl,"\t",undef,$opts->{threshold});
	}
}

1;
