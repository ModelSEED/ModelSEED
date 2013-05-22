package ModelSEED::App::genome::Command::mapping;
use strict;
use common::sense;
use ModelSEED::App::genome;
use base 'ModelSEED::App::GenomeBaseCommand';
sub abstract { return "Prints the name of the mapping linked to the genome" }
sub usage_desc { return "genome mapping [genome id] [options]" }
sub options {
    return ();
}
sub sub_execute {
    my ($self, $opts, $args,$anno) = @_;
    my $map = $self->get_object({
    	type => "Mapping",
    	reference => "Mapping/".$anno->mapping_uuid(),
    });
	print "Genome linked to mapping:\n".$map->msStoreID()."\n";
}

1;
