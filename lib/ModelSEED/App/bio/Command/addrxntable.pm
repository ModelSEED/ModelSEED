package ModelSEED::App::bio::Command::addrxntable;
use strict;
use common::sense;
use ModelSEED::App::bio;
use base 'ModelSEED::App::BioBaseCommand';
use Class::Autouse qw(
    ModelSEED::MS::Factories::ExchangeFormatFactory
);
use ModelSEED::utilities;
sub abstract { return "Reads in table of reaction data and adds them to the database" }
sub usage_desc { return "bio addrxntable [ biochemistry id ] [filename] [options]"; }
sub options {
    return (
        ["rxnnamespace|r=s", "Name space for reaction IDs"],
        ["cpdnamespace|c=s", "Name space for compound IDs in equation"],
        ["autoadd|u","Automatically add any missing compounds to DB"],
        ["mergeto|m=s@", "Name space of identifiers used for merging reactions. Comma delimiter accepted."],
        ["separator|t=s", "Column separator for file. Default is tab"],
        ["addmergealias|g", "Add identifiers to merging namespace."],
	["balancedonly|b", "Attempt to balance reactions and reject imbalanced reactions before adding to biochemistry"]
    );
}
sub sub_execute {
    my ($self, $opts, $args,$bio) = @_;
    $self->usage_error("Must specify a valid filename for reaction table") unless(defined($args->[0]) && -e $args->[0]);
    #load table
    my $tbl = ModelSEED::utilities::LOADTABLE($args->[0],"\\t");

    #load table
    my $separator="\\\t";
    $separator = $opts->{separator}  if exists $opts->{separator};
    my $tbl = ModelSEED::utilities::LOADTABLE($args->[0],$separator);

    if(scalar(@{$tbl->{data}->[0]})<2){
	$tbl = ModelSEED::utilities::LOADTABLE($args->[0],"\\\;");
#	$self->usage_error("Not enough columns in table, consider using a different separator");
    }

    #set namespace
    if (!defined($opts->{rxnnamespace})) {
	$opts->{rxnnamespace} = $args->[0];
	print STDERR "Warning: no namespace passed.  Using biochemistry name by default: ".$opts->{rxnnamespace}."\n";
    } 

    if(defined($opts->{balancedonly}) && defined($opts->{autoadd})){
	print STDERR "Warning: automatically added compounds will have no formula and lead to the automatic rejection of reactions\n";
    }

    #processing table
    my $mergeto = [];
    if (defined($opts->{mergeto})) {
	$mergeto = ModelSEED::utilities::translateArrayOptions({
	    option => $opts->{mergeto},
	    delimiter => ","});
    }

    #creating namespaces if they don't exist
    if(!$bio->queryObject("aliasSets",{name => $opts->{rxnnamespace},attribute=>"reactions"})){
	$bio->add("aliasSets",{
	    name => $opts->{rxnnamespace},
	    source => $opts->{rxnnamespace},
	    attribute => "reactions",
	    class => "Reaction"});
    }

    foreach my $merge (@$mergeto){
	next if $bio->queryObject("aliasSets",{name => $merge, attribute=>"reactions"});
	$bio->add("aliasSets",{
	    name => $merge,
	    source => $merge,
	    attribute => "reactions",
	    class => "Reaction"});
    }

    if(!$bio->queryObject("aliasSets",{name => "name", attribute=>"reactions"})){
	$bio->add("aliasSets",{
	    name => "name",
	    source => "name",
	    attribute => "reactions",
	    class => "Reaction"});
    }

    my $headingTranslation = {
    	name => "names",
	enzyme => "enzymes",
	database => "id"
    };
    for (my $i=0; $i < @{$tbl->{data}}; $i++) {
        my $rxnData = {
	    reactionIDaliasType => $opts->{rxnnamespace},
	    mergeto => $mergeto,
	    addmergealias => $opts->{addmergealias},
	    balancedonly => $opts->{balancedonly}
	};
        if (defined($opts->{cpdnamespace})) {
        	$rxnData->{equationAliasType} = $opts->{cpdnamespace};
        }else{
	    $rxnData->{equationAliasType} = $opts->{rxnnamespace};
	}
	$rxnData->{autoadd} = 1 if $opts->{autoadd};

        for (my $j=0; $j < @{$tbl->{headings}}; $j++) {
            my $heading = lc($tbl->{headings}->[$j]);
            if (defined($headingTranslation->{$heading})) {
            	$heading = $headingTranslation->{$heading};
            }
            if ($heading eq "names" || $heading eq "enzymes") {
	            $rxnData->{$heading} = [ map { $_ =~ s/^\s+//; $_ =~ s/\s+$//; $_ } split(/\|/,$tbl->{data}->[$i]->[$j])];
            } else {
		my $data = [ map { $_ =~ s/^\s+//; $_ =~ s/\s+$//; $_ } $tbl->{data}->[$i]->[$j] ];
		if($heading eq "compartment"){
		    $data->[0] =~ s/^\[//;
		    $data->[0] =~ s/\]$//;
		}
		$rxnData->{$heading} = $data;
            }
        }
	#Not adding biomass reactions by default
	next if $rxnData->{id}->[0] =~ /biomass/i || $rxnData->{id}->[0] =~ /^R_BIO/;

        my $rxn = $bio->addReactionFromHash($rxnData);
    }

    $self->save_bio($bio);
}

1;
