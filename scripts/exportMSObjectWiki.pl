#!/usr/bin/perl 
use strict;
use warnings;
use autodie;
use ModelSEED::Table;
use ModelSEED::MS::Metadata::Definitions;
use File::Temp qw(tempfile);
use Data::Dumper;
my $usage = <<HEREDOC;
exportMSObjectWiki export/directory

Generates documentation for MS objects.
HEREDOC
my $dest   = shift @ARGV;
die $usage unless(defined($dest) && -d $dest);
my $defs = ModelSEED::MS::Metadata::Definitions::objectDefinitions();
# Generate PNG images for the following object hierarchies:
# These will be saved as $key.png in the output directory
my $graphConfig = {
    Biochemistry          => [1000],
    Mapping               => [1000],
    Model                 => [1000, [qw(FBAFormulation GapfillingFormulation)] ],
    GapfillingFormulation => [1000],
    FBAFormulation        => [1000],
};
foreach my $graph (keys %$graphConfig) {
    my $depth = $graphConfig->{$graph}->[0] || 0;
    my $exclude = $graphConfig->{$graph}->[1] || [];
    buildGraph($defs, $dest, $graph, $depth, $exclude);
}
# Generate HTML tables and markdown descriptions of each object and
# object attributes. These are contained in a hash until the final
# document is constructed.
my $sections = {};
foreach my $object (sort keys %$defs) {
    $sections->{$object} = buildSection($defs, $object);
}
# Now format the document, proceeding in a specific order and including
# a top-level section that we explicitly define here. Note that for @order,
# The string {Type} implies all the remaining subobjects of Type
my @order = qw(
  Biochemistry Compound Compartment Media MediaCompound Reaction Reagent AliasSet {Biochemistry}
  Mapping Role Complex {Mapping}
  FBAFormulation {FBAFormulation}
  GapfillingFormulation {GapfillingFormulation}
  Model {Model}
);
my $markdown = <<HEAD;
Object Definitions
==================

General Concepts
----------------
Each section in this document describes an object and class within
the ModelSEED.  All objects inherit from
[ModelSEED::MS::BaseObject](ModelSEED-MS-BaseObject).  However, a
few objects also inherit from
[ModelSEED::MS::IndexedObject](ModelSEED-MS-IndexedObject) which
defines a few additional functions for data-lookup. Consult these
pages for details on what functions are offered.

### Objects as JSON blobs

Objects can be represented as plain JSON blobs. For example, the following
is a valid <a href='#wiki-Compartment'>Compartment</a> blob:

```json 
   {
      "uuid" : "A128E5E2-C209-11E1-9982-998743BA47CD",
      "modDate" : "2012-06-29T16:45:50",
      "name" : "Extracellular",
      "id" : "e",
      "hierarchy" : 0
   }
```
If this were un-marshalled into a Perl hash-reference, we could construct
an object by passing it into the `new` function:

```perl
    use ModelSEED::MS::Compartment;
    my \$cmp = ModelSEED::MS::Compartment->new(\$hash);
```

Attributes can be accessed via the function specified in the "method name"
section of the table. For basic types, this returns the value. For Arrays,
Hashes, etc. this returns a reference to that object. These methods are
also setters.

```perl
    print \$cmp->name;    # prints "Extracellular"
    \$cmp->id("x");       # sets the comartment id to "x"
```

### Sub-Objects

Objects 

### Links between Objects



### Provenance



### Object Storage and Versioning

Using the [ModelSEED::MS::Store](ModelSEED-MS-Store) interface, it is possible to
fetch and save a provenence object with it's associated sub-objects.


HEAD
my $done_sections = {};
foreach my $type (@order) {
    if ($type =~ /{(.*)}/) {
        my @types = _remainingChildren($1, $defs, $done_sections);
        foreach my $type (@types) {
            $markdown .= buildSection($defs, $type, $graphConfig);
            $done_sections->{$type} = 1;
        }
    } else {
        $markdown .= buildSection($defs, $type, $graphConfig);
        $done_sections->{$type} = 1;
    }
}

sub _remainingChildren {
    my ($type, $defs, $done_sections) = @_;
    my @remaining;
    my $subs = $defs->{$type}->{subobjects} || [];
    foreach my $sub (@$subs) {
        push(@remaining, _remainingChildren(
            $sub->{class}, $defs, $done_sections
        ));
        next if defined $done_sections->{$sub->{class}};
        push(@remaining, $sub->{class});
    }
    return @remaining;
}

sub buildSection {
    my ($defs, $type, $graphConfig) = @_;
    my $graphPlaceholder = "";
    my $hFactor = "###";
    if(defined $graphConfig->{$type}) {
        $graphPlaceholder = <<PLACE;
[[$type.png|align=center]]
*Key: Nodes are objects and classes. Red arrows represent links; Blue arrows represent sub-object relationships.*
PLACE
        $hFactor = "##";
    }
    my $tableAndDescription = _build_table_and_description($defs, $type);
    my $section = <<SECTION;
$hFactor <a name='$type'>$type</a>
$graphPlaceholder
$tableAndDescription
SECTION
    return $section;
}

open(my $fh, ">", "$dest/Object-Definitions.md");
print $fh $markdown;
close($fh);

sub _build_table_and_description {
    my ($defs, $type_name) = @_;
    my $type = $defs->{$type_name};
    my $parts = [];
    my $table = ModelSEED::Table->new(columns => ["method name", "type", "description"]);
    foreach my $attr (@{$type->{attributes}}) {
        my $row = [];
        my $desc = $attr->{description};
        $desc    = "" unless defined $desc;
        $desc   .= " (Required)" if defined $attr->{required};
        push(@$row, $attr->{name});
        push(@$row, get_type_link($attr->{type}, $attr));
        push(@$row, $desc);
        $table->add_row($row);
    }
    foreach my $subobj (@{$type->{subobjects}}) {
        my $row = [];
        my $desc = $subobj->{description};
        $desc    = "" unless defined $desc;
        push(@$row, $subobj->{name});
        push(@$row, get_type_link("ModelSEED::MS::".$subobj->{class}, $subobj));
        push(@$row, $desc);
        $table->add_row($row);
    }
    foreach my $link (@{$type->{links}}) {
        my $row = [];
        my $desc = $link->{description};
        $desc    = "" unless defined $desc;
        my $type = _get_linked_object_type($defs, $link);
        push(@$row, $link->{name});
        push(@$row, get_type_link("ModelSEED::MS::".$type, $link));
        push(@$row, $desc);
        $table->add_row($row);
    }
    $table = generate_html_table($table);
    my $description = $defs->{$type_name}->{description};
    $description = "" unless defined $description;
    return $description . "\n" . $table;
}

sub generate_html_table {
    my ($table) = @_;
    my $tableHeader = "<tr>". join("", map { "<th>".$_."</th>" } @{$table->columns}) . "</tr>";
    my $tableRows = "";
    foreach my $row (@{$table->rows}) {
        my $rowStr = join("", map { "<td>".$_."</td>" } @$row);
        $tableRows .= "<tr>".$rowStr."</tr>\n";
    }
    return <<HEREDOC;
<table>
    $tableHeader
    $tableRows
</table>
HEREDOC
}

sub get_type_link {
    my ($type, $row) = @_;
    my $t = '';
    $t = 'Array of '            if defined $row->{class};
    $t = 'UUID refering to a: ' if defined $row->{parent};
    $t = 'Array of UUIDs referring to: '
      if defined $row->{parent} && $row->{array};
    if($type =~ /ModelSEED::MS::(.*)/) {
        return "$t<a href='#wiki-$1'>$1</a>";
    } elsif($type eq 'ModelSEED::uuid') {
        return "${t}UUID";
    } elsif($type eq 'ModelSEED::varchar') {
        return "${t}Str, with maximum length: 255";
    } elsif ($type =~ /ModelSEED::(.*)/) {
        return "$t<a href='ModelSEED-$1'>ModelSEED::$1</a>";
    } else {
        return $type;
    }
}

sub _get_linked_object_type {
    my ($defs, $link) = @_;
    my $parent = $link->{parent};
    my $accessor = $link->{method};
    return $accessor if $parent eq "ModelSEED::Store";
    my $subobjects = $defs->{$parent}->{subobjects};
    my ($part) = grep { $_->{name} eq $accessor } @$subobjects;
    return undef unless defined $part;
    return $part->{class};
}


# Graph Construction Functions
#
#  - These functions are used to construct a dotfile for
#    the object hierarchy and render that dotfile into
#    a png image using GraphViz
#
#  - buildGraph("Biochemistry", 10, [])
#    This function constructs the graph for $targetObject.
#    $depth is the maximum depth.
#    $exclude is a list of objects to ignore.
sub buildGraph {
    my ($defs, $dest, $targetObject, $depth, $exclude) = @_;
    my $graph = _build_subgraph($defs, $targetObject, $depth, $exclude);
    my $dotstring = _build_dotstring($graph);
    my ($fh, $filename) = tempfile();
    print $fh $dotstring;
    close($fh);
    system("dot -Tpng $filename > $dest/$targetObject.png");
    unlink $filename;
    return $graph;
}
#  - _build_subgraph $defs, $object, $depth, $exclude
#    Recursivly build and return the graph object.
sub _build_subgraph {
    my ($defs, $object, $depth, $exclude) = @_;
    $exclude = [] unless defined $exclude;
    $exclude = { map { $_ => 1 } @$exclude };
    $depth = 0 unless defined $depth;
    my $graph = {};
    foreach my $link (@{$defs->{$object}->{links}}) {
        my $class = _get_linked_object_type($defs, $link);
        next unless defined $class;
        next if defined $exclude->{$class};
        push(@{$graph->{$object}}, { v => $class, d => "link" });
    }
    foreach my $subo (@{$defs->{$object}->{subobjects}}) {
        my $class = $subo->{class};
        next unless defined $class;
        next if defined $exclude->{$class};
        push(@{$graph->{$object}}, { v => $class, d => "subobject" });
        if($depth-1 > 0) {
            _merge_hash($graph, _build_subgraph($defs, $class, $depth - 1));
        }
    }
    return $graph;
}
#  - _build_dotstring($graph)
#    Construct dotfile contents for a $graph object
sub _build_dotstring {
    my ($graph) = @_;
    my $nodes = [];
    foreach my $lhs (keys %$graph) {
        foreach my $edge (@{$graph->{$lhs}}) {
            my $type = $edge->{d};
            my $rhs = $edge->{v};
            if($type eq "link") {
                push(@$nodes, "\t$lhs -> $rhs [color=red]");
            } elsif($type eq "subobject") {
                push(@$nodes, "\t$lhs -> $rhs [color=blue]");
            } else {
                push(@$nodes, "\t$lhs -> $rhs");
            }
        }
    }
    $nodes = join("\n", @$nodes);
    return "digraph G {\n$nodes\n}\n";
}
sub _merge_hash {
    my ($a, $b) = @_;
    foreach my $k (keys %$b) {
        if(defined $a->{$k}) {
            push(@{$a->{$k}}, @{$b->{$k}});
        } else {
            $a->{$k} = $b->{$k};
        }
    }
    return $a;
}
# END - graph functions
