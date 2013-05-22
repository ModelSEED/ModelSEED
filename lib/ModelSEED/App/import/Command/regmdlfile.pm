package ModelSEED::App::import::Command::regmdlfile;
use strict;
use common::sense;
use ModelSEED::App::import;
use base 'ModelSEED::App::ImportBaseCommand';
use ModelSEED::utilities;
use Cwd qw(getcwd);
use Class::Autouse qw(
    ModelSEED::MS::Factories::ExchangeFormatFactory
);
sub abstract { return "Import a regulatory model from file"; }
sub usage_desc { return "ms import regmdlfile [filename] [genome] [name] [options]"; }
sub description { return "Import a regulatory model from file"; }
sub options {
    return (
    	["filepath|f:s", "Directory with flatfiles of data you are importing"],
        ["type|t=s", "Type of the regulatory model"],
        ["mapping|m=s", "Mapping to which regulatory model should be linked"],
	);
}
sub sub_execute {
    my ($self, $opts, $args) = @_;
    $self->usage_error("Must specify filename with regulatory model data") unless(defined($args->[0]));
    $self->usage_error("Must specify a genome for the regulatory model") unless(defined($args->[1]));
    $self->usage_error("Must specify a name for the regulatory model") unless(defined($args->[2]));
    #Getting annotation object
    my $anno = $self->get_object({
	   	type => "Annotation",
	   	reference => $args->[1]
	});
    #Getting mapping object
    my $map;
    if(defined($opts->{mapping})) {
    	$map = $self->get_object({
	   		type => "Mapping",
	   		reference => $opts->{mapping}
	   	});
    } else {
    	$map = ModelSEED::utilities::config()->currentUser()->primaryStore()->defaultMapping();
    }
    #Handling filepath if specified
    if(defined($opts->{filepath})) {
    	$args->[0] = $opts->{filepath}.$args->[0];
    }
    #Loading data files
	my $requiredHeadings = [qw(
		Regulon Gene Stimuli StimuliSign Regulator
	)];
	my $optionalHeadings = [qw(
		Strength MinConcentration MaxConcentration
	)];
	my $regTbl = $self->_loadTableFile($args->[0],$requiredHeadings,$optionalHeadings);
	my $genes = [];
	for (my $i=0; $i < @{$regTbl->{data}}; $i++) {
		my $row = [
			$regTbl->{data}->[$i]->[$regTbl->{headings}->{Regulon}],
			$regTbl->{data}->[$i]->[$regTbl->{headings}->{Gene}],
			$regTbl->{data}->[$i]->[$regTbl->{headings}->{Stimuli}],
			$regTbl->{data}->[$i]->[$regTbl->{headings}->{StimuliSign}],
			$regTbl->{data}->[$i]->[$regTbl->{headings}->{Regulator}],
			$regTbl->{data}->[$i]->[$regTbl->{headings}->{Strength}],
			$regTbl->{data}->[$i]->[$regTbl->{headings}->{MinConcentration}],
			$regTbl->{data}->[$i]->[$regTbl->{headings}->{MaxConcentration}]
		];
		push(@{$genes},$row);
	}
	#Building and running ModelTemplate 
	my $factory = ModelSEED::MS::Factories::ExchangeFormatFactory->new(
		store => $self->store()
	);
	my $regModel = $factory->buildRegulatoryModel({
		genes => $genes,
		name => $args->[2],
		type => $opts->{type},
		mapping => $map,
		annotation => $anno 
	});
	#Saving model in database
    $self->save_object({
    	object => $regModel,
    	type => "RegulatoryModel",
    	reference => $args->[2]
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
