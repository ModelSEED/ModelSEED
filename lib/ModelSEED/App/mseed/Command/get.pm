package ModelSEED::App::mseed::Command::get;
use strict;
use common::sense;
use Try::Tiny;
use List::Util;
use JSON::XS;
use ModelSEED::utilities qw( config args verbose set_verbose translateArrayOptions);

use base 'ModelSEED::App::MSEEDBaseCommand';

sub abstract { return "Get an object from workspace or datastore."; }

sub usage_desc { return "ms get [ref] [options]"; }

sub description { return <<END;
Get an object from the datastore.  
END
}

sub options {
    return (
        ["pretty|p", "Pretty-print JSON"],
    );
}

sub sub_execute {
    my ($self, $opts, $args) = @_;
	my $refs = $args;
	if (!defined($refs->[0])) {
        error("Must provide reference");
    }
	my $JSON = JSON::XS->new->utf8(1);
    $JSON->pretty(1) if($opts->{pretty});
    my $cache = {};
    my $output = [];
	foreach my $ref (@$refs) {
        my $o = $self->get_object_deep($cache,$ref);
        if(ref($o) eq 'ARRAY') {
            push(@$output, @$o);
        } else {
            push(@$output, $o);
        }
	}
    my $delimiter = "\n";
    print join($delimiter, map { $JSON->encode($_) } @$output);
	return;
}

sub get_object_deep {
    my ($self, $cache,$refstr) = @_;
    my ($ref, $found, $refstring);
    try {
        $ref = ModelSEED::Reference->new(ref => $refstr);
    };
    return unless(defined($ref));
    if($ref->type eq 'object' && @{$ref->parent_objects} == 0) {
        $refstring = $ref->base . $ref->delimiter . $ref->id;
        if(defined($cache->{$refstring})) {
            $found = $cache->{$refstring};
        } else {
            $found = $self->get_data($refstring);
        }
    } elsif($ref->type eq 'object' && @{$ref->parent_collections}) {
        $refstring = $ref->base . $ref->delimiter . $ref->id;
        my $parent_ref = $ref->parent_objects->[0];
        my $parent = $self->get_object_deep($cache,$parent_ref);
        my @sections = split($ref->delimiter, $ref->base);
        my $subtype = pop @sections;
        my $uuid = $ref->id;
        my $selection = [ grep { $_->{uuid} eq $uuid } @{$parent->{$subtype}}];
        $found = $selection->[0] || undef;
    # Reference to a collection of subobjects
    } elsif($ref->type eq 'collection' && @{$ref->parent_objects} > 0) {
        $refstring = $ref->base;
        my $last_i = @{$ref->{parent_objects}};
        my $parent_ref = $ref->parent_objects->[$last_i-1];
        my $parent = $self->get_object_deep($cache,$parent_ref);
        my @sections = split($ref->delimiter, $ref->base);
        my $subtype = pop @sections;
        $found = $parent->{$subtype};
    }
    # otherwise it's a collection, not sure what the deal is here
    return $cache->{$refstring} = $found;
}

1;
