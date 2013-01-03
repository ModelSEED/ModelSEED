package ModelSEED::App::bio::Command::addrxntable;
use strict;
use common::sense;
use ModelSEED::utilities qw( args verbose set_verbose translateArrayOptions);
use base 'App::Cmd::Command';
use Class::Autouse qw(
    ModelSEED::Store
    ModelSEED::Auth::Factory
    ModelSEED::App::Helpers
);
sub abstract { return "Reads in table of reaction data and adds them to the database" }
sub usage_desc { return "bio addrxntable [< biochemistry | biochemistry] [filename] [options]"; }
sub opt_spec {
    return (
        ["saveas|a:s", "New alias for altered biochemistry"],
        ["rxnnamespace|r:s", "Name space for reaction IDs"],
        ["cpdnamespace|c:s", "Name space for compound IDs in equation"],
        ["autoadd|a","Automatically add any missing compounds to DB"],
        ["mergeto|m:s@", "Name space of identifiers used for merging reactions. Comma delimiter accepted."],
        ["verbose|v", "Print verbose status information"],
        ["dry|d", "Perform a dry run; that is, do everything but saving"],
    );
}

sub execute {
    my ($self, $opts, $args) = @_;
    my $auth  = ModelSEED::Auth::Factory->new->from_config;
    my $store = ModelSEED::Store->new(auth => $auth);
    my $helper = ModelSEED::App::Helpers->new();

    $self->usage_error("Must specify a biochemistry to use") unless $args->[0];
    my ($biochemistry, $ref) = $helper->get_object("biochemistry", $args, $store);
    $self->usage_error("Biochemistry ".$args->[0]." not found") unless defined($biochemistry);
    $self->usage_error("Must specify a valid filename for reaction table") unless(defined($args->[1]) && -e $args->[1]);

    #verbosity
    set_verbose(1) if $opts->{verbose};

    #load table
    my $tbl = ModelSEED::utilities::LOADTABLE($args->[1],"\\t");

    #set namespace
    if (!defined($opts->{rxnnamespace})) {
	$opts->{rxnnamespace} = $args->[0];
	print STDERR "Warning: no namespace passed.  Using biochemistry name by default: ".$opts->{rxnnamespace}."\n";
    } 

    #processing table
    my $mergeto = [];
    if (defined($opts->{mergeto})) {
	$mergeto = translateArrayOptions({
	    option => $opts->{mergeto},
	    delimiter => ","});
    }

    #creating namespaces if they don't exist
    if(!$biochemistry->queryObject("aliasSets",{name => $opts->{rxnnamespace},attribute=>"reactions"})){
	$biochemistry->add("aliasSets",{
	    name => $opts->{rxnnamespace},
	    source => $opts->{rxnnamespace},
	    attribute => "reactions",
	    class => "Reaction"});
    }

    foreach my $merge (@$mergeto){
	next if $biochemistry->queryObject("aliasSets",{name => $merge, attribute=>"reactions"});
	$biochemistry->add("aliasSets",{
	    name => $merge,
	    source => $merge,
	    attribute => "reactions",
	    class => "Reaction"});
    }

    if(!$biochemistry->queryObject("aliasSets",{name => "name", attribute=>"reactions"})){
	$biochemistry->add("aliasSets",{
	    name => "name",
	    source => "name",
	    attribute => "reactions",
	    class => "Reaction"});
    }

    my $headingTranslation = {
    	name => "names",
	enzyme => "enzymes"
    };
    for (my $i=0; $i < @{$tbl->{data}}; $i++) {
        my $rxnData = {reaciontIDaliasType => $opts->{rxnnamespace}, mergeto => $mergeto};
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
	            $rxnData->{$heading} = [split(/\|/,$tbl->{data}->[$i]->[$j])];
            } else {
		    $rxnData->{$heading} = [$tbl->{data}->[$i]->[$j]];
            }
        }
        my $rxn = $biochemistry->addReactionFromHash($rxnData);
    }

    if (defined($opts->{saveas})) {
        $ref = $helper->process_ref_string($opts->{save}, "biochemistry", $auth->username);
        verbose "Saving biochemistry with new reactions as ".$ref."...\n";
	$biochemistry->name($opts->{saveas});
    	$store->save_object($ref,$biochemistry);
    } elsif (!defined($opts->{dry}) || $opts->{dry} == 0) {
        verbose "Saving over original biochemistry with new reactions...\n";
        $store->save_object($ref,$biochemistry);
    }
}

1;
