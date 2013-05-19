package ModelSEED::App::bio::Command::aliasSet;
use strict;
use common::sense;
use ModelSEED::App::bio;
use base 'ModelSEED::App::BioBaseCommand';
use Class::Autouse qw(
    ModelSEED::MS::Factories::ExchangeFormatFactory
);
use ModelSEED::utilities;
sub abstract { return "Functions on alias sets"; }
sub usage_desc { return "bio aliasSet [ biochemistry id ] [ options ]";}
sub options {
    return (
        ["validate", "Run validation logic on alias set"],
        ["list", "List available alias sets"],
        ["store|s:s", "Identify which store to save the annotation to"],
        ["mapping|m:s", "Select the preferred mapping object to use when importing the annotation"],
        ["help|h|?", "Print this usage information"],
    );
}
sub sub_execute {
    my ($self, $opts, $args,$bio) = @_;
    if ($opts->{validate}) {
        $self->_validate($bio, $args, $opts); 
    } elsif($opts->{list}) {
        $self->_list($bio, $args, $opts);
    }
}

sub _validate {
    my ($self, $bio, $aliasSets, $opts) = @_;
    $bio = ModelSEED::MS::Biochemistry->new($bio);
    if(!defined($aliasSets)) {
        $aliasSets = [ map { $_->type } @{$bio->compoundAliasSets} ];
        push(@$aliasSets, [ map { $_->type } @{$bio->reactionAliasSets} ]);
    }
    my $aliasSetMap = { map { $_ => 1 } @$aliasSets };
    foreach my $set (@{$bio->reactionAliasSets}) {
        if(defined($aliasSetMap->{$set->type})) {
            my $errors = $set->validate();
            if(@$errors) {
                print "Errors in ".$set->type."\n";
                print join("\n", $errors);
            }
        }
    }
    foreach my $set (@{$bio->compoundAliasSets}) {
        if(defined($aliasSetMap->{$set->type})) {
            my $errors = $set->validate();
            if(@$errors) {
                print "Errors in ".$set->type."\n";
                print join("\n", $errors);
            }
        }
    }
}

sub _list {
    my ($self, $bio, $aliasSets, $opts) = @_;
    my $set = {};
    map { $set->{$_->{type}} = 1 } @{$bio->{compoundAliasSets}};
    map { $set->{$_->{type}} = 1 } @{$bio->{reactionAliasSets}};
    print join("\n", sort keys %$set);
}

1;
