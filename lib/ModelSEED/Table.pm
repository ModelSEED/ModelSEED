########################################################################
# ModelSEED::Table - OO Table Interface
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location:
#   Mathematics and Computer Science Division, Argonne National Lab;
#   Computation Institute, University of Chicago
#
# Date of module creation: 2012-07-25
########################################################################

=head1 ModelSEED::Table

A basic table object

=head2 SYNOPSIS

    # Initalization
    my $t = ModelSEED::Table->new
    my $t = ModelSEED::Table->new(rows => [], columns => [])
    my $t = ModelSEED::Table->new(filename => "foo")
        
    # Alter columns
    $tbl->columns("id", "name")          # sets column names
    $tbl->columns([ qw(id name) ])      
    $tbl->add_column("phone number", []) # appends a column
    $tbl->remove_column("phone number")  # removes a column
    $tbl->reorder_columns(\@)            # rearranges columns
    $tbl->reorder_columns(@)
    
    # Alter rows
    $tbl->rows(\@)
    $tbl->rows(@)
    $tbl->add_row(\%)
    $tbl->add_row(%)
    $tbl->add_row(@)
    $tbl->add_row(\@)
    
    # Getters
    $tbl->columns           # return array ref of columns
    $tbl->rows              # return array ref of rows
    $tbl->size              # return length, number of rows
    $tbl->length            # return number of rows
    $tbl->width             # return number of columns
    $tbl->row(n)            # 
    
    # Settings
    $tbl->filename
    $tbl->delimiter
    $tbl->subdelimiter
    $tbl->rows_return_as
    
    # Queries
    $tbl->get_rows ( % )
    $tbl->get_row ( % )
     
    # Save
    $tbl->save
    $tbl->print

=cut

package ModelSEED::Table;
use Moose;
use Moose::Util::TypeConstraints;
use autodie;
use common::sense;
use Storable qw(dclone);
use Data::Dumper; # DEBUG
use Carp qw(cluck); # DEBUG

enum 'RowReturns', [qw(array hash ref)];
coerce 'RowReturns',
    from 'Str',
    via { lc $_ };

# Data
has _data => ( is => 'rw', isa => 'ArrayRef', lazy => 1, builder => '_build_data' );
has _columns => (
    is      => 'rw',
    isa     => 'ArrayRef[Str]',
    lazy    => 1,
    builder => '_build_columns',
    trigger => \&_update_column_order,
);

# Settings
has filename => ( is => 'rw', isa => 'Str', clearer => '_clear_filename' );
has delimiter => ( is => 'rw', isa => 'Str', default => "\t" );
has subdelimiter => (
    is      => 'rw',
    isa     => 'Maybe[Str]',
    trigger => \&_update_subdelimiter,
    default => undef,
);
has rows_return_as => ( is => 'rw', isa => 'RowReturns', default => 'Array', coerce => 1 );

# Cache
has _column_order => ( is => 'rw', isa => 'HashRef', builder => '_update_column_order', lazy => 1);

sub BUILD {
    my $self = shift;
    my $hash;
    if ( @_ == 1 && ref $_[0] eq 'HASH' ) {
        $hash = shift;
    }
    $self->_init_from_hash($hash) if $hash;
}


# Getter / Setter Functions 
sub columns {
    my $self = shift @_;
    $self->_maybe_do_setter("_set_columns", @_);
    return $self->_columns;
}

sub rows {
    my $self = shift;
    $self->_maybe_do_setter("_set_rows", @_);
    return $self->_data;
}

sub row {
    my $self = shift;
    my $n    = shift;
    my $row  = shift;
    $self->_set_row($n, $row) if defined $row;
    my $row = $self->_data->[$n];
    my $setting = $self->rows_return_as;
    if (lc($setting) eq 'array') {
        return $row;
    } elsif(lc($setting) eq 'hash') {
        my $h = $self->columns;
        my $i = 0;
        return { map { $h->[$i++] => $_ } @$row };
    } elsif(lc($setting) eq 'ref') {
        return ModelSEED::Table::Row->new(_table => $self, _row => $row, _i => $n);
    }
}

# Setter Helper Functions
sub _set_columns {
    my $self = shift @_;
    my $arr  = shift @_;
    $self->_columns( dclone $arr );
    $self->_trim_rows();
}

sub _set_rows {
    my $self = shift @_;
    my $rows = shift @_;
    $self->_get_row_from_args($_) for @$rows;
    $self->_data($rows);
}

sub _set_row {
    my $self = shift @_;
    my $i    = shift @_;
    my $row  = shift @_;
    $row = $self->_get_row_from_args($row);
    splice(@{$self->_data}, $i, 1, $row);
}

# Addder Functions
sub add_column {
    my ($self, $cname, $values) = @_;
    # Do column update this way to spark trigger on _columns
    my $columns = $self->_columns;
    push(@$columns, $cname);
    $self->_columns($columns);
    # Add values if they are provided
    if(defined $values) {
        die "Second argument to add_column must be an arrayref"
            if ref $values ne 'ARRAY';
        foreach my $row (@{$self->_data}) {
            my $value = shift @$values;
            push(@$row, $value);
        }
    }
}

sub add_row {
    my $self = shift @_;
    my $row  = $self->_get_row_from_args(@_);
    die "Invalid arguments to add_row" unless defined $row;
    my $data = $self->_data;
    push(@$data, $row);
    $self->_data($data);
}

sub remove_column {
    my ($self, $cname) = @_;
    my $index = $self->_column_order->{$cname};
    die "Unknown Column: $cname" unless defined $index;
    # Pull out row-data for this column
    my $data = [ map { splice(@$_, $index, 1) } @{$self->_data} ];
    # Update Columns
    my $columns = $self->_columns;
    splice(@$columns, $index, 1);
    $self->columns($columns);
    return $data;
} 

sub remove_row {
    my ($self, $index) = @_;
    return unless defined $index;
    return splice(@{$self->_data}, $index, 1);
}

# Save functions
sub save {
    my $self = shift;
    my $filename = shift;
    $filename = $self->filename unless defined $filename;
    open( my $fh, ">", $filename );
    $self->print($fh);
    close($fh);
}

sub print {
    my ($self, $fh) = @_;
    my ($del, $delr, $sdel, $sdelr) = $self->_delimiters();
    my $nl = "\n";
    print $fh join($del, map { $self->_escape_str($_) } @{$self->columns}) . $nl;
    foreach my $row (@{$self->_data}) {
        if ( defined $sdel ) {
            my @cols;
            foreach my $subrow (@$row) {
                push(@cols,
                    join($sdel, map { $self->_escape_str($_) } @$subrow)
                );
            }
            my $str = join($del, @cols); 
            print $fh $str . "\n";
        } else {
            print $fh join($del, map { $self->_escape_str($_) } @$row) . "\n"
        }
    }
}

sub load {
    my ($self, $filename) = @_;
    my $filename = $self->filename unless defined $filename;
    my ($del, $delr, $sdel, $sdelr) = $self->_delimiters();
    open( my $fh, "<", $filename) or die "Unable to open $filename: $!";
    my $doneColumns = 0;
    my $rows = [];
    my $columns;
    while(<$fh>) {
        my @row = split(/$delr/, $_);
        @row = map { $self->_unescape_str($_) } @row;
        chop $row[@row-1];
        unless(defined $columns) {
            $columns = \@row;
            next;
        }
        if(defined $sdel) {
            @row = map { [ split(/$sdelr/, $_) ] } @row;
        } 
        push(@$rows, \@row);
    }
    close($fh);
    if($self->width > 0 && $self->width != @$columns) {
        die "Unmatched columns during table load:\n".
        "File contains: " . join(" ", @$columns) . "\n" .
        "Table contains: " . join(" ", @{$self->columns}) . "\n";
    }
    $self->columns($columns);
    $self->rows($rows);
}


# Basic Getters
sub size   { scalar @{ $_[0]->_data }; }
sub width  { scalar @{ $_[0]->columns }; }
sub length { $_[0]->size }

# TRIGGERS
sub _update_subdelimiter {
    my ($self, $new, $old) = @_;
    # split each cell by $new
    if (defined $new && !defined $old) {
        foreach my $row (@{$self->_data}) {
            foreach my $c (@$row) {
                $c = [ split(/$new/, $c) ];
            }
        }
    # join each cell's arrayref by $old
    } elsif(!defined $new && defined $old) {
        foreach my $row (@{$self->_data}) {
            foreach my $c (@$row) {
                $c = join($old, @$c);
            }
        }
    }
}

sub _update_column_order {
    my $self = shift @_;
    my $i = 0;
    my $rtv = { map { $_ => $i++ } @{$self->columns} };
    $self->_column_order($rtv);
    return $rtv;
}

# HELPERS
sub _maybe_do_setter {
    my $self      = shift;
    my $setter_fn = shift;
    my $ref       = $self->_arrayref_from_args(@_);
    if ($ref) {
        $self->$setter_fn($ref);
    }
}

sub _arrayref_from_args {
    my $self = shift @_;
    if ( @_ && scalar(@_) == 1 && ref $_[0] eq 'ARRAY' ) {
        return $_[0];
    } elsif (@_) {
        return \@_;
    } else {
        return undef;
    }
}

# remove cells from rows that have no column headers
sub _trim_rows {
    my $self = shift;
    my $i = $self->width;
    foreach my $row (@{$self->_data}) {
        my $size = scalar @$row;
        splice(@$row, $i-$size) if($size > $i);
    }
}

# { @, \@, \%, $ } -> \@
sub _get_row_from_args {
    my $self = shift;
    return \@_ if(@_ > 1);
    my $r    = shift;
    return $r if ref $r eq 'ARRAY';
    if(ref $r eq 'HASH') {
        return [ map { $r->{$_} } @{$self->columns} ];
    } elsif(ref $r && $r->isa("ModelSEED::Table::Row")) {
        return dclone $r->_row;
    } else {
        return undef;
    }
}

sub _escape_del {
    my ($self, $del) = @_;
    my $metachars = {
        "|" => 1,
    };
    return "\\".$del if $metachars->{$del};
    return $del;
}

sub _delimiters {
    my $self = shift;
    my ($del, $delr, $sdel, $sdelr);
    $del = $self->delimiter;
    $sdel = $self->subdelimiter;
    # need to escape regex metacharachters
    $delr = $self->_escape_del($del);
    $sdelr = $self->_escape_del($sdel) if defined $sdel;
    return ($del, $delr, $sdel, $sdelr);
}

sub _escape_str {
    my ($self, $str) = @_;
    my ($del, $delr, $sdel, $sdelr) = $self->_delimiters;
    my $cpy = $str;
    $cpy =~ s/$delr/\\$del/g;
    if(defined $sdel) {
        $cpy =~ s/$sdelr/\\$sdel/g;
    }
    return $cpy; 
}

sub _unescape_str {
    my ($self, $str) = @_;
    my $metachars = {
        "|" => 1,
    };
    my ($del, $delr, $sdel, $sdelr) = $self->_delimiters;
    my $cpy = $str;
    $cpy =~ s/\\$delr/$del/g;
    if(defined $sdel) {
        $cpy =~ s/\\$sdelr/$sdel/g;
    }
    return $cpy;
}

# BUILDERS

sub _build_data { [] }
sub _build_columns { [] }

sub _init_from_hash {
    my ($self, $hash) = @_;
    if(defined $hash->{columns}) {
        $self->_columns( dclone $hash->{columns} );
    }
    if(defined $hash->{data}) {
        $self->_data( dclone $hash->{data} );
    }
    if(defined $hash->{rows}) {
        $self->_data( dclone $hash->{rows} );
    }
    if($self->length == 0 && defined $self->filename) {
        $self->load;
    }
}

__PACKAGE__->meta->make_immutable;
1;

package ModelSEED::Table::Row;
use Moose;
use common::sense;
use namespace::autoclean;

has _table => ( is => 'ro', isa => "ModelSEED::Table", required => 1, weak_ref => 1 );
has _i => ( is => 'ro', isa => 'Int', required => 1 );
has _row => ( is => 'ro', isa => 'ArrayRef', required => 1 );

sub AUTOLOAD {
    my $self = shift;
    my $call = our $AUTOLOAD;
    return if $AUTOLOAD =~ /::DESTROY$/;
    $call =~ s/.*://;
    my $h = $self->_table->_column_order;
    my $column = $h->{$call}; 
    if( defined $column && @_ ) {
        return $self->_row->[$column] = shift;
    } elsif( defined $column )  {
        return $self->_row->[$column];
    }
}

__PACKAGE__->meta->make_immutable;
1;
