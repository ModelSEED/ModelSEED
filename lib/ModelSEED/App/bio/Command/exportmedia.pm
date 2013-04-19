package ModelSEED::App::bio::Command::exportmedia;
use strict;
use common::sense;
use ModelSEED::App::bio;
use base 'ModelSEED::App::BioBaseCommand';
use Class::Autouse qw(
    ModelSEED::MS::Factories::ExchangeFormatFactory
    ModelSEED::MS::Model
);
use ModelSEED::utilities qw( config error args verbose set_verbose translateArrayOptions);
sub abstract { return "Exports biochemistry media data to various formats" }
sub usage_desc { return "bio exportmedia [ biochemistry id ] [media IDs with | delimiter] [format:exchange/readable/html/json] [options]"; }
sub options {
    return ();
}
sub sub_execute {
    my ($self, $opts, $args,$bio) = @_;
    $self->usage_error("Must specify format for media export") unless(defined($args->[1]));
    my $medias = [split(/\|/,$args->[0])];
    if (@{$medias} == 1 && lc($medias->[1]) eq "all") {
    	$medias = [];
    	my $meds = $bio->media();
    	foreach my $med (@{$meds}) {
    		push(@{$medias},$med->id());
    	}
    }
    foreach my $media (@{$medias}) {
    	my $med = $bio->queryObject("media",{id => $media});
    	if (!defined($med)) {
    		print STDERR "Could not find media: ".$media."\n";
    	} else {
	    	print $med->export({
	    		format => $args->[2]
	    	})."\n";
    	}
    }
}

1;
