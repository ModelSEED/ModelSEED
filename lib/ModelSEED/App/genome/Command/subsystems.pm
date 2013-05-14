package ModelSEED::App::genome::Command::subsystems;
use strict;
use common::sense;
use ModelSEED::App::genome;
use base 'ModelSEED::App::GenomeBaseCommand';
use ModelSEED::utilities qw( config error args verbose set_verbose translateArrayOptions);
sub abstract { return "Get the list of subsystems for an annotated genome" }
sub usage_desc { return "genome subsystems [genome id] [options]" }
sub description { return <<END;
Print the subsystems that this genome has annotated features for.
END
}
sub options {
    return ();
}
sub sub_execute {
    my ($self, $opts, $args,$anno) = @_;
    print map { $_->type . "\t" . $_->name ."\n" } @{$anno->subsystems};
}

1;