########################################################################
# ModelSEED::MS::Factories::SBMLFactory
# 
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location:
#   Mathematics and Computer Science Division, Argonne National Lab;
#   Computation Institute, University of Chicago
#
# Date of module creation: 2012-06-03
########################################################################

=head1 ModelSEED::MS::Factories::SBMLFactory

A Factory that creates a model or biochemistry from an SBML file.

=head2 Methods

=head3 createModel

    $model = $fact->createModel(\%config);

Construct a L<ModelSEED::MS::Model> object. Config is
a hash ref that accepts the following:

=over 4

=item id

The filename of the SBML file to be imported. Required.

=item annotation

A L<ModelSEED::MS::Annotation> object. Required.

=back

=cut

package ModelSEED::MS::Factories::SBMLFactory;
use ModelSEED::utilities;
use Class::Autouse qw(
    ModelSEED::Auth::Factory
    ModelSEED::Auth
    ModelSEED::MS::Model
    ModelSEED::MS::Biomass
);
use Try::Tiny;
use Moose;
use namespace::autoclean;

has auth => ( is => 'ro', isa => "ModelSEED::Auth", required => 1);
has store => ( is => 'ro', isa => "ModelSEED::Store", required => 1);
has auth_config => ( is => 'ro', isa => 'HashRef', lazy => 1, builder => '_build_auth_config');

sub parseSBML {
    my ($self, $args) = @_;
	$args = ModelSEED::utilities::ARGS($args,["id", "annotation"],{
        verbose => 0,
       	namespace => undef
	});
	my $filename = $args->{id};
	if (!-e $args->{id}) {
		ModelSEED::utilities::ERROR("SBML file not found!");
	}
    my $parser = XML::DOM::Parser->new();
    my $doc = $parser->parsefile($filename);
    #Parsing model name
    my $mdls = [$doc->getElementsByTagName("model")];
    my $mdlid = "Unknown";
    my $mdlname = "Unknown";
    if (!defined($mdls->[0])) {
		foreach my $attr ($mdls->[0]->getAttributes()->getValues()) {
			my $name = $attr->getName();
    		my $value = $attr->getValue();
			if ($name eq "id") {
				$mdlid = $value;
			} elsif ($name eq "name") {
				$mdlname = $value;
			}
		}
	}
    if (!defined($args->{namespace})) {
		$args->{namespace} = $mdlid;
	}
    my $bio = ModelSEED::MS::Biochemistry->new({
    	defaultNameSpace => $args->{namespace},
    	name => $mdlname
    });
    my $mdl;
    if (defined($args->{annotation})) {
	    $mdl = ModelSEED::MS::Model->new({
	    	defaultNameSpace => $args->{namespace},
	    	name => $mdlname,
	    	id => $mdlid,
	    	annotation_uuid => $args->{annotation}
	    });
    }
	#Adding compartments to the biochemistry
    my $cmpts = [$doc->getElementsByTagName("compartment")];
    foreach my $cmpt (@$cmpts){
    	my $data = {};
    	foreach my $attr ($cmpt->getAttributes()->getValues()) {
    		my $name = $attr->getName();
    		my $value = $attr->getValue();
    		if ($name eq "id") {
    			$data->{id} = $value;
    		}
    	}
    	if (!defined($data->{name})) {
    		$data->{name} = $data->{id};
    	}
    	if (defined($data->{id})) {
    		$bio->add("compartments",$data);
    	}
	}
    #Adding compounds to model and biochemistry 
    my $cpdhash = {};
    my $mdlcpdHash = {};
    my $mdlcpdidHash = {};
    my $cpds = [$doc->getElementsByTagName("species")];
    my $cpdAtts = {
    	id => "id",
    	name => "name",
    	compartment => "compartment",
    	charge => "defaultCharge",
    	boundaryCondition => "boundary",
    };
    foreach my $cpd (@$cpds){
    	my $data = {};
    	my $mdldata = {};
    	my $fileid;
    	my $mdlid;
    	foreach my $attr ($cpd->getAttributes()->getValues()) {
    		my $name = $attr->getName();
    		my $value = $attr->getValue();
    		if (defined($cpdAtts->{$name})) {
    			my $heading = $cpdAtts->{$name};
    			if ($heading eq "id") {
    				$fileid = $heading;
    				if ($value =~ m/^(.+)_(\w+)$/) {
    					
    				}
    			} else {
    				$data->{$heading} = $value;
    			}
			}
    	}
    	if (!defined($cpdhash->{$id})) {
    		my $cpd = $bio->add("compounds",$data);
    		$cpdhash->{$id} = $cpd;
    		$biochemistry->addAlias({
				attribute => "compounds",
				aliasName => $args->{namespace},
				alias => $id,
				uuid => $cpd->uuid()
			});
    	}
    	if (defined($mdl) && !defined($mdlcpdHash->{$mdlid})) {
    		my $mdlcpd = $mdl->add("modelcompounds",$mdldata);
    		$mdlcpdHash->{$mdlid} = $mdlcpd;
    		$mdlcpdidHash->{$fileid} = $mdlcpd;
    	}
    }
    #Adding reactions to model and biochemistry	
	my $rxnhash = {};
    my $mdlrxnHash = {};
    my $mdlrxnidHash = {};
    my $rxns = [$doc->getElementsByTagName("reaction")];
    foreach my $rxn (@$rxns){
    	my $data = {};
    	my $mdldata = {};
    	my $fileid;
    	my $mdlid;
    	my $id;
    	foreach my $attr ($rxn->getAttributes()->getValues()) {
    		my $name = $attr->getName();
    		my $value = $attr->getValue();
    		if ($name eq "id") {
    			$id = $value;
    			$fileid = $value;
    			$mdlid = $value;
    			$data->{abbreviation} = $value;
    		} elsif ($name eq "name") {
    			$data->{name} = $value;
    		} elsif ($name eq "reversible") {
    			if ($value eq "true") {
    				$data->{direction} = "=";
    				$mdldata->{direction} = "=";
    				$data->{thermoReversibility} = "=";
    			} else {
    				$data->{direction} = ">";
    				$mdldata->{direction} = ">";
    				$data->{thermoReversibility} = ">";
    			}
    		} else {
    			print $name.":".$value."\n";
    		}
    	}
    	if (!defined($rxnhash->{$fileid})) {
    		my $rxn = $bio->add("reactions",$data);
    		$rxnhash->{$fileid} = $rxn;
    		$biochemistry->addAlias({
				attribute => "reactions",
				aliasName => $args->{namespace},
				alias => $fileid,
				uuid => $rxn->uuid()
			});
    	}
    	if (defined($rxnhash->{$fileid}) && defined($mdl) && !defined($mdlrxnHash->{$mdlid})) {
    		$mdldata->{reaction_uuid} = $rxnhash->{$fileid}->uuid();
    		my $mdlrxn = $mdl->add("modelreactions",$mdldata);
    		$mdlrxnHash->{$mdlid} = $mdlrxn;
    		$mdlrxnidHash->{$fileid} = $mdlrxn;
    	}
    }
	
	return ($bio,$mdl);
}

    
sub traverse_sbml {
    my $node=shift;
    my $prev_path=shift;
    my $path=shift;
    my $nodehash=shift;
    my @children=$node->getElementsByTagName("*",0);

    if(scalar(@children)==0){
	my $textstring=undef;
	$textstring=$node->getFirstChild()->getNodeValue() if $node->hasChildNodes();
	$nodehash->{$path}{$textstring}=1 if defined($textstring);
	foreach my $attr(@{$node->getAttributes()->getValues()}){
	    $nodehash->{$path}{$attr->getName().":".$attr->getValue()}=1;
	}
	return $prev_path;
    }

    foreach my $n (@children){
	$prev_path=$path;
	unless($path =~ /a?n{1,2}ot[ea][st]/i){  #Notes and Annotation fields have needless <html> and <p> elements
	    $path.="|" if $path ne "";
	    $path.=$n->getNodeName();
	}
	$path=traverse_sbml($n,$prev_path,$path,$nodehash);
    }
    return $path;
}
	
	

    #go through all compounds in case of irregular attributes
    foreach my $cmpd(@cmpds){
	foreach my $attr($cmpd->getAttributes()->getValues()){
	    $name=$attr->getName();
	    $HeadingTranslation{$name}=uc($name);
	    $HeadingTranslation{$name} .= ($name eq "name") ? "S" : "";
	    $cmpdAttrs{$HeadingTranslation{$name}}= (exists($TableHeadings{$attr->getName()})) ? $TableHeadings{$attr->getName()} : 100;
	}
    }

    foreach my $cmpd (@cmpds){
	my $row={};
	foreach my $attr($cmpd->getAttributes()->getValues()){
#	    print $attr->getName(),"\n";
	    $row->{$HeadingTranslation{$attr->getName()}}->[0]=$attr->getValue();
	    if($attr->getValue() =~ /([CG]\d{5})/){
		$row->{KEGG}->[0]=$1;
	    }
	}
	$CmpdCmptTranslation{$row->{ID}->[0]}=$row->{COMPARTMENT}->[0];
	$row->{METACYC}->[0]="";
	$row->{KEGG}->[0]="" if !exists($row->{KEGG});
	$row->{NAMES}->[0]=$row->{ID}->[0] if !exists($row->{NAMES});
	$TableList->{compound}->add_row($row);
    }

    my @rxns = $doc->getElementsByTagName("reaction");
    my %rxnAttrs=();
    foreach my $rxn(@rxns){
	foreach my $attr($rxn->getAttributes()->getValues()){
	    $name=$attr->getName();
	    $HeadingTranslation{$name}=uc($name);
	    $HeadingTranslation{$name} .= ($name eq "name") ? "S" : "";
	    $HeadingTranslation{$name} = ($name eq "reversible") ? "DIRECTIONALITY" : $HeadingTranslation{$name};
	    $rxnAttrs{$HeadingTranslation{$name}}= (exists($TableHeadings{$attr->getName()})) ? $TableHeadings{$attr->getName()} : 100;
	}
    }

    my $nodehash={};
    foreach my $node($rxns[0]->getElementsByTagName("*",0)){
	next if $node->getNodeName() =~ "^listOf";
	my $path=$node->getNodeName();
	traverse_sbml($node,"",$path,$nodehash);
    }
    foreach my $key (keys %$nodehash){
	$HeadingTranslation{$key}=uc($key);
	$HeadingTranslation{$key} = ($key eq "annotation") ? "NOTES" : $HeadingTranslation{$key};
	$rxnAttrs{$HeadingTranslation{$key}}= (exists($TableHeadings{$key})) ? $TableHeadings{$key} : 100;
    }


    foreach my $rxn (@rxns){
		foreach my $attr($rxn->getAttributes()->getValues()){
	    $row->{$HeadingTranslation{$attr->getName()}}->[0]=$attr->getValue();

	    #grep for EC numbers
	    my $tv=$attr->getValue();
	    while($tv =~ /([\d]+\.[\d-]+\.[\d-]+\.[\d-]+)/g){
 		$ec{$1}=1;
	    }
	    
	    if($attr->getName() eq "reversible"){
		$row->{DIRECTIONALITY}->[0]="=>" if $attr->getValue() eq "false";
		$row->{DIRECTIONALITY}->[0]="<=>" if $attr->getValue() eq "true";
	    }
	}

	my $nodehash={};
	foreach my $node($rxn->getElementsByTagName("*",0)){
	    next if $node->getNodeName() =~ "^listOf";
	    my $path=$node->getNodeName();
	    traverse_sbml($node,"",$path,$nodehash);
	}
	foreach my $key (keys %$nodehash){
	    #grep for EC numbers
	    my $tv=join("|",sort keys %{$nodehash->{$key}});
	    while($tv =~ /([\d]+\.[\d-]+\.[\d-]+\.[\d-]+)/g){
 		$ec{$1}=1;
	    }

	    $row->{$HeadingTranslation{$key}}->[0]=$tv;
	}
}

sub _build_auth_config {
    my ($self) = @_;
    if($self->auth->isa("ModelSEED::Auth::Basic")) {
        return { user => $self->auth->username,
                 password => $self->auth->password,
               };
    } else {
        return {};
    }
}

sub _get_uuid_from_alias {
    my ($self, $ref) = @_;
    return unless(defined($ref));
    my $alias_objects = $self->store->get_aliases($ref);
    if(defined($alias_objects->[0])) {
        return $alias_objects->[0]->{uuid}
    } else {
        return;
    }
}

1;
