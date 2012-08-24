package ModelSEED::App::mseed::Command::save;
use Try::Tiny;
use List::Util;
use JSON;
use Class::Autouse qw(
    ModelSEED::App::Helpers
    ModelSEED::Reference
    ModelSEED::Auth::Factory
    ModelSEED::Store
);
use base 'App::Cmd::Command';

sub abstract { return "Save JSON data to a reference"; }

sub usage_desc { return "ms save [ref] < JSON"; }

sub description { return <<END;
Save JSON data to a reference.
END
}


sub opt_spec {
    return (
        ["help|h|?", "Print this usage information"],
    );
}
sub execute {
    my ($self, $opts, $args) = @_;
    print($self->usage) && exit if $opts->{help};
    my $auth = ModelSEED::Auth::Factory->new->from_config;
    my $store = ModelSEED::Store->new(auth => $auth);
    my $helpers = ModelSEED::App::Helpers->new;
    $self->usage_error("Must provide a reference") unless @$args == 1;
    my $refstr = shift @$args;
    my $ref = ModelSEED::Reference->new(ref => $refstr);
    my $ref_base_type = $ref->base_types->[0];
    my $fh = *STDIN;
    if($opts->{file}) {
        open($fh, "<", $opts->{file}) or
            die "Could not open file: " .$opts->{file} . ", $@\n";
    }
    my $object;
    {
        local $\;
        my $str = <$fh>;
        my $perl = JSON->new->utf8(1)->decode($str);
        close($fh);
        $object = $store->create($ref_base_type, $perl);
    }
    $store->save_object($ref, $object) if defined $object;
}

1;
