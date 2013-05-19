package ModelSEED::App::import::Command::templatefile;
use strict;
use common::sense;
use ModelSEED::App::import;
use base 'ModelSEED::App::ImportBaseCommand';
use ModelSEED::utilities;
use Cwd qw(getcwd);
use Class::Autouse qw(
    ModelSEED::MS::Factories::ExchangeFormatFactory
);
sub abstract { return "Import a template model from file"; }
sub usage_desc { return "ms import templatefile [reaction file] [biomass file] [biomass components file] [name] [options]"; }
sub description { return "Import a template model from file"; }
sub options {
    return (
    	["filepath|f:s", "Directory with flatfiles of data you are importing"],
        ["domain=s", "Domain of life for template model"],
        ["type|t=s", "Type of model produced by template"],
        ["mapping|m=s", "Mapping to which the template should be linked"],
	);
}
sub sub_execute {
    my ($self, $opts, $args) = @_;
    $self->usage_error("Must specify filename with template reactions") unless(defined($args->[0]));
    $self->usage_error("Must specify filename with template biomass reactions") unless(defined($args->[1]));
    $self->usage_error("Must specify filename with template biomass components") unless(defined($args->[2]));
    $self->usage_error("Must specify name for template model") unless(defined($args->[3]));
    #Getting mapping object
    my $map;
    if(defined($opts->{mapping})) {
    	$map = $self->get_object({
	   		type => "Mapping",
	   		reference => $opts->{mapping}
	   	});
    } else {
    	$map = config()->currentUser()->primaryStore()->defaultMapping();
    }
    #Handling filepath if specified
    if(defined($opts->{filepath})) {
    	$args->[0] = $opts->{filepath}.$args->[0];
    	$args->[1] = $opts->{filepath}.$args->[1];
    	$args->[2] = $opts->{filepath}.$args->[2];
    }
    #Loading data files
	my $rxnTbl = $self->_loadTableFile($args->[0]);
	my $bioTbl = $self->_loadTableFile($args->[1]);
	my $bioCompTbl = $self->_loadTableFile($args->[2]);
	my $tempRxns = [];
	my $tempBioComp = [];
	my $tempBio = [];
	for (my $i=0; $i < @{$rxnTbl->{data}}; $i++) {
		my $rxnRow = [
			$rxnTbl->{data}->[$i]->[$rxnTbl->{headings}->{id}],
			$rxnTbl->{data}->[$i]->[$rxnTbl->{headings}->{compartment}],
			$rxnTbl->{data}->[$i]->[$rxnTbl->{headings}->{direction}],
			$rxnTbl->{data}->[$i]->[$rxnTbl->{headings}->{type}],
			[split(/\|/,$rxnTbl->{data}->[$i]->[$rxnTbl->{headings}->{complexes}])]
		];
		push(@{$tempRxns},$rxnRow);
	}
	my $bioNameHash;
	for (my $i=0; $i < @{$bioTbl->{data}}; $i++) {
		my $bioRow = [
			$bioTbl->{data}->[$i]->[$bioTbl->{headings}->{name}],
			$bioTbl->{data}->[$i]->[$bioTbl->{headings}->{type}],
			$bioTbl->{data}->[$i]->[$bioTbl->{headings}->{dna}],
			$bioTbl->{data}->[$i]->[$bioTbl->{headings}->{rna}],
			$bioTbl->{data}->[$i]->[$bioTbl->{headings}->{protein}],
			$bioTbl->{data}->[$i]->[$bioTbl->{headings}->{lipid}],
			$bioTbl->{data}->[$i]->[$bioTbl->{headings}->{cellwall}],
			$bioTbl->{data}->[$i]->[$bioTbl->{headings}->{cofactor}],
			$bioTbl->{data}->[$i]->[$bioTbl->{headings}->{energy}],
			$bioTbl->{data}->[$i]->[$bioTbl->{headings}->{other}]
		];
		$bioNameHash->{$bioTbl->{data}->[$i]->[$bioTbl->{headings}->{name}]} = @{$tempBio};
		push(@{$tempBio},$bioRow);
	}
	for (my $i=0; $i < @{$bioCompTbl->{data}}; $i++) {
		if (defined($bioNameHash->{$bioCompTbl->{data}->[$i]->[$bioCompTbl->{headings}->{biomass}]})) {
			my $index = $bioNameHash->{$bioCompTbl->{data}->[$i]->[$bioCompTbl->{headings}->{biomass}]};
			my $links = [split(/;/,$bioCompTbl->{data}->[$i]->[$bioCompTbl->{headings}->{linked}])];
			for (my $j=0; $j < @{$links}; $j++) {
				$links->[$j] = [split(/:/,$links->[$j])];
			}
			my $bioRow = [
				$bioCompTbl->{data}->[$i]->[$bioCompTbl->{headings}->{id}],
				$bioCompTbl->{data}->[$i]->[$bioCompTbl->{headings}->{compartment}],
				$bioCompTbl->{data}->[$i]->[$bioCompTbl->{headings}->{class}],
				$bioCompTbl->{data}->[$i]->[$bioCompTbl->{headings}->{coefficientType}],
				$bioCompTbl->{data}->[$i]->[$bioCompTbl->{headings}->{coefficient}],
				$bioCompTbl->{data}->[$i]->[$bioCompTbl->{headings}->{conditions}],
				$links
			];
			push(@{$tempBio->[$index]->[10]},$bioRow);
		}
	}
	#Building and running ModelTemplate 
	my $factory = ModelSEED::MS::Factories::ExchangeFormatFactory->new(
		store => $self->store()
	);
	my $templateModel = $factory->buildTemplateModel({
		templateReactions => $tempRxns,
		templateBiomass => $tempBio,
		name => $args->[2],
		modelType => $opts->{type},
		mapping => $map,
		domain => $opts->{domain}
	});
	#Saving model in database
    $self->save_object({
    	object => $templateModel,
    	type => "ModelTemplate",
    	reference => $args->[3]
    });
}

sub _loadTableFile {
	my ($self, $filename) = @_;
	if (!-e $filename) {
		print "Could not open table file!\n";
		exit();
	}
	open(my $fh, "<", $filename) || return;
	my $headingline = <$fh>;
	my $tbl;
	chomp($headingline);
	my $headings = [split(/\t/,$headingline)];
	for (my $i=0; $i < @{$headings}; $i++) {
		$tbl->{headings}->{$headings->[$i]} = $i;
	}
	while (my $line = <$fh>) {
		chomp($line);
		push(@{$tbl->{data}},[split(/\t/,$line)]);
	}
	close($fh);
	return $tbl;
}

1;
