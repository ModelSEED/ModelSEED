package ModelSEED::App::mseed::Command::pp;
use strict;
use common::sense;
use base 'App::Cmd::Command';
use JSON::XS;
sub abstract { return "Pretty print JSON object" }
sub usage_desc { return "ms pp < object.json" }
sub opt_spec { return (
        ["help|h|?", "Print this usage information"],
    );
}
sub execute {
    my ($self, $opts, $args) = @_;
    print($self->usage) && exit if $opts->{help};
    my $str;
    {
        local $\;
        $str = <STDIN>;
    }
    my $j = JSON::XS->new->utf8->pretty(1);
    print $j->encode($j->decode($str)) . "\n";
}

1;
