package ModelSEED::App::bio::Command::addmedia;
use base 'App::Cmd::Command';
use Class::Autouse qw(
    ModelSEED::Store
    ModelSEED::Auth::Factory
    ModelSEED::Reference
    ModelSEED::Configuration
    ModelSEED::App::Helpers
    ModelSEED::MS::Factories::ExchangeFormatFactory
);
sub abstract { return "Adds a specified media condition to the database"; }
sub usage_desc { return "bio addmedia [< biochemistry | biochemistry] [name] [compounds] [options]"; }
sub opt_spec {
    return (
        ["verbose|v", "Print verbose status information"],
        ["isdefined","Media is defined"],
        ["isminimal","Media is a minimal media"],
        ["type:s","Type of the media"],
        ["concentrations|c:s", "';' delimited array of concentrations"],
        ["saveas|a:s", "New alias for altered biochemistry"],
        ["file|f:s", "Specify values using files."],
        ["namespace|n:s", "Namespace under which IDs will be added"],
    );
}

sub execute {
    my ($self, $opts, $args) = @_;
    my $auth  = ModelSEED::Auth::Factory->new->from_config;
    my $store = ModelSEED::Store->new(auth => $auth);
    my $helper = ModelSEED::App::Helpers->new();
    my ($biochemistry,my $ref) = $helper->get_object("biochemistry", $args, $store);
    $self->usage_error("Must specify an biochemistry to use") unless(defined($biochemistry));

    if  (!defined $opts->{"file"}) {
        $self->usage_error("Must specify a name for the media") unless(defined($args->[1]));
        $self->usage_error("Must specify compounds in the media") unless(defined($args->[2]));        
        my $data = {
            name => $args->[1],
            compounds => $args->[2]
        };
        foreach my $option (keys(%{$opts})) {
            $data->{$option} = $opts->{$option};
        }
        &addMedia($biochemistry, $data);
    }
    else {
        my ($nameToCpd_ids, $cpd_idsToName) = read_media_cpds("/cygdrive/c/home/workspace/media_cpds.txt");
        my ($fluxSpec, $unknowns) = readExpDesc($opts->{"file"}, $nameToCpd_ids);
        
        # my $mediaSpec = readOut("/cygdrive/c/home/workspace/media.out");        
        # &assertion($fluxSpec, $mediaSpec, $unknowns, $cpd_idsToName);

        $DB::single = 1;
        
        my @complete;
        while (my ($exp, $fluxmap) = each %$fluxSpec) {
            if (exists $fluxmap->{"Complete"}) {
                print STDERR "$exp is Complete\n";
                push @complete, $exp;
                next; # need to be handled when it runs FBA.
            }
            my $data = {
                "name" => $exp,
                "compounds" => join(';', keys $fluxmap),
                "concentrations" => join(';', values $fluxmap),
            };
            foreach my $option (keys %{$opts}) {
                $data->{$option} = $opts->{$option};
            }            
            &addMedia($biochemistry, $data);        
        }        
        print STDERR "The following is compelete media.(STDOUT)\n";
        print join(";", @complete);
    }
    
    if (defined($opts->{saveas})) {
    	$ref = $helper->process_ref_string($opts->{saveas}, "biochemistry", $auth->username);
    	print STDERR "Saving biochemistry with new media as ".$ref."...\n" if($opts->{verbose});
		$store->save_object($ref,$biochemistry);
    } else {
    	print STDERR "Saving over original biochemistry with new media...\n" if($opts->{verbose});
    	$store->save_object($ref,$biochemistry);
    }
}

sub assertion {
    my ($fluxSpec, $mediaSpec, $unknowns, $cpd_idsToName) = @_;
    
    my $sol = {};
    foreach my $exp (keys %$fluxSpec) {                
        if (!exists $mediaSpec->{$exp}){
#            print STDERR "experiment name unmatched for $exp\n";
            next;
        }
        print "-----------For experient $exp\n";
        print "The following is in ours, but not in them.\n";
        foreach my $cpd_id (keys %{$fluxSpec->{$exp}}) {
            if (!exists $mediaSpec->{$exp}->{$cpd_id}) {

                my $str = "$cpd_id\t".join(',', @{$cpd_idsToName->{$cpd_id}});
                print "\t$str","\n";
                $sol->{"ours"}->{$str} = 1;
            }
        }
        print "The following is in them, but not in ours.\n";
        foreach my $cpd_id (keys %{$mediaSpec->{$exp}}) {
            if (!exists $fluxSpec->{$exp}->{$cpd_id}) {
                my $str = "$cpd_id\t ". $mediaSpec->{$exp}->{$cpd_id};
                print "\t$str","\n";
                $sol->{"their"}->{$str} = 1;
            }
        }
        print "These are unknowns:\n";
        foreach my $name (keys %{$unknowns->{$exp}}) {
            $sol->{"unk"}->{$name} = 1;
            print "\t$name\n";
        }    
    }

    foreach (keys %$sol) {
        print "$_\n";
        my @ids = sort keys %{$sol->{$_}};
        foreach (@ids) {
            print "\t$_\n";
        }        
    }
}

sub addMedia {
    my ($biochemistry, $data) = @_;
    my $factory = ModelSEED::MS::Factories::ExchangeFormatFactory->new();
    my $obj = $factory->createFromAPI("Media",$biochemistry,$data);
        my $existingMedia = $biochemistry->queryObject("media",{id => $obj->id()});
    if (defined($existingMedia)) {
        $obj->uuid($existingMedia->uuid());
        $biochemistry->remove("media",$existingMedia);
    }
    $biochemistry->add("media",$obj);            
}

sub readOut {
    my ($out) = @_;

    open(OUT,"<$out");
    # skip fancy headers.
    for (my $i = 0; $i < 3; $i++) {
        scalar <OUT>;
    }
    my $mediaSpec;
    while(<OUT>) {
        chomp;
        my ($blank, $exp, $cpd_id, $name) = split(/\s*\|\s*/);
        if ($exp =~ /(.+)_media$/) {
            $exp = $1;
        }
        else {
            print STDERR "Unexpected experiment name $exp\n";
            next
        }
        
        $mediaSpec->{$exp}->{$cpd_id} = $name;                    
    }
    close(OUT);

    return $mediaSpec;
}


sub read_media_cpds {
    my ($path) = @_;

    open(FILE, "<$path") or die "Cannot open $path: $!\n";
    my $nameToCpd_ids = {};
    my $cpd_idsToName = {}; # for assertion.
    while(<FILE>) {
        chomp;
        my ($name, $cpd_ids) = split(' ');        
        my @cpd_ids = split(',', $cpd_ids);
        push @{$nameToCpd_ids->{$name}}, @cpd_ids;
        foreach my $cpd_id (@cpd_ids) {
            push @{$cpd_idsToName->{$cpd_id}}, $name;
        }
    }            
    close(FILE);
    return $nameToCpd_ids, $cpd_idsToName;
}

sub readExpDesc {
    my ($path, $nameToCpd_ids) = @_;

    open(DESC, "<$path");
    my $fluxSpec = {};
    my $unknowns = {};
    
    my %aeration = (
        assumed_aerobic => 30,
        aerobic => 30,
        assumed_O2_limited => 1,
        O2_limited => 1,
        assumed_anaerobic => 0,
        anaerobic => 0,
        );
    
    # skip header
    scalar <DESC>;
    while(<DESC>) {
        chomp;
        my ($exp, $name, $value, $unit) = split(/\t/);        

        # skip non-compound elements
        if ($unit ne 'mM') {
            if ($name eq "aeration") {
                warn "Unexpected aeration value $value\n" if (!exists $aeration{$value});
                $value = $aeration{$value};
            }
            elsif ($name eq 'yeast_extract') {
                $fluxSpec->{$exp}->{"Complete"} = 1; 
            }
            else {
                next;            
            }
        }
        # "", undef, either case, we don't need them.
        next if ($value eq "" or !defined $value);

        # resume original name
        ($name) = split(' ', $name) if ($name =~ /cpd\d{5}/);

        if (exists $nameToCpd_ids->{$name}) {
            &updateFluxSpec($fluxSpec, $exp, $nameToCpd_ids->{$name}, $value);
        }
        else {
            $unknowns->{$exp}->{$name} = $value;
        }        
    }
    close(DEC);
    return $fluxSpec, $unknowns;
}

sub updateFluxSpec {
    my ($fluxSpec, $exp, $cpd_ids, $value) = @_;

    foreach my $cpd_id (@$cpd_ids) {
        $fluxSpec->{$exp}->{$cpd_id} += $value;
    }
#    @{$fluxSpec->{$exp}}{@$cpd_ids} += ($value) x @$cpd_ids;
}

# my $media = readOut("/cygdrive/c/home/workspace/media.out");
# my $fluxSpec = readExpDesc("/cygdrive/c/Users/Shinnosuke/Downloads/S_oneidensis_v4_Build_2.experiment_feature_descriptions_LF.txt");
# $DB::single = 1;
# print "hello";
1;
