use strict;
use warnings;
use ModelSEED::Table;
use Data::Dumper; # DEBUG
use Test::More;
use Test::Exception;
use File::Temp qw(tempfile);
my $testCount = 0;

# TEST DATA - States, Capitols, Postal Abbreviations
my $states = [qw(
    Alabama Alaska Arizona Arkansas California Colorado Connecticut Delaware
    Florida Georgia Hawaii Idaho Illinois Indiana Iowa Kansas Kentucky Louisiana
    Maine Maryland Massachusetts Michigan Minnesota Mississippi Missouri Montana
    Nebraska Nevada New-Hampshire New-Jersey New-Mexico New-York North-Carolina 
    North-Dakota Ohio Oklahoma Oregon Pennsylvania Rhode-Island South-Carolina 
    South-Dakota Tennessee Texas Utah Vermont Virginia Washington West-Virginia
    Wisconsin Wyoming
)];
my $capitols = [qw(
    Montgomery Juneau Phoenix Little-Rock Sacramento Denver Hartford Dover
    Tallahassee Atlanta Honolulu Boise Springfield Indianapolis Des-Moines
    Topeka Frankfort Baton-Rouge Augusta Annapolis Boston Lansing Saint-Paul
    Jackson Jefferson-City Helena Lincoln Carson-City Concord Trenton Santa-Fe
    Albany Raleigh Bismarck Columbus Oklahoma-City Salem Harrisburg Providence
    Columbia Pierre Nashville Austin Salt-Lake-City Montpelier Richmond
    Olympia Charleston Madison Cheyenne 
)];
my $abbr = [qw(
    AL AK AZ AR CA CO CT DE FL GA HI ID IL IN IA KS KY LA ME MD MA
    MI MN MS MO MT NE NV NH NJ NM NY NC ND OH OK OR PA RI SC SD TN
    TX UT VT VA WA WV WI WY
)];
# TEST DATA - Test / verify test data
{
    my %sc = map { $states->[$_] => $capitols->[$_] } 0..49;
    my %ab = map { $states->[$_] => $abbr->[$_] } 0..49;
    is @$states, 50, "Fifty states";
    is @$capitols, 50, "Fifty capitols";
    is @$abbr, 50;
    is $sc{'New-Mexico'}, 'Santa-Fe';
    is $sc{'Delaware'}, 'Dover';
    is $ab{'Alabama'}, 'AL';
    is $ab{'Oregon'}, 'OR';
    $testCount += 7;
}

# CLASS TESTS
# Initialization, with various options
{
    my $tbl = ModelSEED::Table->new;
    ok defined $tbl;
    $testCount += 1;

    # Test hash init vs hashref init
    # with row vs data
    my $tbl1 = ModelSEED::Table->new(
        columns => [ qw( states capitols ) ],
        rows => [ map { [ $states->[$_], $capitols->[$_] ] } 0..49 ]
    );
    my $tbl2 = ModelSEED::Table->new({
        columns => [ qw( states capitols )],
        rows => [ map { [ $states->[$_], $capitols->[$_] ] } 0..49 ]
    });
    my $tbl3 = ModelSEED::Table->new({
        columns => [ qw( states capitols )],
        data => [ map { [ $states->[$_], $capitols->[$_] ] } 0..49 ]
    });
    my $tbl4 = ModelSEED::Table->new(
        columns => [ qw( states capitols ) ],
        data => [ map { [ $states->[$_], $capitols->[$_] ] } 0..49 ]
    );
    is_deeply $tbl1, $tbl2;
    is_deeply $tbl2, $tbl3;
    is_deeply $tbl3, $tbl4;
    is_deeply $tbl1, $tbl4;
    is_deeply $tbl1, $tbl3;
    is_deeply $tbl2, $tbl4;
    $testCount += 6;

    # Test hash + filename
    my ($fh, $filename) = tempfile;
    close($fh);
    my $tbl5 = ModelSEED::Table->new(
        columns => [ qw( states capitols ) ],
        rows => [ map { [ $states->[$_], $capitols->[$_] ] } 0..49 ],
        filename => $filename,
    );
    is $tbl5->filename, $filename;
    is $tbl5->size, 50;
    $testCount += 2;
}

# Test empty table
{
    my $tbl = ModelSEED::Table->new;
    is $tbl->size, 0;
    is_deeply $tbl->rows, [];
    is $tbl->row(1), undef;
    is_deeply $tbl->columns, [];
    is $tbl->width, 0;
    is $tbl->length, $tbl->size;
    $testCount += 6;
}

# Test column setting
{
    my $tbl = ModelSEED::Table->new;
    is_deeply $tbl->columns, [];
    my $c = [qw(a b c)];
    $tbl->columns($c);
    is_deeply $tbl->columns, $c;
    $tbl->add_column("d");
    is scalar @$c, 3, "Adding column should not alter initial column ref";
    is scalar @{$tbl->columns}, 4, "Column should get added";
    is_deeply $tbl->columns, [qw(a b c d)];
    $testCount += 5;

    # Test adding columns with data
    $tbl->add_column("e", [0..10]);
    is $tbl->size, 0, "Adding a column with data should not *create* rows";
    $tbl->add_row([qw(a b c d e)]);
    is $tbl->size, 1;
    $tbl->add_column("f", [0..10]);
    is $tbl->size, 1;
    $testCount += 3;

    # Test adding columns with insufficent data
    my $tbl2 = ModelSEED::Table->new(
        columns => [qw(a b)],
        rows => [ map { [ $_, $_ ] } 0..10 ],
    );
    $tbl2->add_column("c", [0..5]);
    $tbl2->rows_return_as("ref");
    is $tbl2->row(0)->c, 0;
    is $tbl2->row(4)->c, 4;
    is $tbl2->row(6)->c, undef;
    is $tbl2->row(10)->c, undef;
    $testCount += 4;

    # Test remove_column
    my $d = $tbl2->remove_column("c");
    is @$d, $tbl2->length;
    is $tbl2->width, 2;
    is $tbl2->length, 11;
    is_deeply $tbl2->_column_order, { a => 0, b => 1 };
    $testCount += 4;

    # Test add columns w/ non-array ref
    dies_ok sub { $tbl->add_colunm("g", 'foo') }, "Should die with non-array ref";
    dies_ok sub { $tbl->add_colunm("g", ()) }, "Should die with non-array ref";
    $testCount += 2;

    # test remove invalid column
    dies_ok sub { $tbl->remove_column("foobar") }, "Die for remove_column";
    $testCount += 1;
}

# Test row with multiple add types
{
    my $tbl = ModelSEED::Table->new(columns => [ qw( state capitol ) ]);
    my $ref_row = [ $states->[0], $capitols->[0] ];
    my @arr_row = ( $states->[1], $capitols->[1] );
    my $hash    = { state => $states->[2], capitol => $capitols->[2] };
    my $obj     = ModelSEED::Table::Row->new(
        _table => $tbl,
        _i     => 3,
        _row   => [ $states->[3], $capitols->[3] ]
    );
    $tbl->add_row($ref_row);
    is $tbl->size, 1;
    $tbl->add_row(@arr_row);
    is $tbl->size, 2;
    $tbl->add_row($hash);
    is $tbl->size, 3;
    $tbl->add_row($obj);
    is $tbl->size, 4;
    my $rows = [ map { [ $states->[$_], $capitols->[$_] ] } 0..3 ];
    is_deeply $tbl->rows, $rows;
    $testCount += 5;

    # test get_row with all types
    $tbl->rows_return_as('Array');
    my $r0 = $tbl->row(0);
    is_deeply $r0, $ref_row;
    $tbl->rows_return_as('Hash');
    my $r2 = $tbl->row(2);
    is_deeply $r2, $hash;
    $tbl->rows_return_as('Ref');
    my $r3 = $tbl->row(3);
    is_deeply $r3, $obj;
    $testCount += 3;

    # test row($i, $val) with all types
    # rotate mod x 4 all values in table +1
    my $obj2 = ModelSEED::Table::Row->new(
        _table => $tbl, _i => 2, _row => $obj->_row
    );
    $tbl->row(0, \@arr_row); # can't add as array
    $tbl->row(1, $hash);
    $tbl->row(2, $obj2);
    $tbl->row(3, $ref_row);
    $tbl->rows_return_as('Array');
    is_deeply $tbl->row(0), \@arr_row;
    $tbl->rows_return_as('Hash');
    is_deeply $tbl->row(1), $hash;
    $tbl->rows_return_as('Ref');
    is_deeply $tbl->row(2), $obj2;
    $tbl->rows_return_as('Array');
    is_deeply $tbl->row(3), $ref_row;
    $testCount += 4;

    # test remove_row
    my $row = $tbl->remove_row(3);
    is @$row, $tbl->width;
    is $tbl->length, 3;
    $tbl->remove_row();
    is $tbl->length, 3;
    $testCount += 3;

    # test bad add_row
    dies_ok sub { $tbl->add_row() }, "Die with call to add row";
    $testCount += 1;
    
    # test add rows with array
    $rows = $tbl->rows;
    my $count = @$rows;
    $tbl->rows(@$rows);
    is scalar(@{$tbl->rows}), $count;
    $testCount += 1;

}

# Test get row with multiple types
#

# Test small table
{
    my $s_rows = [ [ "Alabama", "AL" ], [ "Alaska", "AK" ], ];
    my $s_columns = [ "state", "abbreviation" ];
    my $tbl = ModelSEED::Table->new(columns => [qw(state abbreviation)],
        data => [ map { [ $states->[$_], $abbr->[$_] ] } 0..49 ]
    );
    # Size, width, height functions
    is $tbl->size, 50;
    is $tbl->width, 2;
    is $tbl->length, 50;

    is_deeply $tbl->columns, [qw(state abbreviation)]; 

    my $first_row = [ $states->[0], $abbr->[0] ];
    is_deeply $tbl->row(0), $first_row;
    $tbl->rows_return_as('Ref');
    my $row = $tbl->row(1); 
    ok defined $row;
    is $row->state, "Alaska";
    is $row->abbreviation, "AK";
    is $row->state("FOO"), "FOO";
    is $row->state, "FOO";
    $tbl->rows_return_as('array');
    is_deeply $tbl->row(1), [ "FOO", "AK" ];

    $testCount += 11;
}

# Test file print / load
{
    my ($fh, $filename) = tempfile;
    my $tbl1 = ModelSEED::Table->new(columns => [qw(state abbreviation)],
        data => [ map { [ $states->[$_], $abbr->[$_] ] } 0..49 ]
    );
    $tbl1->print($fh);
    close($fh);
    my $tbl2 = ModelSEED::Table->new(filename => $filename);
    $tbl2->_clear_filename; # do this because tmpfile will fail is_deep test
    is_deeply $tbl1, $tbl2;
    $testCount += 1; 

    # Test save, reload
    ($fh, $filename) = tempfile;
    close($fh);
    $tbl2->save($filename);
    my $tbl3 = ModelSEED::Table->new(filename => $filename);
    $tbl3->_clear_filename;
    is_deeply $tbl3, $tbl2;
    $testCount += 1;
}


# Test string (un-)escape
{
    my $delimiters = [ "\t", ",", ";", ":", "|", "&", "<", "-"];
    sub roundtrip {
        my $tbl = shift;
        my $str = shift;
        return $tbl->_unescape_str(
            $tbl->_escape_str($str)
        );
    }
    foreach my $del (@$delimiters) {
        my $strings = {
            foofoo => "foofoo",
            "foo${del}foo" => "foo\\${del}foo",
            "$del$del" => "\\$del\\$del",
            "\\$del" => "\\\\$del",
        };
        my $tbl = ModelSEED::Table->new( delimiter => $del);
        foreach my $str (keys %$strings) {
            my $exp = $strings->{$str};
            if ($exp ne $str) {
                isnt $tbl->_escape_str($str), $str;
                $testCount += 1;
            }
            is $tbl->_escape_str($str), $exp;
            is roundtrip($tbl, $str), $str;
            $testCount += 2;
        }
    }
}

# Test subdelimiter behavior
{
    my $tbl1 = ModelSEED::Table->new(
        columns => [ qw( states capitols ) ],
        rows => [ map { [ $states->[$_], $capitols->[$_] ] } 0..49 ]
    );
    is_deeply $tbl1->row(0)->[0], $states->[0];
    $tbl1->subdelimiter('');
    is_deeply $tbl1->row(0)->[0], [ split('', $states->[0]) ];
    $tbl1->subdelimiter(',');
    my ($fh, $filename) = tempfile;
    close($fh);
    $tbl1->filename($filename);
    $tbl1->save();
    my $tbl2 = ModelSEED::Table->new(filename => $filename, subdelimiter => ',');
    is_deeply $tbl1, $tbl2;
    $tbl2->subdelimiter(undef);
    is_deeply $tbl2->row(0)->[0], join(',', split('', $states->[0]));
    $testCount += 4;

    my $tbl3 = ModelSEED::Table->new(
        columns => [ qw( states capitols ) ],
        rows => [ map { [ $states->[$_], $capitols->[$_] ] } 0..49 ]
    );
    my $row = $tbl3->row(0);
    $tbl3->subdelimiter();
    is_deeply $row, $tbl3->row(0);
    $testCount += 1;

}

# Test die when load from file + bad column spec
{
    my ($fh, $filename) = tempfile;
    close($fh);
    my $tbl1 = ModelSEED::Table->new(
        columns => [ qw( states capitols ) ],
        rows => [ map { [ $states->[$_], $capitols->[$_] ] } 0..49 ],
        filename => $filename,
    );
    ok defined $tbl1;
    $tbl1->save();
    dies_ok sub {
        my $tbl2 = ModelSEED::Table->new(
            columns => [qw(states)],
            filename => $filename,
        );
     }, "Die on load from file w/ bad column spec";
    $testCount += 2;
}


done_testing($testCount);
