package ModelSEED::App::bio::Command::addrxntable;
use strict;
use common::sense;
use ModelSEED::utilities qw( args verbose set_verbose );
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
        ["namespace|n:s", "Name space for aliases added"],
        ["autoadd|a","Automatically add any missing compounds to DB"],
        ["mergeto|m:s", "Name space of identifiers used for merging compounds"],
        ["verbose|v", "Print verbose status information"]
    );
}

sub execute {
    my ($self, $opts, $args) = @_;
    my $auth  = ModelSEED::Auth::Factory->new->from_config;
    my $store = ModelSEED::Store->new(auth => $auth);
    my $helper = ModelSEED::App::Helpers->new();
    my ($biochemistry, $ref) = $helper->get_object("biochemistry", $args, $store);
    $self->usage_error("Must specify an biochemistry to use") unless(defined($biochemistry));
    $self->usage_error("Must specify a valid filename for reaction table") unless(defined($args->[1]) && -e $args->[1]);

    #verbosity
    set_verbose(1) if $opts->{verbose};

    #load table
    my $tbl = ModelSEED::utilities::LOADTABLE($args->[1],"\\t");

    #set namespace
    if (!defined($opts->{namespace})) {
    $opts->{namespace} = $args->[0];
    print STDERR "Warning: no namespace passed.  Using biochemistry name by default: ".$opts->{namespace}."\n";
    } 

    #creating namespaces if they don't exist
    if(!$biochemistry->queryObject("aliasSets",{name => $opts->{namespace},attribute=>"reactions"})){
    $biochemistry->add("aliasSets",{
        name => $opts->{namespace},
        source => $opts->{namespace},
        attribute => "reactions",
        class => "Reaction"});
    }
    if(defined($opts->{mergeto}) && !$biochemistry->queryObject("aliasSets",{name => $opts->{mergeto},attribute=>"reactions"})){
    $biochemistry->add("aliasSets",{
        name => $opts->{mergeto},
        source => $opts->{mergeto},
        attribute => "reactions",
        class => "Reaction"});
    }

    for (my $i=0; $i < @{$tbl->{data}}; $i++) {
        my $rxnData = {aliasType => $opts->{namespace}};
        for (my $j=0; $j < @{$tbl->{headings}}; $j++) {
            my $heading = lc($tbl->{headings}->[$j]);
            if ($heading =~ /names?/ || $heading =~ /enzymes?/) {
            $heading="names" if $heading eq "name";
            $heading="enzymes" if $heading eq "enzyme";
            $rxnData->{$heading} = [split(/\|/,$tbl->{data}->[$i]->[$j])];
            } else {
            $rxnData->{$heading} = [$tbl->{data}->[$i]->[$j]];
            }
        }
        my $rxn = $biochemistry->addReactionFromHash($rxnData,$opts->{mergeto});
    }

    if (defined($opts->{saveas})) {
        $ref = $helper->process_ref_string($opts->{save}, "biochemistry", $auth->username);
        verbose "Saving biochemistry with new reactions as ".$ref."...\n";
    $store->save_object($ref,$biochemistry);
    } else {
        verbose "Saving over original biochemistry with new reactions...\n";
        $store->save_object($ref,$biochemistry);
    }
}

1;
