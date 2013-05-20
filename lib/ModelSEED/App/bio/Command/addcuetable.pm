package ModelSEED::App::bio::Command::addcuetable;
use strict;
use common::sense;
use ModelSEED::utilities;
use base 'App::Cmd::Command';
use Class::Autouse qw(
    ModelSEED::Store
    ModelSEED::Auth::Factory
    ModelSEED::App::Helpers
);
sub abstract { return "Reads in table of compound data and adds them to the database" }
sub usage_desc { return "bio addcpdtable [< biochemistry | biochemistry] [filename] [options]"; }
sub opt_spec {
    return (
        ["saveas|a:s", "New alias for altered biochemistry"],
        ["verbose|v", "Print verbose status information"],
	["separator|t:s", "Column separator for file. Default is tab"],
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
    $self->usage_error("Must specify a valid filename for cue table") unless(defined($args->[1]) && -e $args->[1]);

    #verbosity
    ModelSEED::utilities::set_verbose(1) if $opts->{verbose};

    #load table
    my $separator="\\\t";
    $separator = $opts->{separator}  if exists $opts->{separator};
    my $tbl = ModelSEED::utilities::LOADTABLE($args->[1],$separator);

    if(scalar(@{$tbl->{data}->[0]})<2){
	$tbl = ModelSEED::utilities::LOADTABLE($args->[1],"\\\;");
#	$self->usage_error("Not enough columns in table, consider using a different separator");
    }

    my $headingTranslation = {
	small_molecule => "smallMolecule",
    };
    for (my $i=0; $i < @{$tbl->{data}}; $i++) {
        my $cueData = {};
        for (my $j=0; $j < @{$tbl->{headings}}; $j++) {
            my $heading = lc($tbl->{headings}->[$j]);
            if (defined($headingTranslation->{$heading})) {
            	$heading = $headingTranslation->{$heading};
            }
	    $cueData->{$heading} = [ map { $_ =~ s/^\s+//; $_ =~ s/\s+$//; $_ } $tbl->{data}->[$i]->[$j]];
        }
        my $cue = $biochemistry->addCueFromHash($cueData);
    }

    #Saving biochemistry
    if (defined($opts->{saveas})) {
        $ref = $helper->process_ref_string($opts->{saveas}, "biochemistry", $auth->username);
        ModelSEED::utilities::verbose("Saving biochemistry with new compounds as ".$ref."...\n");
	$biochemistry->name($opts->{saveas});
    	$store->save_object($ref,$biochemistry);
    } elsif (!defined($opts->{dry}) || $opts->{dry} == 0) {
        ModelSEED::utilities::verbose("Saving over original biochemistry with new compounds...\n");
        $store->save_object($ref,$biochemistry);
    }
}

1;
