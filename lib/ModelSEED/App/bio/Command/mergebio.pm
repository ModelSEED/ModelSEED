package ModelSEED::App::bio::Command::mergebio;
use strict;
use common::sense;
use base 'App::Cmd::Command';
use Class::Autouse qw(
    ModelSEED::Store
    ModelSEED::Auth::Factory
    ModelSEED::App::Helpers
);
use ModelSEED::utilities qw( verbose set_verbose );
sub abstract { return "Merge two biochemistries into a nonredundant set" }
sub usage_desc { return "bio mergebio [ < biochemistry | biochemistry ] [ biochemistry2 ]"; }
sub opt_spec {
    return (
    	["noaliastransfer|n", "Do not transfer aliases to merged compound"],
    	["verbose|v", "Print messages with progress"],
        ["saveas|a:s", "New name the results should be saved to"],
        ["dryrun|d", "Donot save results in database"],
        ["help|h|?", "Print this usage information"],
    );
}

sub execute {
    my ($self, $opts, $args) = @_;
    if ($opts->{verbose}) {
        set_verbose(1);
    	delete $opts->{verbose};
    }
    my $auth  = ModelSEED::Auth::Factory->new->from_config;
    my $store = ModelSEED::Store->new(auth => $auth);
    my $helper = ModelSEED::App::Helpers->new();
    my ($biochemistry,my $ref) = $helper->get_object("biochemistry", $args, $store);
    #Checking for arguments
    $self->usage_error("Must specify an biochemistry to use") unless(defined($biochemistry));
    $self->usage_error("Must specify an biochemistry to be merged") unless(defined($args->[1]));
    if ($args->[1] !~ m/^biochemistry/) {
    	$args->[1] = $helper->process_ref_string($args->[1], "biochemistry", $auth->username);
    }
    #Getting biochemistry
    my $otherbio = $store->get_object($args->[1]);
  	if (!defined($otherbio)) {
  		$self->usage_error("Specified biochemistry not found!") unless(defined($biochemistry));
  	}
    $biochemistry->mergeBiochemistry($otherbio);
    if (defined($opts->{saveas})) {
    	$ref = $helper->process_ref_string($opts->{save}, "biochemistry", $auth->username);
    	verbose("Saving biochemistry with merged compounds as ".$ref."...");
		$store->save_object($ref,$biochemistry);
    } elsif (!defined($opts->{dryrun})) {
    	verbose("Saving over original biochemistry with merged biochmistry...");
    	$store->save_object($ref,$biochemistry);
    }
}

1;
