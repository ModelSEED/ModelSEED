package ModelSEED::App::bio::Command::findobjectlinks;
use strict;
use common::sense;
use base 'App::Cmd::Command';
use Class::Autouse qw(
    ModelSEED::Store
    ModelSEED::Auth::Factory
    ModelSEED::App::Helpers
);
sub abstract { return "Lists all objects th" }
sub usage_desc { return "bio findobjectlinks [< biochemistry | biochemistry] [object] [type]"; }
sub opt_spec {
    return (
    	["verbose|v", "Print messages with progress"]
    );
}

sub execute {
    my ($self, $opts, $args) = @_;
    my $auth  = ModelSEED::Auth::Factory->new->from_config;
    my $store = ModelSEED::Store->new(auth => $auth);
    my $helper = ModelSEED::App::Helpers->new();
    my ($biochemistry,my $ref) = $helper->get_object("biochemistry", $args, $store);
    $self->usage_error("Must specify an biochemistry to use") unless(defined($biochemistry));
    $self->usage_error("ID of first compound to be merged") unless(defined($args->[1]));
    $self->usage_error("ID of second compound to be merged") unless(defined($args->[2]));
    my $cpdone = $biochemistry->getObject("compounds",$args->[1]);
    $self->usage_error("Compound ".$args->[1]." not found!") unless(defined($cpdone));
    my $cpdtwo = $biochemistry->getObject("compounds",$args->[2]);
    $self->usage_error("Compound ".$args->[2]." not found!") unless(defined($cpdtwo));
    my $olduuid = $cpdtwo->uuid();
    my $newuuid = $cpdone->uuid();
    print "Removing compound from biochemistry...\n" if($opts->{verbose});
    $biochemistry->remove("compounds",$cpdtwo);
    my $transfer = 1;
    if (defined($opts->{noaliastransfer}) && $opts->{noaliastransfer} == 1) {
    	$transfer = 0;
    }
    print "Updating links...\n" if($opts->{verbose});
    $biochemistry->updateLinks("Compound",$olduuid,$newuuid,1,$transfer);
    $biochemistry->forwardedLinks()->{$olduuid} = $newuuid;
    if (defined($opts->{saveas})) {
    	$ref = $helper->process_ref_string($opts->{save}, "biochemistry", $auth->username);
    	print STDERR "Saving biochemistry with merged compounds as ".$ref."...\n" if($opts->{verbose});
		$store->save_object($ref,$biochemistry);
    } else {
    	print STDERR "Saving over original biochemistry with merged compounds...\n" if($opts->{verbose});
    	$store->save_object($ref,$biochemistry);
    }
}

1;
