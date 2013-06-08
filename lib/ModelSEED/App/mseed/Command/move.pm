package ModelSEED::App::mseed::Command::move;
use strict;
use common::sense;
use base 'ModelSEED::App::MSEEDBaseCommand';
use Class::Autouse qw(
	ModelSEED::MS::BaseObject
);
use JSON::XS;
sub abstract { return "Moves object to new ID or workspace or store" }
sub usage_desc { return "ms move [object reference]" }
sub opt_spec { return (
        ["newid|i=s", "New id for the object"],
        ["newworkspace|w=s", "New workspace for the object"],
        ["newstore|n=s", "Store to which object should be copied"],
    );
}
sub sub_execute {
    my ($self, $opts, $args) = @_;
    $self->usage_error("Must provide object ID") unless(defined($args->[0]));
    my $obj = $self->get_object({
   		reference => $args->[0],
   		store => $self->store()
   	});
   	my $output = $self->store()->parseReference($args->[0]);
   	if (defined($opts->{newstore})) {
   		$output->{store} = $opts->{newstore};
   	}
   	if (defined($opts->{newid})) {
   		$output->{id} = $opts->{newid};
   	}
   	if (defined($opts->{newworkspace})) {
  		$output->{workspace} = $opts->{newworkspace};
   	}
   	$obj->move($output);
}

1;
