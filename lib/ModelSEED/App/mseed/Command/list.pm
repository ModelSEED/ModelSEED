package ModelSEED::App::mseed::Command::list;
use strict;
use common::sense;
use Try::Tiny;
use List::Util qw(max);
use ModelSEED::Exceptions;
use Class::Autouse qw(
    ModelSEED::Reference
    ModelSEED::Auth::Factory
    ModelSEED::Store
    ModelSEED::App::Helpers
);
use base 'App::Cmd::Command';


sub abstract { return "List and retrive objects from workspace or datastore."; }
sub opt_spec {
    return (
        ["verbose|v", "Print out additional information about the object, tab-delimited"],
        ["mine", "Only list items that I own"],
        ["with|w:s@", "Append a tab-delimited column with this attribute"],
        ["help|h|?", "Print this usage information"],
    );
}

sub execute {
    my ($self, $opts, $args) = @_;
    print($self->usage) && exit if $opts->{help};
    my $auth = ModelSEED::Auth::Factory->new->from_config();
    my $store  = ModelSEED::Store->new(auth => $auth);
    my $helpers = ModelSEED::App::Helpers->new;

    my $arg = shift @$args;
    my $ref;
    try {
        $ref = ModelSEED::Reference->new(ref => $arg);
    };
    if(defined($ref)) {
        # Base level collection ( want a list of aliases )
        if($ref->type eq 'collection' && 0 == @{$ref->parent_collections}) {
            my $aliases;
            if ($opts->{mine}) {
                $aliases = $store->get_aliases({ type => $ref->base, owner => $auth->username });
            } else {
                $aliases = $store->get_aliases({ type => $ref->base, owner => $auth->username });
            }
            # Construct references from alias data
            # TODO: Why isn't this part of Store / Database ?
            my $refs = [
                  map { ModelSEED::Reference->new( ref => $_ ) }
                  map { $_->{type} . "/" . $_->{owner} . "/" . $_->{alias} }
                  @$aliases
            ];
            $self->printForReferences($refs, $opts, $store);
        # Subobject listing. want a list of ids under subobject
        } elsif($ref->type eq 'collection' && @{$ref->parent_collections}) {
            my $need_object = (defined($opts->{with}) || defined($opts->{verbose}));
            my $refs;
            if ($need_object) {
                my $base_object = $store->get_object($ref->parent_objects->[0]);
                my $subtypes = $ref->base_types;
                my $subtype  = $subtypes->[@$subtypes - 1];
                my $data     = $base_object->$subtype;
                $self->printForData($ref, $data, $opts);
            } else {
                my $data = $store->get_data($ref->parent_objects->[0]);
                my $subtypes = $ref->base_types;
                my $subtype  = $subtypes->[@$subtypes - 1];
                if ($subtype eq 'ancestor_uuids') {
                    $refs = [ map { $ref->base . "/" . $_ } @{$data->{$subtype}} ];
                } else {
                    $refs = [ map { $ref->base . "/" . $_->{uuid} } @{$data->{$subtype}} ];
                }
                print join("\n", @$refs) . "\n";
            }
        # Want a breakdown of the subobjects
        } elsif($ref->type eq 'object') {
            my $data = $store->get_data($ref->base . $ref->delimiter . $ref->id);
            # Calculate the size of the padding between first and second column
            my $max =  max map { length $_ } keys %$data;
            $max += 5;
            # Print the formatted results
            foreach my $k ( keys %$data ) {
                my $v = $data->{$k};
                if(ref($v) eq 'ARRAY') {
                    printf("%-${max}s(%d)\n", ($k, scalar(@$v)));
                }
            }
        }
    } else {
        # ref was an empty string or completely invalid 
        my $aliases = $store->get_aliases({});
        exit unless(@$aliases);
        my $types = {};
        # Print counts for aliased objects
        foreach my $alias (@$aliases) {
            $types->{$alias->{type}} = 0 unless(defined($types->{$alias->{type}}));
            $types->{$alias->{type}} += 1;
        }
        printf("%-15s\t%-15s\n", ("Type", "Count"));
        foreach my $type (keys %$types) {
            printf("%-15s\t%d\n", ($type."/", $types->{$type}));
        }
    }
}

sub printForReferences {
    my ($self, $refs, $opts, $store) = @_;
    my $need_object = (defined($opts->{with}) || defined($opts->{verbose}));
    my $columns = $self->determineColumns($refs->[0], $opts);
    print join("\t", @$columns) . "\n" if (@$columns > 1);
    foreach my $ref (@$refs) {
        my $o;
        if ($need_object) {
            $o = $store->get_object($ref);
        }
        print $self->formatOutput($ref, $o, $columns); 
    }
}

sub printForData {
    my ($self, $ref, $data, $opts) = @_;
    my $columns = $self->determineColumns($ref, $opts);
    print join("\t", @$columns) . "\n" if (@$columns > 1);
    foreach my $o (@$data) {
        print $self->formatOutput($ref, $o, $columns);
    }
}


sub determineColumns {
    my ($self, $ref, $opts) = @_;
    my $types = $ref->base_types;
    my $type  = $types->[@$types - 1];
    my $with = [ "Reference" ];
    my %with = map { $_ => 1 } @$with;
    push(@$with, @{$opts->{with} || []});
    if ( $opts->{verbose} ) {
        # If we asked for verbose, print out some default attributes
        my $additional_with = $self->verboseRules($type);
        foreach my $attr (@$additional_with) {
            # Append attributes unless we've already specified them
            push(@$with, $attr) unless defined $with{$attr};
        }
    }
    return $with;
}

sub formatOutput {
    my ($self, $ref, $object, $columns) = @_;
    my $with = [ @$columns ];
    shift @$with; # Remove "Reference" column
    my $parts = [ $ref->ref ];
    foreach my $attr (@$with) {
        my $value;
        if (ref $object ne 'HASH' && $object->meta->find_attribute_by_name($attr)) {
            $value = $object->$attr; 
        } elsif(ref $object eq 'HASH') {
            $value = $object->{$attr};
            $value = '' unless defined $value;
        } else {
            ModelSEED::Exception::InvalidAttribute->throw(
                object => $object,
                invalid_attribute => $attr,
            );
        }
        push(@$parts, $value);
    }
    return join("\t", @$parts) . "\n";
}

1;
