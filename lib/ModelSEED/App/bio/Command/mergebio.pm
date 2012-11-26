package ModelSEED::App::bio::Command::mergebio;
use strict;
use common::sense;
use base 'App::Cmd::Command';
use Class::Autouse qw(
    ModelSEED::Store
    ModelSEED::Auth::Factory
    ModelSEED::App::Helpers
);
use ModelSEED::utilities qw( verbose set_verbose translateArrayOptions );
sub abstract { return "Merge two biochemistries into a nonredundant set" }
sub usage_desc { return "bio mergebio [ < biochemistry | biochemistry ] [ second_biochemistry ]"; }
sub opt_spec {
    return (
	["mergevia|m:s@", "Name space of identifiers used for merging compounds. Comma delimiter accepted."],
	["namespace|n:s@", "Default namespace for printing identifiers"],
    	["noaliastransfer|t", "Do not transfer aliases to merged compound"],
    	["verbose|v", "Print messages with progress"],
        ["saveas|a:s", "New name the merged biochemistry should be saved to"],
        ["saveover|s", "Save results as original biochemistry"],
        ["help|h|?", "Print this usage information"],
    );
}

sub execute {
    my ($self, $opts, $args) = @_;

    $self->usage_error("Must specify a biochemistry to use") unless(defined($args->[0]));
    $self->usage_error("Must specify a biochemistry to be merged") unless(defined($args->[1]));

    #verbosity
    set_verbose(1) if $opts->{verbose};
    $|=1;

    if (!defined($opts->{saveas}) && !defined($opts->{saveover})){
	verbose("Neither the saveas or saveover options were used\nThis run will therefore be a dry run and the biochemistry will not be saved\n");
    }

    my $auth  = ModelSEED::Auth::Factory->new->from_config;
    my $store = ModelSEED::Store->new(auth => $auth);
    my $helper = ModelSEED::App::Helpers->new();

    my ($biochemistry,$ref) = $helper->get_object("biochemistry", $args, $store);
    $self->usage_error("Biochemistry ".$args->[0]." not found") unless defined($biochemistry);
    print "Using: ",$biochemistry->name(),"\n";

    shift(@$args);
    my ($other_biochemistry,$other_ref) = $helper->get_object("biochemistry", $args, $store);
    $self->usage_error("Merging Biochemistry ".$args->[0]." not found") unless defined($other_biochemistry);
    print "Merging: ",$other_biochemistry->name(),"\n";
    
    #test aliasSets for merging
    if(!defined($opts->{mergevia})){
	verbose("A namespace for merging identifiers was not passed, and therefore compounds will be compared directly based on their names\n");
    }else{
	$opts->{mergevia} = translateArrayOptions({ option => $opts->{mergevia}, delimiter => "," });
	foreach my $mergeNamespace (@{$opts->{mergevia}}){
	    if(!$biochemistry->queryObject("aliasSets",{name => $mergeNamespace, attribute=>"compounds"}) ||
	       !$other_biochemistry->queryObject("aliasSets",{name => $mergeNamespace, attribute=>"compounds"})){
		$self->usage_error("Namespace for merging (".$mergeNamespace.") not found in one or both biochemistry objects");
	    }
	}
    }

    if(!defined($opts->{namespace})){
	verbose("A default namespace was not passed and the name of the biochemistry ('".$args->[0]."') is used by default\n");
	$opts->{namespace}=[$args->[0]];
    }else{
	$opts->{namespace} = translateArrayOptions({ option => $opts->{namespace}, delimiter => "," });
	foreach my $idNamespace (@{$opts->{namespace}}){
	    if(!$biochemistry->queryObject("aliasSets",{name => $idNamespace, attribute=>"compounds"}) &&
	       !$other_biochemistry->queryObject("aliasSets",{name => $idNamespace, attribute=>"compounds"})){
		$self->usage_error("Namespace for reporting identifiers (".$idNamespace.") not found in both biochemistry objects");
	    }
	}
    }

    #Add empty aliasSets
    if(!defined($opts->{noaliastransfer})){
	foreach my $set (@{$other_biochemistry->aliasSets()}){
	    if(!$biochemistry->queryObject('aliasSets',{name=>$set->name(),attribute=>$set->attribute()})){
		my $new_set=ModelSEED::MS::AliasSet->new({name=>$set->name(),source=>$set->source(),attribute=>$set->attribute(),class=>$set->class()});
		$biochemistry->add("aliasSets",$new_set);
	    }
	}
    }

    $biochemistry->mergeBiochemistry($other_biochemistry,$opts);

    if (defined($opts->{saveas})) {
	my $new_ref = $helper->process_ref_string($opts->{saveas}, "biochemistry", $auth->username);
	verbose("Saving biochemistry with merged compounds as ".$new_ref."...\n");
	$biochemistry->name($opts->{saveas});
	$store->save_object($new_ref,$biochemistry);
    }elsif (defined($opts->{saveover})) {
	verbose("Saving over first biochemistry with merged biochmistry...\n");
	$store->save_object($ref,$biochemistry);
    }
}

1;
