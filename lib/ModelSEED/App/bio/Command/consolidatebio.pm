package ModelSEED::App::bio::Command::consolidatebio;
use strict;
use common::sense;
use ModelSEED::App::bio;
use base 'ModelSEED::App::BioBaseCommand';
use Class::Autouse qw(
    ModelSEED::MS::Factories::ExchangeFormatFactory
    ModelSEED::MS::Model
);
use ModelSEED::utilities;
sub abstract { return "Consolidates a single biochemistry into a nonredundant set" }
sub usage_desc { return "bio consolidatebio [ biochemistry id ]"; }
sub options {
    return (
	["mergevia|m=s@", "Name space of identifiers used for merging compounds. Comma delimiter accepted."],
	["namespace|n=s", "Default namespace for printing identifiers"],
    	["noaliastransfer|t", "Do not transfer aliases to merged compound"]
    );
}
sub sub_execute {
    my ($self, $opts, $args,$bio) = @_;
    if(!defined($opts->{namespace})){
	ModelSEED::utilities::verbose("A default namespace was not passed and the name of the biochemistry ('".$args->[0]."') is used by default\n");
	$opts->{namespace}=[$args->[0]];
    }else{
	#need arrayref if using mergeBiochemistry()
	#only need one namespace if using consolidatebio
	$opts->{namespace}=[$opts->{namespace}];
    }
    my $new_name="Temp";
    $new_name = $opts->{saveas} if defined($opts->{saveas});
    my $new_biochemistry = ModelSEED::MS::Biochemistry->new({defaultNameSpace => $opts->{namespace},name => $new_name});
    ModelSEED::utilities::verbose("Using: ",$bio->name(),"\n");

    if(!defined($opts->{mergevia})){
	ModelSEED::utilities::verbose("A namespace for merging identifiers was not passed, and therefore compounds will be compared directly based on their names\n");
    }else{
	$opts->{mergevia} = ModelSEED::utilities::translateArrayOptions({ option => $opts->{mergevia}, delimiter => "," });
	foreach my $mergeNamespace (@{$opts->{mergevia}}){
	    if(!$bio->queryObject("aliasSets",{name => $mergeNamespace, attribute=>"compounds"})){
		$self->usage_error("Namespace for merging (".$mergeNamespace.") not found in biochemistry object");
	    }
	}
    }

    #Add empty aliasSets
    if(!defined($opts->{noaliastransfer})){
	#check to see if desired matching namespace actually exists
	my $has_namespace=0;
	foreach my $set (@{$bio->aliasSets()}){
	    my $new_set=ModelSEED::MS::AliasSet->new({name=>$set->name(),source=>$set->source(),attribute=>$set->attribute(),class=>$set->class()});
	    $new_biochemistry->add("aliasSets",$new_set);
	    if($set->name() eq $opts->{namespace}->[0]){
		$has_namespace=1;
	    }
	}
	$self->usage_error("Namespace ".$opts->{namespace}->[0]." not found") unless $has_namespace;
    }

    $bio->defaultNameSpace($opts->{namespace}->[0]);
    $new_biochemistry->defaultNameSpace($opts->{namespace}->[0]);

    #automatically set consolidate option
    #this allows mergeBiochemistry to repeat matches with the same object
    $opts->{consolidate}=1;

    $new_biochemistry->mergeBiochemistry($bio,$opts);

    $self->save_bio($new_biochemistry);
}

1;
