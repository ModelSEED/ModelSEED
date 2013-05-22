package ModelSEED::App::mapping::Command::bio;
use strict;
use common::sense;
use ModelSEED::App::mapping;
use base 'ModelSEED::App::MappingBaseCommand';
sub abstract { return "Returns the associated biochemistry object" }
sub usage_desc { return "mapping bio [mapping id] [options]" }
sub options {
    return ();
}
sub sub_execute {
    my ($self, $opts, $args,$map) = @_;
    my $bio = $self->get_object({
    	type => "Biochemistry",
    	reference => $map->biochemistry_uuid(),
    	store => $opts->{store}
    });
	print "Mapping linked to biochemistry:\n".$bio->msStoreID()."\n";
}

1;
