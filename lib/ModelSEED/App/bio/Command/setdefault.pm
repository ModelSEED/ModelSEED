package ModelSEED::App::bio::Command::setdefault;
use strict;
use common::sense;
use ModelSEED::App::bio;
use base 'ModelSEED::App::BioBaseCommand';
use ModelSEED::utilities;
sub abstract { return "Sets the default biochemistry for the current user" }
sub usage_desc { return "bio setdefault [ biochemistry id ] [ options ]" }
sub description { return <<END;
END
}
sub options {
    return ();
}
sub sub_execute {
    my ($self, $opts, $args,$bio) = @_;
    my $config = config();
	$self->store()->defaultBiochemistry_ref($bio->msStoreID());
	$config->save_to_file();
}

1;
