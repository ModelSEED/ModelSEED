use ModelSEED::Store;
use ModelSEED::Auth::Factory;
use ModelSEED::MS::PROMModel;
use strict;
use Data::Dumper;

if (@ARGV < 3) {
    print STDERR "usage: createPROMModel <genome-id> <on-off-calls-file> <tf-tg-map-file>\n";
    exit;
}
my $genomeid = $ARGV[0];
my $geneCalls = $ARGV[1];
my $tfs = $ARGV[2];
my $result = {};

my $auth = ModelSEED::Auth::Factory->new->from_config;
my $username = $auth->username();
# create an "authorization object" using the config file typically located at
# $HOME/.modelseed
my $store = ModelSEED::Store->new(auth => $auth);
my $annotation = $store->get_object("annotation/$username/$genomeid");
my $features = $annotation->features();

my %geneid2featureid;

foreach my $feature (@$features) {
    $geneid2featureid{$feature->id()} = $feature->uuid();
}

my $parsed;
my $data = ModelSEED::utilities::LOADFILE($geneCalls);
for (my $i=0; $i < @{$data}; $i++) {
    my @tempArray = split(/\t/,$data->[$i]);
    if (@tempArray >= 2) {
	for (my $i=1; $i < @tempArray; $i++) {
	    if ($tempArray[0] eq "Labels") {
		my $inner_parsed = {
		    label => $tempArray[$i]
		};
		$parsed->[$i] = $inner_parsed;
	    } elsif ($tempArray[0] eq "Descriptions") {
		$parsed->[$i]->{description} = $tempArray[$i];
	    } elsif ($tempArray[0] eq "Media") {
		if (length($tempArray[$i]) == 0) {
		    $tempArray[$i] = "Complete";
		}
		$parsed->[$i]->{media} = $tempArray[$i];
	    } else {
		if (!defined($parsed->[$i]->{media})) {
		    $parsed->[$i]->{media} = "Complete";
		}
		if (!defined($parsed->[$i]->{description})) {
		    $parsed->[$i]->{description} = "NONE";
		}
		if (!defined($parsed->[$i]->{label})) {
		    $parsed->[$i]->{label} = "Experiment ".$i;
		}
		$parsed->[$i]->{geneCalls}->{$tempArray[0]} = $tempArray[$i];
	    }
	}
    }
}
shift @{$parsed}; # delete an empty element.

# Compute probability for each tf-target as loading it from a file.
$data = ModelSEED::utilities::LOADFILE($tfs);

my %isOn = (-1 => 0,0 => 1,1 => 1); # expression value = 1 or 0 -> on, = -1 -> off. # but what if undef?

## calculate P(target = ON|TF = OFF) and P(target = ON|TF = ON)
my $tfMaps;

foreach (@{$data}) {
    my @genes = split;
    my $tf = shift @genes;
    my $tfMapTargets;
    foreach my $target (@genes) {
	my $tf_off_count = 0;
	my $tf_off_tg_on_count = 0;
	my $tf_on_count = 0;
	my $tf_on_tg_on_count = 0;

	for(my $i=0; $i < @{$parsed}; $i++) {  
	    if ($isOn{$parsed->[$i]->{geneCalls}->{$tf}}) {
		$tf_on_count++;
		$tf_on_tg_on_count++ if ($isOn{$parsed->[$i]->{geneCalls}->{$target}});
	    }
	    else {
		$tf_off_count++;
		$tf_off_tg_on_count++ if ($isOn{$parsed->[$i]->{geneCalls}->{$target}});
	    }             
	}
	my $tfMapTarget = {"target_uuid" => $geneid2featureid{$target}};
	if ($tf_on_count != 0) { 
	    $tfMapTarget->{"tfOnProbability"} = $tf_on_tg_on_count / $tf_on_count;
	}
	if ($tf_off_count != 0) {
	    $tfMapTarget->{"tfOffProbability"} = $tf_off_tg_on_count / $tf_on_count;
	}
	push @$tfMapTargets, $tfMapTarget;
    }
    push @$tfMaps, {"transcriptionFactor_uuid" => $geneid2featureid{$tf}, "transcriptionFactorMapTargets" => $tfMapTargets };
}

my $pmodel = ModelSEED::MS::PROMModel->new("annotation" => $annotation, "transcriptionFactorMaps" => $tfMaps, "id" => "pm_$genomeid");


print "Saving\n";
use Try::Tiny;
try {
$store->save_object("pROMModel/$username/pm_$genomeid", $pmodel);
print "Saved\n";
my $pm = $store->get_object("pROMModel/$username/pm_$genomeid");
print "Here it is: ", $pm, "\n";
print Dumper($pm);
}
catch {
    print Dumper($_);
};
