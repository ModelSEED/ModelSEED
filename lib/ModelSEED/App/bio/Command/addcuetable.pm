package ModelSEED::App::bio::Command::addcuetable;
use strict;
use common::sense;
use ModelSEED::App::bio;
use base 'ModelSEED::App::BioBaseCommand';
use ModelSEED::utilities;
sub abstract { return "Reads in table of compound data and adds them to the database" }
sub usage_desc { return "bio addcpdtable [< biochemistry | biochemistry] [filename] [options]"; }
sub options {
    return (
	["separator|t=s", "Column separator for file. Default is tab"],
    );
}

sub sub_execute {
    my ($self, $opts, $args, $bio) = @_;
    $self->usage_error("Must specify a valid filename for cue table") unless(defined($args->[0]) && -e $args->[0]);

    #verbosity
    ModelSEED::utilities::set_verbose(1) if $opts->{verbose};

    #load table
    my $separator="\\\t";
    $separator = $opts->{separator}  if exists $opts->{separator};
    my $tbl = ModelSEED::utilities::LOADTABLE($args->[0],$separator);

    if(scalar(@{$tbl->{data}->[0]})<2){
	$tbl = ModelSEED::utilities::LOADTABLE($args->[0],"\\\;");
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
        my $cue = $bio->addCueFromHash($cueData);
    }

    $self->save_bio($bio);
}

1;
