use strict;
use common::sense;
use Class::Autouse qw(
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


#!/usr/bin/perl
sub readExpDesc {
    my ($path) = @_;

    open(DESC, "<$path");
    my $experiments = {};
    
    # skip header
    scalar <DESC>;
    while(<DESC>) {
        chomp;
        my ($exp) = split(/\t/);        
        $experiments->{$exp} = 1;
    }
    close(DEC);
    return $experiments;
}

sub checkIfRan {
    my ($model) = @_;
    my $ran = {};
    foreach my $fba (@{$model->fbaFormulations}) {
	if (defined $fba) {
	    my $media = $fba->media();
	    if (defined $media) {
		$ran->{$media->name()} = 1;
	    }
	}
    }

    return $ran;
} 


print STDERR "Please specify a model id and path to an experiments specifications\n
usage: runfva.pl <model> <spec_file>\n" if (@ARGV != 2);

my $args = \@ARGV;

my $auth  = ModelSEED::Auth::Factory->new->from_config;
my $store = ModelSEED::Store->new(auth => $auth);
my $helper = ModelSEED::App::Helpers->new();
# Retreiving the model object on which FBA will be performed
my ($model, $ref) = $helper->get_object("model",$args,$store);
warn "Model not found; You must supply a valid model name." unless(defined($model));

my ($model_ref, $exp_spec) = @ARGV;

my $ran = &checkIfRan($model);

my $experiments = &readExpDesc($exp_spec);
print "There are ", scalar keys %$experiments, " experiments\n";

foreach my $exp (keys %$experiments) {
    if (exists $ran->{$exp}) {
        print "The data already exists for $exp.\n";
    }
    else {
	(my $media) = $model->interpretReference("Media/name/$exp","Media");
	if (defined $media) {
	    print "media is defined: ", $media->name(), "\n";
	    my $command = "model runfba $model_ref --fva -o -v -f /tmp/$exp --media $exp";
	    print "$command\n";
	    my $result = `$command`;
	    print $result;
	}
	else {
	    print "media is not defined: ", $exp, ". It might be equivalent to Complete.\n";
        }
    }
}

