#!/usr/bin/perl -w
$|++;
my $bio = $ARGV[0];
use Class::Autouse qw(
    ModelSEED::MS::Model
    ModelSEED::Store
    ModelSEED::Auth::Factory
    ModelSEED::Reference
    ModelSEED::Configuration
    ModelSEED::App::Helpers
    ModelSEED::MS::Factories::ExchangeFormatFactory
);

my $auth  = ModelSEED::Auth::Factory->new->from_config;
my $store = ModelSEED::Store->new(auth => $auth);
my $helper = ModelSEED::App::Helpers->new();
my ($biochemistry,my $ref) = $helper->get_object("biochemistry", [$bio], $store);
if (!defined($biochemistry)) {
	ModelSEED::utilities::ERROR("Biochemistry ".$bio." not found!");
}
my $list = [ qw(
	cpd00001 cpd00009 cpd00010 cpd00011 cpd00012 cpd00013 cpd00015 cpd11609 cpd11610 cpd00067 cpd00099 cpd00099 cpd12713 cpd00242 cpd00007 cpd00025
) ];
for (my $i=0; $i < @{$list}; $i++) {
	my $cpd = $biochemistry->getObjectByAlias("compounds",$list->[$i],"ModelSEED");
	if (!defined($cpd)) {
		print "Could not find ".$list->[$i]."!\n";
	} else {
		print "Cofactor found: ".$cpd->id()."\n";
		$cpd->isCofactor(1);
	}
}
my $rxns = $biochemistry->reactions();
my $pairlist = [
["cpd00097","cpd00986"],
["cpd00109","cpd00110"],
["cpd11620","cpd11621"],
["cpd00228","cpd00823"],
["cpd11665","cpd11669"],
["cpd00733","cpd00734"],
["cpd11807","cpd11808"],
["cpd00364","cpd00415"],
["cpd12505","cpd12576"],
["cpd12669","cpd12694"],
["cpd00003","cpd00004"],
["cpd00005","cpd00006"],
["cpd00002","cpd00008"],
["cpd00002","cpd00018"],
["cpd00008","cpd00018"],
["cpd00052","cpd00096"],
["cpd00002","cpd00046"],
["cpd00046","cpd00096"],
["cpd00062","cpd00091"],
["cpd00062","cpd00014"],
["cpd00014","cpd00091"],
["cpd00038","cpd00126"],
["cpd00038","cpd00031"],
["cpd00126","cpd00031"],
["cpd00357","cpd00793"],
]; 
for (my $i=0; $i < @{$rxns}; $i++) {
 	my $rxn = $rxns->[$i];
 	for (my $j=0; $j < @{$pairlist}; $j++) {
 		my $pair = $pairlist->[$j];
 		my $rgts = $rxn->reagents();
 		for (my $k=0; $k < @{$rgts}; $k++) {
 			my $rgt = $rgts->[$k];
 			if ($rgt->compound()->id() eq $pair->[0]) {
 				for (my $m=0; $m < @{$rgts}; $m++) {
		 			my $rgtTwo = $rgts->[$m];
		 			if ($rgtTwo->compound()->id() eq $pair->[1]) {
		 				if ($rgt->coefficient()*$rgtTwo->coefficient() < 0) {
		 					print "Cofactor set in reaction ".$rxn->id()."\n";
		 					$rgt->isCofactor(1);
		 					$rgtTwo->isCofactor(1);
		 				}
		 			}
		 		}
 			}
 		}
 	}
}
$store->save_object("biochemistry/".$biochemistry->uuid(),$biochemistry,{schema_update => 1});