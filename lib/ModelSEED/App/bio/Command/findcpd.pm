package ModelSEED::App::bio::Command::findcpd;
use base 'App::Cmd::Command';
use Class::Autouse qw(
    ModelSEED::Store
    ModelSEED::Auth::Factory
    ModelSEED::App::Helpers
);
sub abstract { return "Searches for compounds that match specified names" }
sub usage_desc { return "bio findcpd [< biochemistry | biochemistry] [options]"; }
sub opt_spec {
    return (
        ["names|n=s", "Filename or '|' delimited list of input names"],
        ["filein|f","Input is specified in a file"],
        ["id", "IDs of identified compounds should be printed"],
        ["help|h|?", "Print this usage information"],
    );
}

sub execute {
    my ($self, $opts, $args) = @_;
    print($self->usage) && exit if $opts->{help};
    my $auth  = ModelSEED::Auth::Factory->new->from_config;
    my $store = ModelSEED::Store->new(auth => $auth);
    my $helper = ModelSEED::App::Helpers->new();
    my ($biochemistry,my $ref) = $helper->get_object("biochemistry", $args, $store);
    $self->usage_error("Must specify an biochemistry to use") unless(defined($biochemistry));
    my $names = [];
    if ($opts->{filein} == 1) {
    	$self->usage_error("Specified names file could not be found!") unless(-e $opts->{names});
    	$names = ModelSEED::utilities::LOADFILE($opts->{names});
    } else {
    	$names = [split(/\|/,$opts->{names})];
    }
   	my $cpds = [];
   	foreach my $name (@{$names}) {
   		my $sn = ModelSEED::MS::Compound->nameToSearchname($name);
   		my $cpd = $biochemistry->queryObject("compounds",{searchnames => $sn});
   		print STDOUT $name."\t".$sn."\t";
   		if (defined($cpd)) {
   			print STDOUT $cpd->uuid();
   			if ($opts->{id} == 1) {
   				print STDOUT "\t".$cpd->id();
   			}
   		} elsif ($opts->{id} == 1) {
   			print STDOUT "\t";
   		}
   		print STDOUT "\n";
   	}
}

1;
