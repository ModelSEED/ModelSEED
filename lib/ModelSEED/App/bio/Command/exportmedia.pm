package ModelSEED::App::bio::Command::exportmedia;
use strict;
use common::sense;
use base 'App::Cmd::Command';
use ModelSEED::utilities qw( verbose set_verbose error );
use Class::Autouse qw(
    ModelSEED::Store
    ModelSEED::Auth::Factory
    ModelSEED::App::Helpers
);
sub abstract { return "Exports biochemistry media data to various formats" }
sub usage_desc { return "bio exportmedia [biochemistry] [media IDs with | delimiter] [format:exchange/readable/html/json] [options]"; }
sub opt_spec {
    return (
        ["help|h|?", "Print this usage information"],
    );
}

sub execute {
    my ($self, $opts, $args) = @_;
    print($self->usage) && exit if $opts->{help};
    my $auth  = ModelSEED::Auth::Factory->new->from_config;
    my $store = ModelSEED::Store->new(auth => $auth);
    my $helper = ModelSEED::App::Helpers->new();
	$self->usage_error("Must specify ID of media to be exported") unless(defined($args->[1]));
    $self->usage_error("Must specify format for biochemistry export") unless(defined($args->[2]));
    my ($biochemistry,my $ref) = $helper->get_object("biochemistry", $args, $store);
    $self->usage_error("Must specify an biochemistry to use") unless(defined($biochemistry));
    my $medias = [split(/\|/,$args->[1])];
    if (@{$medias} == 1 && lc($medias->[1]) eq "all") {
    	$medias = [];
    	my $meds = $biochemistry->media();
    	foreach my $med (@{$meds}) {
    		push(@{$medias},$med->id());
    	}
    }
    foreach my $media (@{$medias}) {
    	my $med = $biochemistry->queryObject("media",{id => $media});
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
