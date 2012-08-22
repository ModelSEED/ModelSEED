#!/usr/bin/env perl
package QuickConvert;
=pod

=head1 QuickConvert

Find and convert MS object's non-ASCII strings

=head2 ABSTRACT

./QuickConvert.pm --reference /biochemistry/alice/foo --summary
./QuickConvert.pm --reference /biochemistry/alice/foo --save

=cut
use Moose;

use ModelSEED::Auth::Factory;
use ModelSEED::MS::Metadata::Definitions;
use ModelSEED::Store;

use IO::Prompt;
use Encode::Detect::Detector;  # Detect encoding
use Text::Iconv;               # Conversion from non-standard encodings to utf-8
use Text::Unidecode;    # Converts non-standard encodings to ascii (agresssive)
use Data::Dumper;

with 'MooseX::Getopt';

# Basic arguments ( command line too )
#
# - reference
# - auto
# - default
# - save
# - summary
# - ignore
has reference => (
    is => 'rw',
    isa => 'Str',
    required => 1,
    documentation => "Data reference to inspect over",
);

has auto => (
    is            => 'rw',
    isa           => 'Bool',
    default       => 0,
    documentation => "If set, do not prompt the user for each conversion",
);

has default => (
    is => 'rw',
    isa => 'Str',
    default => 'utf-8',
    documentation => "Set the default encoding to present, convert to.",
);

has save => (
    is => 'rw',
    isa => 'Bool',
    default => 0,
    documentation => "If set, save, otherwise don't.",
);

has summary => (
    is => 'rw',
    isa => 'Bool',
    documentation => "Just print summary of non-ASCII encodings",
);

has ignore => (
    is => 'rw',
    isa => 'ArrayRef[Str]',
    default => sub { return []; },
    documentation => "Don't even prompt for an encoding",
);

# Internal data Objects
has _store => (
    is       => 'rw',
    isa      => 'ModelSEED::Store',
    builder  => '_build_store',
    lazy     => 1,
);
has _ignore_encodings => (
    is      => 'rw',
    isa     => 'HashRef',
    builder => '_build_ignore_encodings',
    lazy    => 1,
);
has _type_defs => (
    is      => 'rw',
    isa     => 'HashRef',
    builder => '_build_type_defs',
);
has _available_encodings => (
    is => 'ro',
    isa => 'HashRef',
    builder => '_build_available_encodings',
);

sub run {
    my ($self) = @_;
    my $ingoreEncodings = { map { $_ => 1 } @{$self->ignore} };
    # Get the base object
    my $object = $self->_store->get_object($self->reference);
    die "No such object with reference ". $self->reference unless $object;
    my $ref = ModelSEED::Reference->new(ref => $self->reference);
    my $type = ucfirst $ref->base_types->[0];
    my $summary = {};
    # Process it
    $self->_process_object($type, $object, $summary); 
    # Save it we're doing that
    if ($self->save) {
        $object->save($self->reference);
    }
    # Print a summary if we're doing that
    if ($self->summary) {
        print Dumper $summary;
    }
}
    
sub _process_object {
    my ($self, $type, $object, $summary) = @_;
    # Interate over attributes
    my $attributes = $self->_get_attrs($type);
    foreach my $attr (@$attributes) {
        if($self->summary) {
            # If we're doing a summary, just let us know the encodings
            # for this type, attribute
            my $isString = $self->_attr_is_string($type, $attr);
            my $str = $object->$attr;
            my $encoding = $self->_get_encoding($str);
            if ($isString && defined($encoding)) {
                $summary->{$type}->{$attr}->{$encoding} = 0
                unless(defined($summary->{$type}->{$attr}->{$encoding}));
                $summary->{$type}->{$attr}->{$encoding} += 1;
            }
        } else {
            my $isString = $self->_attr_is_string($type, $attr);
            my $str = $object->$attr;
            my $encoding = $self->_get_encoding($str);
            if ($isString && defined $encoding) {
                if (defined $attr) {
                    print "Found $encoding on "
                      . $object->$attr
                      . " $attr, $type\n";
                    if (defined $self->_ignore_encodings->{$encoding}) {
                        print "Skipping\n";
                        next;
                    }
                    my $newStr = $self->_change($str, $encoding);
                    next unless(defined($newStr));
                    $object->$attr($newStr) if $self->save;
                }
            }
        }
    }
    # Recurse over subobjects 
    my ($subobjects, $subtypes) = $self->_get_subobjects($type, $object);
    for ( my $i = 0; $i < @$subtypes; $i++ ) {
        my $subobject = $subobjects->[$i];
        my $subtype   = $subtypes->[$i];
        if (ref $subobject eq 'ARRAY') {
            $summary = $self->_process_object($subtype, $_, $summary) for @$subobject;
        } else {
            $summary = $self->_process_object($subtype, $subobject, $summary);
        }
    }
    return $summary;
}

sub _attr_is_string {
    my ($self, $type, $attr) = @_;
    my $def = $self->_type_defs->{$type};
    my ($attrs) = grep { $_->{name} eq $attr } @{$def->{attributes}};
    my $isString = ($attrs->{type} eq "Str" || $attrs->{type} eq 'ModelSEED::varchar') ? 1 : 0;
    return $isString;
}

sub _get_encoding {
    my ($self, $str) = @_;
    return undef unless defined $str; 
    return Encode::Detect::Detector::detect($str);
}

sub _get_subobjects {
    my ($self, $type, $object) = @_;
    my $def = $self->_type_defs->{$type};
    my $subobjects = $def->{subobjects};
    my ($objs, $types) = ([] , []);
    foreach my $subobject (@$subobjects) {
        my $acessor = $subobject->{name};
        my $type    = $subobject->{class};
        push(@$objs, $object->$acessor);
        push(@$types, $type);
    }
    return ($objs, $types);
}

sub _get_attrs {
    my ($self, $type) = @_;
    my $def = $self->_type_defs->{$type};
    return [ map { $_->{name} } @{$def->{attributes}} ];
}

sub _change {
    my ($self, $str, $fromEnc) = @_;
    my $startStr = $str;
    my $startEnc = $fromEnc;
    my $newStr = $str;
    my $notDone = 1;
    my $toEnc = $self->default;
    while ( $notDone ) {
        print "Converting $fromEnc to $toEnc\n";
        my $conv = $self->_convert($str, $fromEnc, $toEnc);
        print "Old: $str\n";
        print "New: $conv\n";
        prompt "[reset|skip|set|accept|try \$enc] : ";
        chomp $_;
        if($_ eq 'accept') {
            $newStr = $conv;
            $notDone = 0;
        } elsif ($_  eq 'set') {
            $str = $conv;
            $fromEnc = $toEnc;
        } elsif ($_ =~ /^try (.*)$/) {
            $toEnc = $1;
        } elsif ($_ eq "skip") {
            return undef;
        } elsif ($_ eq "reset") {
            $newStr = $str = $startStr;
            $fromEnc = $startEnc;
            $toEnc = $self->default;
        }
    }
    return $newStr;
}

sub _convert {
    my ($self, $str, $from, $to) = @_;
    if ($to eq 'manual') {
        print "Old: $str\n";
        prompt "New: ";
        chomp $_;
        return $_;
    } elsif ($to eq 'smart-ASCII') {
        return unidecode($str);
    } else {
        unless ( defined $self->_available_encodings->{$to} ) {
            warn "Unknown encoding $to, available encodings..." .
            join ("\n", keys %{$self->_available_encodings} );
            return $str;
        }
        my $converter = Text::Iconv->new($from, $to);
        return $converter->convert($str);
    }
}

sub _build_type_defs {
    return ModelSEED::MS::Metadata::Definitions::objectDefinitions();
}

sub _build_store {
    my ($self) = @_;
    my $auth = ModelSEED::Auth::Factory->new->from_config;
    return ModelSEED::Store->new(auth => $auth);
}

sub _build_ignore_encodings {
    my ($self) = @_;
    return { map { $_ => 1 } @{$self->ignore} };
}

sub _build_available_encodings {
    my ($self) = @_;
    my $lines = `iconv -l`;
    my @sets  = split(/\n/, $lines);
    my $rtv = [];
    push(@$rtv, map { split(/\s/, $_) } @sets);
    return { map { $_ => 1 } @$rtv }; 
}

1;

# Main package - called if this is a command line script
# this is the basic modulino pattern.
package main;
use strict;
use warnings;
sub run {
    my $module = QuickConvert->new_with_options();
    $module->run();
}
# run unless we are being called by
# another perl script / package
run() unless caller();

1;
