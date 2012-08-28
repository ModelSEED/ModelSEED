package ModelSEED::MS::Metadata::Attribute::Typed;
use strict;
use warnings;
use Moose;
use namespace::autoclean;
extends 'Moose::Meta::Attribute';
has type => (
      is        => 'rw',
      isa       => 'Str',
      predicate => 'has_type',
);

has printOrder => (
      is        => 'rw',
      isa       => 'Int',
      predicate => 'has_printOrder',
      default => '-1',
);
1;

package Moose::Meta::Attribute::Custom::Typed;
sub register_implementation { 'ModelSEED::MS::Metadata::Attribute::Typed' }
1;
