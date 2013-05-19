package ModelSEED::App::mseed::Command::get;
use strict;
use common::sense;
use Try::Tiny;
use List::Util;
use JSON::XS;
use IO::Compress::Gzip qw(gzip);
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
        ["zip|z", "Zip"],
    );
}

sub sub_execute {
    my ($self, $opts, $args) = @_;
    my $refs = $args;
    $self->usage_error("Must specify reference") unless(defined($args->[0]));

    my $refs = $args;
    my $data = $self->get_data({"reference" => $refs->[0]});
    my $JSON = JSON::XS->new->utf8(1);
    $JSON->pretty(1) if($opts->{pretty});
    if($opts->{zip}) {
    	my $string = $JSON->encode($data);
    	my $gzip_obj;
    	gzip \$string => \$gzip_obj;
    	print $gzip_obj;
    } else {
    	print $JSON->encode($data);
    }
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
