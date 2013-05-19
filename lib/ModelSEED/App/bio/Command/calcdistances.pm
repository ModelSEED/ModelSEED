package ModelSEED::App::bio::Command::calcdistances;
use strict;
use common::sense;
use ModelSEED::App::bio;
use base 'ModelSEED::App::BioBaseCommand';
use Class::Autouse qw(
    ModelSEED::MS::Factories::ExchangeFormatFactory
    ModelSEED::MS::Model
);
use ModelSEED::utilities;
sub abstract { return "Calculate pairwise distances between metabolites, reactions, and roles"; }
sub usage_desc { return "bio calcdistances [ biochemistry id ] [options]"; }
sub options {
    return (
        ["reactions|r","Calculate distances between reactions (metabolites default)"],
        ["roles|r","Calculate distances between roles (metabolites default)"],
        ["matrix|m","Print results as a matrix"],
        ["threshold|t:s","Only print pairs with distance under threshold"],
    );
}
sub sub_execute {
    my ($self, $opts, $args,$bio) = @_;
  	my $model = $bio->makeDBModel();
	my $tbl = $model->computeNetworkDistances({
		reactions => $opts->{reactions},
		roles => $opts->{roles}
	});
	#Printing results
	if ($opts->{matrix} == 1) {
		ModelSEED::utilities::PRINTTABLE("STDOUT",$tbl,"\t");
	} else {
		ModelSEED::utilities::PRINTTABLESPARSE("STDOUT",$tbl,"\t",undef,$opts->{threshold});
	}
}

1;
