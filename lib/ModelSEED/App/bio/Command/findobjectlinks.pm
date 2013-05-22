package ModelSEED::App::bio::Command::findobjectlinks;
use strict;
use common::sense;
use ModelSEED::App::bio;
use base 'ModelSEED::App::BioBaseCommand';
use Class::Autouse qw(
    ModelSEED::MS::Factories::ExchangeFormatFactory
    ModelSEED::MS::Model
);
use ModelSEED::utilities;
sub abstract { return "Lists all objects th" }
sub usage_desc { return "bio findobjectlinks [ biochemistry id ] [object] [type]"; }
sub options {
    return ();
}
sub sub_execute {
    my ($self, $opts, $args,$bio) = @_;
    $self->usage_error("ID of first compound to be merged") unless(defined($args->[0]));
    $self->usage_error("ID of second compound to be merged") unless(defined($args->[1]));
    my $cpdone = $bio->getObject("compounds",$args->[0]);
    $self->usage_error("Compound ".$args->[0]." not found!") unless(defined($cpdone));
    my $cpdtwo = $bio->getObject("compounds",$args->[1]);
    $self->usage_error("Compound ".$args->[1]." not found!") unless(defined($cpdtwo));
    my $olduuid = $cpdtwo->uuid();
    my $newuuid = $cpdone->uuid();
    print "Removing compound from biochemistry...\n" if($opts->{verbose});
    $bio->remove("compounds",$cpdtwo);
    my $transfer = 1;
    if (defined($opts->{noaliastransfer}) && $opts->{noaliastransfer} == 1) {
    	$transfer = 0;
    }
    print "Updating links...\n" if($opts->{verbose});
    $bio->updateLinks("Compound",$olduuid,$newuuid,1,$transfer);
    $bio->forwardedLinks()->{$olduuid} = $newuuid;
    $self->save_bio($bio);
}

1;
