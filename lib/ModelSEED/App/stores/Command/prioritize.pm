package ModelSEED::App::stores::Command::prioritize;
use strict;
use common::sense;
use Class::Autouse qw(ModelSEED::Configuration);
use base 'App::Cmd::Command';
my $MS = ModelSEED::Configuration->new;
sub abstract { "Set the storage priority" }
sub usage_desc { "%c prioritize [store] [store] ..." }
sub opt_spec { return (
        ["help|h|?", "Print this usage information"],
    );
}

sub validate_args {
    my ($self, $opts, $args) = @_;
    print($self->usage) && exit if $opts->{help};
    my $stores = $MS->config->{stores} || [];
    my %map = map { $_->{name} => $_ } @$stores; 
    foreach my $name (@$args) {
        unless (defined($map{$name})) {
            $self->usage_error("No Storage interface named $name!");
        }
    }
}

sub execute {
    my ($self, $opt, $args) = @_;
    my $stores = $MS->config->{stores} || [];
    my $newStore = [];
    my %map = map { $_->{name} => $_ } @$stores; 
    foreach my $name (@$args) {
        push(@$newStore, $map{$name});
        delete $map{$name};
    }
    push(@$newStore, values %map);
    $MS->config->{stores} = $newStore;
    $MS->save();
}
