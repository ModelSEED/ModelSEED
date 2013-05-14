package ModelSEED::App::bio::Command::findcpd;
use strict;
use common::sense;
use ModelSEED::App::bio;
use base 'ModelSEED::App::BioBaseCommand';
use Class::Autouse qw(
    ModelSEED::MS::Factories::ExchangeFormatFactory
    ModelSEED::MS::Model
);
use ModelSEED::utilities qw( config error args verbose set_verbose translateArrayOptions);
sub abstract { return "Searches for compounds that match specified names" }
sub usage_desc { return "bio findcpd [ biochemistry id ] [options]"; }
sub options {
    return (
        ["names|n=s", "Filename or '|' delimited list of input names"],
        ["filein|f","Input is specified in a file"],
        ["id", "IDs of identified compounds should be printed"],
    );
}
sub sub_execute {
    my ($self, $opts, $args,$bio) = @_;
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
   		my $cpd = $bio->queryObject("compounds",{searchnames => $sn});
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
