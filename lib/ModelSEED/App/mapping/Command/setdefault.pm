package ModelSEED::App::mapping::Command::setdefault;
use strict;
use common::sense;
use ModelSEED::App::mapping;
use base 'ModelSEED::App::MappingBaseCommand';
use ModelSEED::utilities qw( config error args verbose set_verbose translateArrayOptions);
sub abstract { return "Returns the associated biochemistry object" }
sub usage_desc { return "mapping setdefault [mapping id] [options]" }
sub options {
    return ();
}
sub sub_execute {
    my ($self, $opts, $args,$map) = @_;
    my $config = config();
	$self->store()->defaultMapping_ref($map->msStoreID());
	$config->save_to_file();
}

1;