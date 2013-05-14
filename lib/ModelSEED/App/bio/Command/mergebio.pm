package ModelSEED::App::bio::Command::mergebio;
use strict;
use common::sense;
use ModelSEED::App::bio;
use base 'ModelSEED::App::BioBaseCommand';
use Class::Autouse qw(
    ModelSEED::MS::Factories::ExchangeFormatFactory
);
use ModelSEED::utilities qw( config error args verbose set_verbose translateArrayOptions);
sub abstract { return "Merge two biochemistries into a nonredundant set" }
sub usage_desc { return "bio mergebio [ biochemistry id ] [ second_biochemistry ]"; }
sub options {
    return (
		["mergevia|m:s@", "Name space of identifiers used for merging compounds. Comma delimiter accepted."],
		["namespace|n:s@", "Default namespace for printing identifiers"],
    	["noaliastransfer|t", "Do not transfer aliases to merged compound"],
		["checkforduplicates|f:s", "Force a check to report whether multiple compounds from the same file were merged together, which is typically undesirable.  Parameter requires single namespace"],
    );
}
sub sub_execute {
    my ($self, $opts, $args,$bio) = @_;
    $self->usage_error("Must specify a biochemistry to be merged") unless(defined($args->[0]));
    print "Using: ",$bio->name(),"\n";
	my $other_biochemistry = $self->get_object({
   		type => "Biochemistry",
   		reference => $args->[0]
   	});
    $self->usage_error("Merging Biochemistry ".$args->[0]." not found") unless defined($other_biochemistry);
    verbose("Merging: ".$other_biochemistry->name()." with ".$bio->name());
    
    #test aliasSets for merging
    if(!defined($opts->{mergevia})){
	verbose("A namespace for merging identifiers was not passed, and therefore compounds will be compared directly based on their names\n");
    }else{
	$opts->{mergevia} = translateArrayOptions({ option => $opts->{mergevia}, delimiter => "," });
	foreach my $mergeNamespace (@{$opts->{mergevia}}){
	    if(!$bio->queryObject("aliasSets",{name => $mergeNamespace, attribute=>"compounds"}) ||
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
	    if(!$bio->queryObject("aliasSets",{name => $idNamespace, attribute=>"compounds"}) &&
	       !$other_biochemistry->queryObject("aliasSets",{name => $idNamespace, attribute=>"compounds"})){
		$self->usage_error("Namespace for reporting identifiers (".$idNamespace.") not found in both biochemistry objects");
	    }
	}
    }

    #Add empty aliasSets
    if(!defined($opts->{noaliastransfer})){
	foreach my $set (@{$other_biochemistry->aliasSets()}){
	    if(!$bio->queryObject('aliasSets',{name=>$set->name(),attribute=>$set->attribute()})){
		my $new_set=ModelSEED::MS::AliasSet->new({name=>$set->name(),source=>$set->source(),attribute=>$set->attribute(),class=>$set->class()});
		$bio->add("aliasSets",$new_set);
	    }
	}
    }

    $bio->mergeBiochemistry($other_biochemistry,$opts);

    if(defined($opts->{checkforduplicates})){
	if(!$bio->queryObject("aliasSets",{name => $opts->{checkforduplicates}, attribute=>"compounds"})){
	    print STDERR "Warning: cannot check for duplicate compounds, namespace ".$opts->{checkforduplicates}." does not exist\n";
	}else{
	    my $aliases = $bio->queryObject("aliasSets",{ name => $opts->{checkforduplicates}, attribute => "compounds" })->aliases();
	    my %uuidAliasHash=();
	    
	    foreach my $alias (keys %$aliases){
		foreach my $uuid (@{$aliases->{$alias}}){
		    $uuidAliasHash{$uuid}{$alias}=1;
		}
	    }
	    
	    foreach my $uuid ( grep { scalar( keys %{$uuidAliasHash{$_}} )>1 } keys %uuidAliasHash ){
		print STDERR "Multiple compounds merged to a single UUID (".$uuid."): ".join("|",keys %{$uuidAliasHash{$uuid}})."\n";
	    }
	}
    }

    $self->save_bio($bio);
}

1;
