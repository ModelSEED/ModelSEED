#!/usr/bin/perl
use strict;
use common::sense;
use Class::Autouse qw(
    Term::ProgressBar
    YAML::XS
    File::Temp
    JSON::XS
    ModelSEED::Store
    ModelSEED::Auth::Factory
    ModelSEED::Reference
    ModelSEED::Configuration
    ModelSEED::App::Helpers
    ModelSEED::MS::Factories::ExchangeFormatFactory
    ModelSEED::MS::FBAFormulation
    ModelSEED::Solver::FBA
);

my $args = \@ARGV;

my $auth  = ModelSEED::Auth::Factory->new->from_config;
my $store = ModelSEED::Store->new(auth => $auth);
my $helper = ModelSEED::App::Helpers->new();
# Retreiving the model object on which FBA will be performed
my ($model, $ref) = $helper->get_object("model",$args,$store);
warn "Model not found; You must supply a valid model name." unless(defined($model));
$DB::single = 1;

my $forms = $model->fbaFormulations();
my $count = 0;
my $max = @$forms;
my $progress = Term::ProgressBar->new({name  => 'Outliers',
                                      count => $max,
                                     ETA   => 'linear', });
$progress->max_update_rate(1);

my $geneCalls = {};

foreach my $form (@$forms) {
    my ($uuid, $file) = File::Temp::tempfile();
    print $uuid $form->uuid();
    close $uuid;

    my $command = "perl ./simpleGeneActivityAnalysis.pl ". $ref->alias_string. " -j $file";
    my $exchange = `$command`;    
    my $singleGeneCalls = YAML::XS::Load($exchange);
#    print STDERR $singleGeneCalls->{"media"}, "\n";

    $geneCalls->{$singleGeneCalls->{"media"}} = $singleGeneCalls->{"data"}; 
    $progress->update($count++);
}

# save file just in case.
YAML::XS::DumpFile("./genecall.yaml", $geneCalls);

&resumeComplete($geneCalls);

&printGeneCalls($geneCalls);


# print gene calls for each media.
sub printGeneCalls {    
    my ($overForms) = @_;

    my $tbl = {"headings" =>["gene_id"], "data" => []};
    
    foreach my $media (sort keys %$overForms) {
        $geneCalls = $overForms->{$media};
        push @{$tbl->{"headings"}}, $media;

        my @gene_ids = sort by_feature_id keys %{$geneCalls};
        for (my $row_i = 0; $row_i < @gene_ids; $row_i++ ) {
            $tbl->{"data"}->[$row_i] = [$gene_ids[$row_i]] if (!defined $tbl->{"data"}->[$row_i]);
            push @{$tbl->{"data"}->[$row_i]}, $geneCalls->{$gene_ids[$row_i]};
        }
    }
    ModelSEED::utilities::PRINTTABLE("STDOUT",$tbl,"\t");
}

sub resumeComplete {
    my ($geneCalls) = @_;
    if (!exists  $geneCalls->{"Complete"}) {
	warn "genecall for complete media does not exists";
	return;
    }
    my $file_path = "./complete.media"; 
    if (! -e $file_path) {
	warn "Cannot find $file_path";
	return;
    }	
    open(FILE, "<$file_path") or die "Cannot find complete.media: $!";
    my @media = split(/;/, readline(FILE));
    for my $name (@media) {
        $geneCalls->{$name} = $geneCalls->{"Complete"};
    }    
}


sub by_feature_id {
    if ($a =~ /(\w+)\.(\d+)$/) {
        my $a_kind = $1;
        my $a_num = $2;
        if ($b =~ /(\w+)\.(\d+)$/) {
            my $b_kind = $1;
            my $b_num = $2;	    
            return $a_kind cmp $b_kind || $a_num <=> $b_num;
	    }
    }
    return 0;    
}
