########################################################################
# ModelSEED::MS::BaseObject - This is a base object that serves as a foundation for all other objects
# Author: Christopher Henry
# Author email: chenry@mcs.anl.gov
# Author affiliation: Mathematics and Computer Science Division, Argonne National Lab
# Date of module creation: 3/11/2012
########################################################################
use ModelSEED::MS::Metadata::Types;
use DateTime;
use Data::UUID;
use JSON::XS;
use Module::Load;
use ModelSEED::MS::Metadata::Attribute::Typed;
use ModelSEED::Exceptions;
use ModelSEED::utilities;
package ModelSEED::MS::BaseObject;

=head1 ModelSEED::MS::BaseObject

=head2 SYNOPSIS

=head2 METHODS

=head3 Initialization

=head4 new

    my $obj = ModelSEED::MS::Object->new();   # Initialize object with default parameters
    my $obj = ModelSEED::MS::Object->new(\%); # Initialize object with hashref of parameters
    my $obj = ModelSEED::MS::Object->new(%);  # Initialize object with hash of parameters

=head3 Serialization

=head4 serializeToDB

Return a simple perl hash that can be passed to a JSON serializer.

    my $data = $object->serializeToDB();

=head4 toJSON

    my $string = $object->toJSON(\%);

Serialize object to JSON. A hash reference of options may be passed
as the first argument. Currently only one option is available C<pp>
which will pretty-print the ouptut.

=head4 createHTML

    my $string = $object->createHTML();

Returns an HTML document for the object.

=head4 toReadableString

    my $string = $object->toReadableString();

=head3 Object Traversal

=head4 getAlias

=head4 getAliases

=head4 defaultNameSpace

=head4 getLinkedObject

=head4 getLinkedObjectArray

=head4 store

=head4 biochemisry

=head4 annotation

=head4 mapping

=head4 fbaproblem

=head3 Object Manipulation

=head4 add

=head4 remove

=head3 Helper Functions

=head4 interpretReference

=head4 parseReferenceList

=head3 Schema Versioning

=head4 __version__

=head4 __upgrade__

=cut

use Moose;
use namespace::autoclean;
use ModelSEED::utilities;
use Scalar::Util qw(weaken);
our $VERSION = undef;

my $htmlheader = <<HEADER;
<!doctype HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<title>\${TITLE}</title>
<link rel="stylesheet" href="http://netdna.bootstrapcdn.com/twitter-bootstrap/2.3.0/css/bootstrap-combined.min.css">
<link rel="stylesheet" href="http://ajax.aspnetcdn.com/ajax/jquery.dataTables/1.9.4/css/jquery.dataTables.css">
<script src="http://ajax.googleapis.com/ajax/libs/jquery/1.9.1/jquery.min.js"></script>
<script src="http://netdna.bootstrapcdn.com/twitter-bootstrap/2.3.0/js/bootstrap.min.js"></script>
<script type="text/javascript" charset="utf8" src="http://ajax.aspnetcdn.com/ajax/jquery.dataTables/1.9.4/jquery.dataTables.js"></script>
<script type="text/javascript">
  \$(document).ready(function() {
    \$('#tab-header a').click(function (e) {
      e.preventDefault();
      \$(this).tab('show');
    });

    \$('.data-table').dataTable();
  });
</script>
<style type="text/css">
    #tabs {
        margin: 20px 50px;
    }
</style>
</head>
HEADER

my $htmlbody = <<BODY;
<body>
<div id="tabs">
<ul class="nav nav-tabs" id="tab-header">
<li class="active"><a href="#tab-1">Overview</a></li>
\${TABS}
</ul>
<div class="tab-content">
<div class="tab-pane active" id="tab-1">
\${MAINTAB}
</div>
\${TABDIVS}
</div>
</div>
</body>
BODY

my $htmltail = <<TAIL;
</html>
TAIL

around BUILDARGS => sub {
    my $orig  = shift;
    my $class = shift;
    my $hash = {};
    if ( ref $_[0] eq 'HASH' ) {
        $hash = shift;    
    } elsif ( scalar @_ % 2 == 0 ) {
        my %h = @_;
        $hash = \%h;
    }
    my $objVersion = $hash->{__VERSION__};
    my $classVersion = $class->__version__;
    if (!defined($objVersion) && defined($hash->{parent})) {
    	$objVersion = 1;
    }
    if (defined $objVersion && defined($classVersion) && $objVersion != $classVersion) {
        if (defined(my $fn = $class->__upgrade__($objVersion))) {
            $hash = $fn->($hash);
        } else {
            die "Invalid Object\n";
        }
    }
    return $class->$orig($hash);
};


sub BUILD {
    my ($self,$params) = @_;
    # replace subobject data with info hash
    foreach my $subobj (@{$self->_subobjects}) {
        my $name = $subobj->{name};
        my $class = $subobj->{class};
        my $method = "_$name";
        my $subobjs = $self->$method();

        for (my $i=0; $i<scalar @$subobjs; $i++) {
            my $data = $subobjs->[$i];
            # create the info hash
            my $info = {
                created => 0,
                class   => $class,
                data    => $data
            };

            $data->{parent} = $self; # set the parent
            weaken($data->{parent}); # and make it weak
            $subobjs->[$i] = $info; # reset the subobject with info hash
        }
    }
}

sub serializeToDB {
    my ($self) = @_;
    my $data = {};
    $data = { __VERSION__ => $self->__version__() } if defined $self->__version__();
    my $attributes = $self->_attributes();
    foreach my $item (@{$attributes}) {
    	my $name = $item->{name};	
		if (defined($self->$name())) {
    		$data->{$name} = $self->$name();	
    	}
    }
    my $subobjects = $self->_subobjects();
    foreach my $item (@{$subobjects}) {
    	my $name = "_".$item->{name};
    	my $arrayRef = $self->$name();
    	foreach my $subobject (@{$arrayRef}) {
			if ($subobject->{created} == 1) {
				push(@{$data->{$item->{name}}},$subobject->{object}->serializeToDB());	
			} else {
				my $newData;
				foreach my $key (keys(%{$subobject->{data}})) {
					if ($key ne "parent") {
						$newData->{$key} = $subobject->{data}->{$key};
					}
				}
				push(@{$data->{$item->{name}}},$newData);
			}
		}
    }
    return $data;
}

sub cloneObject {
	my ($self) = @_;
	my $data = $self->serializeToDB();
	my $class = "ModelSEED::MS::".$self->_type();
	if (defined($data->{uuid})) {
		delete $data->{uuid};
	}
	return $class->new($data);
}

sub dependencies {
	return [];
}

sub toJSON {
    my $self = shift;
    my $args = ModelSEED::utilities::args([],{pp => 0}, @_);
    my $data = $self->serializeToDB();
    my $JSON = JSON::XS->new->utf8(1);
    $JSON->pretty(1) if($args->{pp} == 1);
    return $JSON->encode($data);
}

=head3 export

Definition:
	string = ModelSEED::MS::BaseObject->export({
		format => readable/html/json
	});
Description:
	Exports media data to the specified format.

=cut

sub export {
    my $self = shift;
	my $args = ModelSEED::utilities::args(["format"], {}, @_);
	if (lc($args->{format}) eq "readable") {
		return $self->toReadableString();
	} elsif (lc($args->{format}) eq "html") {
		return $self->createHTML();
	} elsif (lc($args->{format}) eq "json") {
		return $self->toJSON({pp => 1});
	}
	ModelSEED::utilities::error("Unrecognized type for export: ".$args->{format});
}

######################################################################
#Alias functions
######################################################################
sub getAlias {
    my ($self,$set) = @_;
    my $aliases = $self->getAliases($set);
    return (@$aliases) ? $aliases->[0] : undef;
}

sub getAliases {
    my ($self,$setName) = @_;
    return [] unless(defined($setName));
    my $aliasRootClass = lc($self->_aliasowner());
    my $rootClass = $self->$aliasRootClass();
    my $aliasSet = $rootClass->queryObject("aliasSets",{
    	name => $setName,
    	class => $self->_type()
    });
    return [] unless(defined($aliasSet));
    my $aliases = $aliasSet->aliasesByuuid->{$self->uuid()};
    return (defined($aliases)) ? $aliases : [];
}

sub allAliases {
	my ($self) = @_;
    my $aliasRootClass = lc($self->_aliasowner());
    my $rootClass = $self->$aliasRootClass();
    my $aliasSets = $rootClass->queryObjects("aliasSets",{
    	class => $self->_type()
    });
    my $aliases = [];
    for (my $i=0; $i < @{$aliasSets}; $i++) {
    	my $set = $aliasSets->[$i];
    	my $setAliases = $set->aliasesByuuid->{$self->uuid()};
    	if (defined($setAliases)) {
    		push(@{$aliases},@{$setAliases});
    	}
    }
    return $aliases;
}

sub hasAlias {
    my ($self,$alias,$setName) = @_;
    my $aliasRootClass = lc($self->_aliasowner());
    my $rootClass = $self->$aliasRootClass();
    my $aliasSets = $rootClass->queryObjects("aliasSets",{
    	class => $self->_type()
    });
    for (my $i=0; $i < @{$aliasSets}; $i++) {
    	my $set = $aliasSets->[$i];
	next if $setName && $set->name() ne $setName;
    	my %setAliases = map { $_=>1 } @{$set->aliasesByuuid->{$self->uuid()}};
	return 1 if exists($setAliases{$alias});
    }
    return 0;
}

sub defaultNameSpace {
    return $_[0]->parent->defaultNameSpace();
}

sub _build_id {
    my ($self) = @_;
    my $alias = $self->getAlias($self->defaultNameSpace());
    return (defined($alias)) ? $alias : $self->uuid;
}

sub interpretReference {
	my ($self,$ref,$expectedType) = @_;
	if (defined($expectedType)) {
		my $class = "ModelSEED::MS::".$expectedType;
		if ($class->can("recognizeReference")) {
			$ref = $class->recognizeReference($ref);
		} 
	}
	my $array = [split(/\//,$ref)];
	if (!defined($array->[2]) || (defined($expectedType) && $array->[0] ne $expectedType)) {
		if (defined($expectedType) && @{$array} == 1) {
			$array = [$expectedType,"id",$ref];
		} else {
			ModelSEED::utilities::error($ref." is not a valid  reference!");
		}
	}
	my $refTypeProvObj = {
		"Role" => ["mapping","roles"],
		"Reaction" => ["biochemistry","reactions"],
		"Media" => ["biochemistry","media"],
		"Feature" => ["annotation","features"],
		"Genome" => ["annotation","genomes"],
		"Compound" => ["biochemistry","compounds"],
		"Compartment" => ["biochemistry","compartments"],
		"Biomass" => ["model","biomasses"]
	};
	if (!defined($refTypeProvObj->{$array->[0]})) {
		ModelSEED::utilities::error("No specs to handle ref type ".$array->[0]);
	}	
	my $prov = $refTypeProvObj->{$array->[0]}->[0];
	my $func = $refTypeProvObj->{$array->[0]}->[1];
	my $obj;
	if ($array->[1] eq "ModelSEED") {
		$obj = $self->$prov()->queryObject($func,{"id" => $array->[2]});
	} else {
		$obj = $self->$prov()->queryObject($func,{$array->[1] => $array->[2]});
	}
	if (!defined($obj)) {
		ModelSEED::utilities::verbose("Could not find ".$ref."!");
	}
	return ($obj,$array->[0],$array->[1],$array->[2]);
}

sub parseReferenceList {
	my $self = shift;
	my $args = ModelSEED::utilities::args([], { string => "none", delimiter => "|", data => "obj", class => undef }, @_);
	my $output = [];
	if (!defined($args->{array})) {
		$args->{array} = ModelSEED::utilities::parseArrayString($args);
	}
	for (my $i=0; $i < @{$args->{array}}; $i++) {
		(my $obj) = $self->interpretReference($args->{array}->[$i],$args->{class});
		if (defined($obj)) {
			if ($args->{data} eq "obj") {
				push(@{$output},$obj);
			} elsif ($args->{data} eq "uuid") {
				push(@{$output},$obj->uuid());
			}	
		}
	}
	return $output;
}
######################################################################
#Output functions
######################################################################
sub htmlComponents {
	my $self = shift;
	my $args = ModelSEED::utilities::args([],{}, @_);
	my $data = $self->_createReadableData();
	my $output = {
		title => $self->_type()." Viewer",
		tablist => [],
		tabs => {
			main => {
				content => "",
				name => "Overview"
			}
		}
	};
	$output->{tabs}->{main}->{content} .= "<table>\n";
	for (my $i=0; $i < @{$data->{attributes}->{headings}}; $i++) {
		$output->{tabs}->{main}->{content} .= "<tr><th>".$data->{attributes}->{headings}->[$i]."</th><td style='font-size:16px;border: 1px solid black;'>".$data->{attributes}->{data}->[0]->[$i]."</td></tr>\n";
	}
	$output->{tabs}->{main}->{content} .= "</table>\n";
	my $count = 2;
	foreach my $subobject (@{$data->{subobjects}}) {
		my $name = $self->_type()." ".$subobject->{name};
		my $id = "tab-".$count;
		push(@{$output->{tablist}},$id);
		$output->{tabs}->{$id} = {
			content => ModelSEED::utilities::PRINTHTMLTABLE( $subobject->{headings}, $subobject->{data}, 'data-table' ),
			name => $name
		};
		$count++;
	}
	return $output;
}

sub createHTML {
	my $self = shift;
	my $args = ModelSEED::utilities::args([],{internal => 0}, @_);
	my $document = "";
	if ($args->{internal} == 0) {
		$document .= $htmlheader."\n";
	}
	$document .= $htmlbody."\n";
	if ($args->{internal} == 0) {
		$document .= $htmltail;
	}
	my $htmlData = $self->htmlComponents();
	my $title = $htmlData->{title};
	$document =~ s/\$\{TITLE\}/$title/;
	my $tablist = "";
	foreach my $id (@{$htmlData->{tablist}}) {
		$tablist .= '<li><a href="#'.$id.'">'.$htmlData->{tabs}->{$id}->{name}."</a></li>\n";
	}
	$document =~ s/\$\{TABS\}/$tablist/;
	my $maintab = $htmlData->{tabs}->{main}->{content};
	$document =~ s/\$\{MAINTAB\}/$maintab/;
	my $divdata = "";
	for (my $i=0; $i < @{$htmlData->{tablist}}; $i++) {
		$divdata .= '<div class="tab-pane" id="'.$htmlData->{tablist}->[$i].'">'."\n";
		$divdata .= $htmlData->{tabs}->{$htmlData->{tablist}->[$i]}->{content};
		$divdata .= "</div>\n";
	}
	$document =~ s/\$\{TABDIVS\}/$divdata/;
	return $document;
}

sub toReadableString {
	my ($self, $asArray) = @_;
	my $output = ["Attributes {"];
	my $data = $self->_createReadableData();
	for (my $i=0; $i < @{$data->{attributes}->{headings}}; $i++) {
		push(@{$output},"\t".$data->{attributes}->{headings}->[$i].":".$data->{attributes}->{data}->[0]->[$i])
	}
	push(@{$output},"}");
	if (defined($data->{subobjects})) {
		for (my $i=0; $i < @{$data->{subobjects}}; $i++) {
			push(@{$output},$data->{subobjects}->[$i]->{name}." (".join("\t",@{$data->{subobjects}->[$i]->{headings}}).") {");
			for (my $j=0; $j < @{$data->{subobjects}->[$i]->{data}}; $j++) {
				push(@{$output},join("\t",@{$data->{subobjects}->[$i]->{data}->[$j]}));
			}
			push(@{$output},"}");
		}
	}
	if (defined($data->{results})) {
		for (my $i=0; $i < @{$data->{results}}; $i++) {
			my $rs = $data->{results}->[$i];
			my $objects = $self->$rs();
			if (defined($objects->[0])) {
				push(@{$output},$rs." objects {");
				for (my $j=0; $j < @{$objects}; $j++) {
					push(@{$output},@{$objects->[$j]->toReadableString("asArray")});
				}
				push(@{$output},"}");
			}
		}
	}
    return join("\n", @$output) unless defined $asArray;
	return $output;
}

sub _createReadableData {
	my ($self) = @_;
	my $data;
	my ($sortedAtt,$sortedSO,$sortedRS) = $self->_getReadableAttributes();
	$data->{attributes}->{headings} = $sortedAtt;
	for (my $i=0; $i < @{$data->{attributes}->{headings}}; $i++) {
		my $att = $data->{attributes}->{headings}->[$i];
		push(@{$data->{attributes}->{data}->[0]},$self->$att());
	}
	for (my $i=0; $i < @{$sortedSO}; $i++) {
		my $so = $sortedSO->[$i];
		my $soData = {name => $so};
		my $objects = $self->$so();
		if (defined($objects->[0])) {
			my ($sortedAtt,$sortedSO) = $objects->[0]->_getReadableAttributes();
			$soData->{headings} = $sortedAtt;
			for (my $j=0; $j < @{$objects}; $j++) {
				for (my $k=0; $k < @{$sortedAtt}; $k++) {
					my $att = $sortedAtt->[$k];
					$soData->{data}->[$j]->[$k] = ($objects->[$j]->$att() || "");
				}
			}
			push(@{$data->{subobjects}},$soData);
		}
	}
	for (my $i=0; $i < @{$sortedRS}; $i++) {
		push(@{$data->{results}},$sortedRS->[$i]);
	}
	return $data;
 }
 
sub _getReadableAttributes {
	my ($self) = @_;
	my $priority = {};
	my $attributes = [];
	my $prioritySO = {};
	my $attributesSO = [];
	my $priorityRS = {};
	my $attributesRS = [];
	my $class = 'ModelSEED::MS::'.$self->_type();
	foreach my $attr ( $class->meta->get_all_attributes ) {
		if ($attr->isa('ModelSEED::MS::Metadata::Attribute::Typed') && $attr->printOrder() != -1 && ($attr->type() eq "attribute" || $attr->type() eq "msdata")) {
			push(@{$attributes},$attr->name());
			$priority->{$attr->name()} = $attr->printOrder();
		} elsif ($attr->isa('ModelSEED::MS::Metadata::Attribute::Typed') && $attr->printOrder() != -1 && $attr->type() =~ m/^result/) {
			push(@{$attributesRS},$attr->name());
			$priorityRS->{$attr->name()} = $attr->printOrder();
		} elsif ($attr->isa('ModelSEED::MS::Metadata::Attribute::Typed') && $attr->printOrder() != -1) {
			push(@{$attributesSO},$attr->name());
			$prioritySO->{$attr->name()} = $attr->printOrder();
		}
	}
	my $sortedAtt = [sort { $priority->{$a} <=> $priority->{$b} } @{$attributes}];
	my $sortedSO = [sort { $prioritySO->{$a} <=> $prioritySO->{$b} } @{$attributesSO}];
	my $sortedRS = [sort { $priorityRS->{$a} <=> $priorityRS->{$b} } @{$attributesRS}];
	return ($sortedAtt,$sortedSO,$sortedRS);
}
######################################################################
#SubObject manipulation functions
######################################################################

sub add {
    my ($self, $attribute, $data_or_object) = @_;

    my $attr_info = $self->_subobjects($attribute);
    if (!defined($attr_info)) {
        ModelSEED::utilities::error("Object doesn't have subobject with name: $attribute");
    }

    my $obj_info = {
        created => 0,
        class => $attr_info->{class}
    };

    my $ref = ref($data_or_object);
    if ($ref eq "HASH") {
        # need to create object first
        $obj_info->{data} = $data_or_object;
        $self->_build_object($attribute, $obj_info);
    } elsif ($ref =~ m/ModelSEED::MS/) {
        $obj_info->{object} = $data_or_object;
        $obj_info->{created} = 1;
    } else {
        ModelSEED::utilities::error("Neither data nor object passed into " . ref($self) . "->add");
    }

    $obj_info->{object}->parent($self);
    my $method = "_$attribute";
    push(@{$self->$method}, $obj_info);
    return $obj_info->{object};
}

sub remove {
    my ($self, $attribute, $object) = @_;

    my $attr_info = $self->_subobjects($attribute);
    if (!defined($attr_info)) {
        ModelSEED::utilities::error("Object doesn't have attribute with name: $attribute");
    }

    my $removedCount = 0;
    my $method = "_$attribute";
    my $array = $self->$method;
    for (my $i=0; $i<@$array; $i++) {
        my $obj_info = $array->[$i];
        if ($obj_info->{created}) {
            if ($object eq $obj_info->{object}) {
                splice(@$array, $i, 1);
                $removedCount += 1;
            }
        }
    }

    return $removedCount;
}

# can only get via uuid
sub getLinkedObject {
    my ($self, $sourceType, $attribute, $uuid) = @_;
    my $source = lc($attribute);
    if ($sourceType eq 'ModelSEED::Store') {
    	if (!defined($self->store)) {
        	ModelSEED::utilities::error("Getting object from undefined store!");
        }
        if (ref($self->store) eq "ModelSEED::Store") {
        	my $refName = lc(substr($attribute, 0,1)).substr($attribute,1);
        	my $ref = ModelSEED::Reference->new(uuid => $uuid, type => $refName);
        	return $self->store->get_object($ref);	
        } else {
        	return $self->store->get_object($attribute,$uuid);
        }
    } else {
        my $source = lc($sourceType);
        my $sourceObj = $self->$source();
        my $object;
        unless(defined $sourceObj) {
            ModelSEED::Exception::BadObjectLink->throw(
                searchSource    => $self,
                searchBaseType  => $sourceType,
                searchAttribute => $attribute,
                searchUUID      => $uuid,
                errorText => "No base object with $sourceType found",
            );
        }
        $object = $sourceObj->getObject($attribute,$uuid);
		if (!defined($object) && $attribute eq "media" && $sourceType eq "Biochemistry" && ref($self->store) eq "ModelSEED::KBaseStore") {
			$object = $self->store()->get_object("Media",$uuid);
			if (defined($object)) {
				$sourceObj->add("media",$object);
			}
		}
        return $object if defined $object;
        ModelSEED::utilities::error("Could not find UUID ".$uuid."!");
#        ModelSEED::Exception::BadObjectLink->throw(
#            searchSource     => $self,
#            searchBaseObject => $sourceObj,
#            searchBaseType   => $sourceType,
#            searchAttribute  => $attribute,
#            searchUUID       => $uuid,
#            errorText        => 'No object found with that UUID',
#        );
        return;
    }
}

sub getLinkedObjectArray {
    my ($self, $sourceType, $attribute, $array) = @_;
    my $list = [];
    foreach my $item (@{$array}) {
    	push(@{$list},$self->getLinkedObject($sourceType,$attribute,$item));
    }
    return $list;
}

sub removeLinkArrayItem {
	my ($self,$link,$object) = @_;
    my $linkdata = $self->_links($link);
    if (defined($linkdata) && $linkdata->{array} == 1) {
    	my $method = $linkdata->{attribute};
    	my $data = $self->$method();
    	for (my $i=0; $i < @{$data}; $i++) {
			if ($data->[$i] eq $object->uuid()) {
				ModelSEED::utilities::verbose("Removing object from link array.");
				if (@{$data} == 1) {
					$self->$method([]);
				} else {
					splice(@{$data},$i,1);
					$self->$method($data);
				}
				my $clearer = "clear_".$link;
				$self->$clearer();
			}
		}
    }	
}

sub replaceLinkArrayItem {
	my ($self,$link,$oldObject,$newObject) = @_;
    my $linkdata = $self->_links($link);
    my $olduuid;
    my $newuuid;
    if (ref($oldObject) eq "SCALAR") {
    	$olduuid = $oldObject;
    } else {
    	$olduuid = $oldObject->uuid();
    }
     if (ref($newuuid) eq "SCALAR") {
    	$newuuid = $newuuid;
    } else {
    	$newuuid = $newuuid->uuid();
    }
    if (defined($linkdata) && $linkdata->{array} == 1) {
    	my $method = $linkdata->{attribute};
    	my $data = $self->$method();
    	for (my $i=0; $i < @{$data}; $i++) {
			if ($data->[$i] eq $olduuid) {
				ModelSEED::utilities::verbose("Replacing object in link array.");
				$data->[$i] = $newuuid;
				my $clearer = "clear_".$link;
				$self->$clearer();
			}
		}
    }	
}

sub addLinkArrayItem {
	my ($self,$link,$object) = @_;
    my $linkdata = $self->_links($link);
    if (defined($linkdata) && $linkdata->{array} == 1) {
    	my $method = $linkdata->{attribute};
    	my $data = $self->$method();
    	my $found = 0;
    	for (my $i=0; $i < @{$data}; $i++) {
			if ($data->[$i] eq $object->uuid()) {
				$found = 1;
			}
    	}
    	if ($found == 0) {
    		ModelSEED::utilities::verbose("Adding object to link array.");
    		my $clearer = "clear_".$link;
			$self->$clearer();
			push(@{$data},$object->uuid());
    	}
    }	
}

sub clearLinkArray {
	my ($self,$link) = @_;
    my $linkdata = $self->_links($link);
    if (defined($linkdata) && $linkdata->{array} == 1) {
    	my $method = $linkdata->{attribute};
    	$self->$method([]);
    	ModelSEED::utilities::verbose("Clearing link array.");
    	my $clearer = "clear_".$link;
		$self->$clearer();
    }	
}

sub biochemistry {
    my ($self) = @_;
    my $parent = $self->parent();
    if (defined($parent) && ref($parent) eq "ModelSEED::MS::Biochemistry") {
        return $parent;
    } elsif (ref($self) eq "ModelSEED::MS::Biochemistry") {
    	return $self;
	} elsif (defined($parent)) {
        return $parent->biochemistry();
    }
    ModelSEED::utilities::error("Cannot find Biochemistry object in tree!");
}

sub fbaformulation {
    my ($self) = @_;
    my $parent = $self->parent();
    if (defined($parent) && ref($parent) eq "ModelSEED::MS::FBAFormulation") {
        return $parent;
    } elsif (defined($parent)) {
        return $parent->fbaformulation();
    }
    ModelSEED::utilities::error("Cannot find FBAFormulation object in tree!");
}

sub model {
    my ($self) = @_;
    my $parent = $self->parent();
    if (defined($parent) && ref($parent) eq "ModelSEED::MS::Model") {
        return $parent;
    } elsif (defined($parent)) {
        return $parent->model();
    }
    ModelSEED::utilities::error("Cannot find Model object in tree!");
}

sub annotation {
    my ($self) = @_;
    my $parent = $self->parent();
    if (defined($parent) && ref($parent) eq "ModelSEED::MS::Annotation") {
        return $parent;
    } elsif (defined($parent)) {
        return $parent->annotation();
    }
    ModelSEED::utilities::error("Cannot find Annotation object in tree!");
}

sub configuration {
    my ($self) = @_;
    my $parent = $self->parent();
    if (defined($parent) && ref($parent) eq "ModelSEED::MS::Configuration") {
        return $parent;
    } elsif (defined($parent)) {
        return $parent->configuration();
    }
    ModelSEED::utilities::error("Cannot find Configuration object in tree!");
}

sub mapping {
    my ($self) = @_;
    my $parent = $self->parent();
    if (defined($parent) && ref($parent) eq "ModelSEED::MS::Mapping") {
        return $parent;
    } elsif (defined($parent)) {
        return $parent->mapping();
    }
    ModelSEED::utilities::error("Cannot find mapping object in tree!");
}

sub biochemistrystructures {
    my ($self) = @_;
    print $self->_type()."\n";
    my $parent = $self->parent();
    if (defined($parent) && ref($parent) eq "ModelSEED::MS::BiochemistryStructures") {
        return $parent;
    } elsif (defined($parent)) {
       	return $parent->biochemistrystructures();
    }
    ModelSEED::utilities::error("Cannot find BiochemistryStructures object in tree!");
}

sub fbaproblem {
    my ($self) = @_;
    my $parent = $self->parent();
    if (defined($parent) && ref($parent) eq "ModelSEED::MS::FBAProblem") {
        return $parent;
    } elsif (defined($parent)) {
        return $parent->fbaproblem();
    }
    ModelSEED::utilities::error("Cannot find fbaproblem object in tree!");
}

sub store {
    my ($self) = @_;
    my $parent = $self->parent();
    if (defined($parent) && ref($parent) ne "ModelSEED::Store" && ref($parent) ne "ModelSEED::KBaseStore") {
        return $parent->store();
    }
    return $parent;
}

sub updateLinks {
    my ($self,$type,$translation,$recursive,$transferaliases) = @_;
    if ($self->_type() eq "AliasSet") {
    	if ($self->class() eq $type) {
    		my $uuidHash = $self->aliasesByuuid();
    		my $aliases = $self->aliases();
    		foreach my $olduuid (keys(%{$translation})) {
	    		my $newuuid = $translation->{$olduuid};
	    		if (defined($uuidHash->{$olduuid})) {
	    			my $aliaselist = $uuidHash->{$olduuid};
	    			my $aliasesToAdd = [];
	    			for (my $j=0; $j < @{$aliaselist}; $j++) {
	    				my $alias = $aliaselist->[$j];
						my $found = 0;
						print $j."\t".$alias."\n";
						for (my $i=0; $i < @{$aliases->{$alias}}; $i++) {
							print $i."\n";
							if ($aliases->{$alias}->[$i] eq $olduuid) {
								splice(@{$aliases->{$alias}},$i,1);
								if (@{$aliases->{$alias}} > 0) {
									$i--;
								}
							} elsif ($aliases->{$alias}->[$i] eq $newuuid) {
								$found = 1;
							}
						}
						if (@{$aliases->{$alias}} == 0) {
							delete $aliases->{$alias};
						}
						if ($transferaliases == 1 && $found == 0) {
							push(@{$aliases->{$alias}},$newuuid);
							push(@{$aliasesToAdd},$alias);
						}
					}
					if (@{$aliasesToAdd} > 0) {
						push(@{$uuidHash->{$newuuid}},@{$aliasesToAdd});
					}
	    		}
    		}
    	}
    	return;
    }
    if ($self->_type() eq "Biochemistry") {
	my $old_forwards = $self->forwardedLinks();
	
	foreach my $old_forward (keys %$old_forwards){
	    if(exists($translation->{$old_forward})){
		$old_forwards->{$old_forward}=$translation->{$old_forward};
	    }
	}

	$self->forwardedLinks($old_forwards);
    }

    my $links = $self->_links();
    for (my $i=0; $i < @{$links}; $i++) {
    	my $link = $links->[$i];
    	if ($link->{class} eq $type) {
    		my $attribute = $link->{attribute};
    		my $clearer = $link->{clearer};
    		my $data = $self->$attribute();
    		if (defined($data)) {
	    		if (defined($link->{array}) && $link->{array} == 1) {
	    			for (my $j=0; $j < @{$data}; $j++) {
	    				if (defined($translation->{$data->[$j]})) {
	    					$data->[$j] = $translation->{$data->[$j]};
	    					$self->$clearer();
	    				}
	    			}
	    		} elsif (defined($translation->{$data})) {
    				$self->$attribute($translation->{$data});
    				$self->$clearer();
    			}
    		}
    	}
    }
    if ($recursive == 1) {
    	my $sos = $self->_subobjects();
    	for (my $i=0; $i < @{$sos}; $i++) {
    		my $so = $sos->[$i]->{name};
    		my $objects = $self->$so();
    		for (my $j=0; $j < @{$objects}; $j++) {
    			$objects->[$j]->updateLinks($type,$translation,$recursive,$transferaliases);
    		}
    	} 
    }
}

sub msStoreID {
	my ($self) = @_;
	return $self->{_msStoreID};
}

sub msStoreRef {
	my ($self) = @_;
	return $self->{_msStoreRef};
}

sub _build_object {
    my ($self, $attribute, $obj_info) = @_;

    if ($obj_info->{created}) {
        return $obj_info->{object};
    }
	my $attInfo = $self->_subobjects($attribute);
    if (!defined($attInfo->{class})) {
    	ModelSEED::utilities::error("No class for attribute ".$attribute);	
    }
    my $class = 'ModelSEED::MS::' . $attInfo->{class};
    Module::Load::load $class;
    my $obj = $class->new($obj_info->{data});

    $obj_info->{created} = 1;
    $obj_info->{object} = $obj;
    delete $obj_info->{data};

    return $obj;
}

sub _build_all_objects {
    my ($self, $attribute) = @_;

    my $objs = [];
    my $method = "_$attribute";
    my $subobjs = $self->$method();
    foreach my $subobj (@$subobjs) {
        push(@$objs, $self->_build_object($attribute, $subobj));
    }

    return $objs;
}

sub __version__ { $VERSION }
sub __upgrade__ { return sub { return $_[0] } }

__PACKAGE__->meta->make_immutable;
1;
