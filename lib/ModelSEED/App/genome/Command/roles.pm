package ModelSEED::App::genome::Command::roles;
use strict;
use common::sense;
use ModelSEED::App::genome;
use base 'ModelSEED::App::GenomeBaseCommand';
sub abstract { return "Get the list of roles for an annotated genome" }
sub usage_desc { return "genome roles [genome id] [options]" }
sub description { return <<END;
Print the roles that this genome has annotated features for.
END
}
sub options {
    return ();
}
sub sub_execute {
    my ($self, $opts, $args,$anno) = @_;
    print map { $_->name ."\n" } @{$anno->roles()};
}

1;
