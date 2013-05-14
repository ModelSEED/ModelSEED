package ModelSEED::App::mseed::Command::history;
use strict;
use common::sense;
use Try::Tiny;
use List::Util;
use JSON::XS;
use ModelSEED::utilities qw( config args verbose set_verbose translateArrayOptions);
use base 'ModelSEED::App::MSEEDBaseCommand';
sub abstract { return "Return references to all previous versions of an object."; }
sub usage_desc { return "ms history [object id] [options]"; }
sub description { return <<END;
Return a list of references to all previous versions of an object.
END
}
sub options {
    return (
        ["date|d", "Include a timestamp for when the objects was saved"],
    );
}
sub sub_execute {
    my ($self, $opts, $args) = @_;
	my $id = shift(@{$args});
    my $unseen_ancestors = [$id];
    my $seen_ancestors = {};
    my $list = [];
    my $type;
    while(my $ancestor = shift @$unseen_ancestors) {
        $seen_ancestors->{$ancestor} = 1;
        my $object = $self->store()->objectManager()->get_data($ancestor);
        next unless(defined($object));
        my $values = [ $ancestor ];
        push(@$values, $object->{modDate}) if($opts->{date});
        print join("\t", @$values) . "\n";
        my $refs = [
            map { $_->ref }
            map { ModelSEED::Reference->new( uuid => $_, type => $type ) }
                @{ $object->{ancestor_uuids} || [] }
        ];
        foreach my $ref (@$refs) {
            next if defined($seen_ancestors->{$ref});
            push(@$unseen_ancestors, $ref);
        }
    }
}

1;
