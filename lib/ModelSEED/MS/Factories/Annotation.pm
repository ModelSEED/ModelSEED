########################################################################
# ModelSEED::MS::Factories::Annotation
# 
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location:
#   Mathematics and Computer Science Division, Argonne National Lab;
#   Computation Institute, University of Chicago
#
# Date of module creation: 2012-06-03
########################################################################
#TODO: refactor code, too much repeating yourself now.

=head1 ModelSEED::MS::Factories::Annotation

A factory for producing an Annotation object from several data
sources.

=head2 ABSTRACT

    my $fact = ModelSEED::MS::Factories::Annotation->new;
    
    # Get list of available genome IDs
    my $genomes = $fact->availableGenomes();
    my $kbase_genomes = $fact->availableGenomes(source => 'KBase');
    my $rast_genomes = $fact->availableGenomes(source => 'RAST');
    my $pubseed_genomes = $fact->availableGenomes(source => 'PubSEED');
    # These are all hash refs of genome IDs as keys and scientific names as values
    
    # Create a MS::Annotation object from a genome
    my $anno = $fact->build({ genome_id => "kb|g.0", mapping => $mapping });

=head3 availableGenomes

    my $hash = $fact->availableGenomes(source => "KBase");

List available genomes. If C<source> is povided, restrict query to
a specific genome source. Returns a hash reference of genome id to
scientific name.

=head3 build

    my $anno = $factory->build($config);

Build an annotation object from configuration information. <$config> is a hash reference
that must contain the key C<genome_id>, with the genome to import. In addition, C<mapping>
or C<mapping_uuid> must be supplied. Optional parameters:

=over 4

=item source

One of PubSEED, KBase, RAST.

=item verbose

Print verbose status information.

=item mapping_uuid

UUID of mapping object to use.

=item mapping>

L<ModelSEED::MS::Mapping> object to use.

=back

=head3 genomeSource

   $source = $factory->genomeSource($id); 

Returns C<$source> a string indicating the source for the genome ID.
The souce may currently be one of "SEED", "RAST", "KBASE".

=cut

package ModelSEED::MS::Factories::Annotation;
use common::sense;
use Moose;
use namespace::autoclean;
use Class::Autouse qw(
    Bio::KBase::CDMI::Client
    ModelSEED::Auth::Factory
	ModelSEED::MS::Mapping
	ModelSEED::MS::Annotation
    ModelSEED::Client::SAP
    ModelSEED::Client::MSSeedSupport
);
use ModelSEED::utilities qw( verbose args );
use ModelSEED::MS::Utilities::GlobalFunctions;
has auth => ( is => 'rw', does => 'ModelSEED::Auth', builder => '_build_auth' );
has sapsvr => (
    is      => 'rw',
    isa     => 'ModelSEED::Client::SAP',
    lazy    => 1,
    builder => '_build_sapsvr'
);
has kbsvr => (
    is      => 'rw',
    isa     => 'Bio::KBase::CDMI::Client',
    lazy    => 1,
    builder => '_build_kbsvr'
);
has msseedsvr => (
    is      => 'rw',
    isa     => 'ModelSEED::Client::MSSeedSupport',
    lazy    => 1,
    builder => '_build_msseedsvr'
);

sub availableGenomes {
    my $self = shift @_;
    my $args = args([],{
    	source => undef
    }, @_);
    my $source = $args->{source};
    my $servers = [qw(sapsvr kbsvr msseedsvr)];
    if(defined($source)) {
        my %sourceMap = qw(
            pubseed sapsvr
            kbase kbsvr
            rast msseedsvr
        );
        die "Unknown Source: $source" unless(defined $sourceMap{lc($source)});
        $servers = [ $sourceMap{lc($source)} ];
    }
    my $data;
    foreach my $server (@$servers) {
        my $hash;
        if($server eq 'sapsvr') {
            $hash = $self->$server->all_genomes({-prokaryotic => 0});
        } elsif($server eq 'kbsvr') {
            $hash = $self->$server->all_entities_Genome(0, 10000000, [qw(scientific_name)]);
            $hash = { map { $_ => $hash->{$_}->{scientific_name} } keys %$hash };
        } elsif($server eq 'msseedsvr') {
            warn "Unable to list models from RAST at this time";
            $hash = {};
        }
        foreach my $key (keys %$hash) {
            $data->{$key} = $hash->{$key};
        }
    }
    return $data;
}

sub build {
    my $self = shift;
    my $args = args(["mapping","genome_id"],{
    	source => undef
    }, @_);
	unless(defined($args->{source})) {
		$args->{source} = $self->genomeSource($args->{genome_id});	
        verbose("Genome source is " . $args->{source});
	}
    verbose("Getting genome attributes...");
	my $genomeData = $self->_getGenomeAttributes($args->{genome_id});
    my $annoationObj = ModelSEED::MS::Annotation->new({
        name => $genomeData->{name}
    });
    my $genomeObj = $annoationObj->add("genomes", {
        id       => $args->{genome_id},
        name     => $genomeData->{name},
        source   => $args->{source},
        taxonomy => $genomeData->{taxonomy},
        size     => $genomeData->{size},
        gc       => $genomeData->{gc},
    });
	$annoationObj->mapping_uuid($args->{mapping}->uuid());
	$annoationObj->mapping($args->{mapping});
	if (!defined($genomeData->{features})) {
		$genomeData->{features} = $self->_getGenomeFeatures($args->{genome_id}, $args->{source});
	}
    my $featureCount = scalar(@{$genomeData->{features}});
    print "Mapping $featureCount genome feature to metabolic roles...\n" if($args->{verbose});
	for (my $i=0; $i < @{$genomeData->{features}}; $i++) {
		my $row = $genomeData->{features}->[$i]; 
		if (defined($row->{ID}->[0]) && defined($row->{START}->[0]) && defined($row->{STOP}->[0]) && defined($row->{CONTIG}->[0])) {
			my $featureObj = $annoationObj->add("features",{
				id => $row->{ID}->[0],
				genome_uuid => $genomeObj->uuid(),
				start => $row->{START}->[0],
				stop => $row->{STOP}->[0],
				contig => $row->{CONTIG}->[0]
			});
			if (defined($row->{ROLES}->[0])) {
				for (my $j=0; $j < @{$row->{ROLES}}; $j++) {
					my $roleObj = $self->_getRoleObject({mapping => $args->{mapping},roleString => $row->{ROLES}->[$j]});
					my $ftrRoleObj =$featureObj->add("featureroles",{
						feature_uuid => $featureObj->uuid(),
						role_uuid => $roleObj->uuid(),
						compartment => join("|",@{$row->{COMPARTMENT}}),
						comment => $row->{COMMENT}->[0],
						delimiter => $row->{DELIMITER}->[0]
					});
				}
			}
		}
	}
	return $annoationObj;
}

sub _getRoleObject {
    my $self = shift;
	my $args = args(["roleString","mapping"], {}, @_);
	my $searchName = ModelSEED::MS::Utilities::GlobalFunctions::convertRoleToSearchRole($args->{roleString});
	my $roleObj = $args->{mapping}->queryObject("roles",{searchname => $searchName});
	if (!defined($roleObj)) {
		$roleObj = $args->{mapping}->add("roles",{
			name => $args->{roleString},
		});
	}
	return $roleObj;
}

sub genomeSource {
	my ($self,$id) = @_;
    my $result;
	$result = $self->sapsvr->exists({-type => 'Genome', -ids => [$id]});
	if (defined $result->{$id} && $result->{$id} eq 1) {
		return "PUBSEED";
	}
    $result = $self->kbsvr->get_entity_Genome([$id], []);
    if(defined($result->{$id})) {
        return "KBase";
    }
	$result = $self->msseedsvr->genomeType({ids => [$id]});
	return $result->{$id}->{source};
}

sub _getGenomeFeatures {
	my ($self, $id, $source) = @_;
    $source = $self->genomeSource($id) unless defined $source;
	my $features;
	if ($source eq "PUBSEED") {
		my $featureHash = $self->sapsvr->all_features({-ids => $id});
		if (!defined($featureHash->{$id})) {
			die "Could not load features for pubseed genome: $id";
		}
		my $featureList = $featureHash->{$id};
		my $functions = $self->sapsvr()->ids_to_functions({-ids => $featureList});
		my $locations = $self->sapsvr()->fid_locations({-ids => $featureList});
		#my $aliases = $self->sapsvr()->fids_to_ids({-ids => $featureList,-protein => 1});
		my $sequences;
		for (my $i=0; $i < @{$featureList}; $i++) {
			my $row = {ID => [$featureList->[$i]],TYPE => ["peg"]};
			if ($featureList->[$i] =~ m/\d+\.\d+\.([^\.]+)\.\d+$/) {
				$row->{TYPE}->[0] = $1;
			}
			if (defined($locations->{$featureList->[$i]}->[0]) && $locations->{$featureList->[$i]}->[0] =~ m/^(.+)_(\d+)([\+\-])(\d+)$/) {
				my $array = [split(/:/,$1)];
				$row->{CONTIG}->[0] = $array->[1];
				if ($3 eq "-") {
					$row->{START}->[0] = ($2-$4);
					$row->{STOP}->[0] = ($2);
					$row->{DIRECTION}->[0] = "rev";
				} else {
					$row->{START}->[0] = ($2);
					$row->{STOP}->[0] = ($2+$4);
					$row->{DIRECTION}->[0] = "for";
				}
			}
			if (defined($functions->{$featureList->[$i]})) {
				my $output = ModelSEED::MS::Utilities::GlobalFunctions::functionToRoles($functions->{$featureList->[$i]});
				$row->{COMPARTMENT} = $output->{compartments};
				$row->{COMMENT}->[0] = $output->{comment};
				$row->{DELIMITER}->[0] = $output->{delimiter};
				$row->{ROLES} = $output->{roles};
			}
			if (defined($sequences->{$featureList->[$i]})) {
				$row->{SEQUENCE}->[0] = $sequences->{$featureList->[$i]};
			}
			push(@{$features},$row);			
		}
	} elsif($source eq "KBase") {
        my $contigs  = $self->kbsvr->get_relationship_IsComposedOf([$id], [], [], [qw(id)]);
        $contigs = [ map { $_->[2]->{id} } @$contigs ]; # extract contig ids
        $features = $self->kbsvr->get_relationship_IsLocusFor(
            $contigs, [qw(id)],
            [qw(begin dir len ordinal)],
            [qw(id feature_type function source_id alias)]
        );
        # reformat features
        for (@$features) {
            $_ = {
                ID        => [ $_->[2]->{id} ],
                TYPE      => [ $_->[2]->{feature_type} ],
                CONTIG    => [ $_->[0]->{id} ],
                START     => [ $_->[1]->{begin} ],
                STOP      => [ $_->[1]->{begin} + $_->[1]->{len} ],
                DIRECTION => [ ( $_->[1]->{dir} eq "+" ) ? "for" : "rev" ],
                _FUNCTION => [ $_->[2]->{function} ],
                _SOURCE   => [ $_->[2]->{source_id} ],
                _ALIAS    => [ $_->[2]->{alias} ],
            };
        } 
        # add functions to each feature
        foreach my $feature (@$features) {
            my $output = ModelSEED::MS::Utilities::GlobalFunctions::functionToRoles($feature->{_FUNCTION}->[0]);
            $feature->{ROLES}          = $output->{roles};           # array
            $feature->{COMPARTMENT}    = $output->{compartments};    # array
            $feature->{COMMENT}->[0]   = $output->{comment};
            $feature->{DELIMITER}->[0] = $output->{delimiter};
            # Delete keys that start with an underscore
            foreach my $key (grep { $_ =~ /^_/ } keys %$feature) {
                delete $feature->{$key};
            }
        }
    } elsif( $source eq "RAST" ) {
        unless ( defined $self->auth && $self->auth->isa("ModelSEED::Auth::Basic") ) {
            die <<ERR;
You must be logged in to import a RAST genome.
Use the 'ms login' command with your RAST username,
and supply the password when promped. To confirm that
you are logged in, run 'ms whoami'
ERR
        }
        my $output = $self->msseedsvr()->genomeData(
            {
                ids      => [ $id ],
                username => $self->auth->username,
                password => $self->auth->password,
            }
        );
        $output->{$id} = $self->_parseRASTFeatures($output->{$id});
        $features = $output->{$id}->{features};
	}
	return $features;
}

sub _parseRASTFeatures {
	my ($self, $data) = @_;
	if (!defined($data->{features})) {
		die "Could not load data for rast genome!";
	}
	for (my $i=0; $i < @{$data->{features}}; $i++) {
		my $ftr = $data->{features}->[$i];
		my $row = {ID => [$ftr->{ID}],TYPE => ["peg"]};
		if ($row->{ID}->[0] =~ m/\d+\.\d+\.([^\.]+)\.\d+$/) {
			$row->{TYPE}->[0] = $1;
		}
		if (defined($ftr->{LOCATION}) && $ftr->{LOCATION} =~ m/^(.+)_(\d+)([\+\-_])(\d+)$/) {
			my $contigData = $1;
			if ($3 eq "-") {
				$row->{START}->[0] = ($2-$4);
				$row->{STOP}->[0] = ($2);
				$row->{DIRECTION}->[0] = "rev";
			} elsif ($3 eq "+") {
				$row->{START}->[0] = ($2);
				$row->{STOP}->[0] = ($2+$4);
				$row->{DIRECTION}->[0] = "for";
			} elsif ($2 > $4) {
				$row->{START}->[0] = $2;
				$row->{STOP}->[0] = $4;
				$row->{DIRECTION}->[0] = "rev";
			} else {
				$row->{START}->[0] = $2;
				$row->{STOP}->[0] = $4;
				$row->{DIRECTION}->[0] = "for";
			}
			if ($contigData =~ m/(.+):(.+)/) {
				$row->{CONTIG}->[0] = $2;
			} elsif ($contigData =~ m/(.+)\|(.+)\|(.+)\|(.+)/) {
				$row->{CONTIG}->[0] = $3."|".$4;
			} else {
				$row->{CONTIG}->[0] = $1;
			}
		}
		if (defined($ftr->{FUNCTION})) {
			my $output = ModelSEED::MS::Utilities::GlobalFunctions::functionToRoles($ftr->{FUNCTION});
			$row->{COMPARTMENT} = $output->{compartments};
			$row->{COMMENT}->[0] = $output->{comment};
			$row->{DELIMITER}->[0] = $output->{delimiter};
			$row->{ROLES} = $output->{roles};
		}
		if (defined($ftr->{SEQUENCE})) {
			$row->{SEQUENCE}->[0] = $ftr->{SEQUENCE};
		}
		$data->{features}->[$i] = $row;
	}
	return $data;
}

sub _getGenomeAttributes {
	my ($self,$id, $source) = @_;
    my ($data, $attributes);
    $source = $self->genomeSource($id) unless defined $source;
    if( $source eq 'PUBSEED') {
        $data = $self->sapsvr()->genome_data({
            -ids => [$id],
            -data => [qw(gc-content dna-size name taxonomy)]
        });
        if(defined($data->{$id})) {
            $attributes = {
                name => $data->{$id}->[2],
                taxonomy => $data->{$id}->[3],
                size => $data->{$id}->[1],
                gc => $data->{$id}->[0],
            };
        }
    } elsif($source eq "KBase") {
        $data = $self->kbsvr->get_entity_Genome([$id],
            [qw(scientific_name source_id dna_size gc_content)]
        );
        if(defined($data->{$id})) {
            $attributes = {
                name     => $data->{$id}->{scientific_name},
                taxonomy => $data->{$id}->{source_id},
                size     => $data->{$id}->{dna_size},
                gc       => $data->{$id}->{gc_content},
            };
        }
    } elsif(defined($self->auth) && $self->auth->isa("ModelSEED::Auth::Basic")) {
        $data = $self->msseedsvr->genomeData({
            ids      => [ $id ],
            username => $self->auth->username,
            password => $self->auth->password,
        });
        $data->{$id} = $self->_parseRASTFeatures($data->{$id});
        $attributes = $data->{$id};
    }
    return $attributes;
}

# Builders
sub _build_sapsvr { return ModelSEED::Client::SAP->new(); }
sub _build_kbsvr { return Bio::KBase::CDMI::Client->new("http://bio-data-1.mcs.anl.gov/services/cdmi_api") };
sub _build_msseedsvr { return ModelSEED::Client::MSSeedSupport->new(); }
sub _build_auth { return ModelSEED::Auth::Factory->new->from_config; }

__PACKAGE__->meta->make_immutable;
1;
