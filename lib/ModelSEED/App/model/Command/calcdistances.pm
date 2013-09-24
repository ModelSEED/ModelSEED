package ModelSEED::App::model::Command::calcdistances;
use strict;
use common::sense;
use ModelSEED::App::model;
use base 'ModelSEED::App::ModelBaseCommand';
use ModelSEED::utilities;
sub abstract { "Calculate pairwise distances between metabolites, reactions, and roles" }
sub usage_desc { return "ms model calcdistances [model] [options]"; }
sub options {
    return (
        ["reactions|r","Calculate distances between reactions (metabolites default)"],
        ["roles|o","Calculate distances between roles (metabolites default)"],
	["genes|g","Calculate distances between genes (metabolites default)"],
        ["matrix|m","Print results as a matrix"],
        ["detail|d","Print details of each path"],
        ["threshold|t:s","Only print pairs with distance under threshold"],
    );
}

sub sub_execute {
    my ($self, $opts, $args,$model) = @_;
	#Standard commands to handle where output will be printed
    my $out_fh = \*STDOUT;
    #Performing computation
	ModelSEED::utilities::verbose("Computing network distances...\n");
	my $tbl = $model->computeNetworkDistances({
		reactions => $opts->{reactions},
		roles=> $opts->{roles},
		genes=> $opts->{genes},
		detail=> $opts->{detail},
	});
	#Printing results
	ModelSEED::utilities::verbose("Printing results...\n");
	if ($opts->{matrix} == 1) {
		ModelSEED::utilities::PRINTTABLE("STDOUT",$tbl,"\t");
	} else {
		ModelSEED::utilities::PRINTTABLESPARSE("STDOUT",$tbl,"\t",undef,$opts->{threshold});
	}
}

1;
