package ModelSEED::App::stores::Command::list;
use strict;
use common::sense;
use Class::Autouse qw(ModelSEED::Configuration);
use base 'App::Cmd::Command';
sub abstract { "List current stores in order of priority" }
sub opt_spec {
    [ 'verbose|v', "print detailed configuration for each store" ],
    ["help|h|?", "Print this usage information"],
}
sub execute {
    my ($self, $opts, $args) = @_;
    print($self->usage) && exit if $opts->{help};
    my $ms = ModelSEED::Configuration->new();    
    my $stores = $ms->config->{stores};
    if($opts->{verbose}) {
        print map { _detailed($_) . "\n" } @$stores;
    } else {
        print map { $_->{name} . "\n" } @$stores;
    }
}

sub _detailed {
    my ($s) = @_;
    # name    key=value key=value
    my $hide = { name => 1, class => 1 };
    my @attrs = grep { !$hide->{$_} } keys %$s;
    my $string = join(" ", map { $_ . '=' . $s->{$_} } @attrs);
    return $s->{name} . "\t" . $string;
}

1;
