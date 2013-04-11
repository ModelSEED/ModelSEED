package ModelSEED::App::import::Command::biochemistry;
use strict;
use common::sense;
use ModelSEED::App::import;
use base 'ModelSEED::App::ImportBaseCommand';
use ModelSEED::utilities qw( config error args verbose set_verbose translateArrayOptions);
use File::Temp qw(tempfile);
use IO::Uncompress::Gunzip qw(gunzip $GunzipError);
use LWP::Simple;
use JSON::XS;
use Class::Autouse qw(
    ModelSEED::MS::Biochemistry
    ModelSEED::MS::Factories::TableFileFactory
);

sub abstract { return "Import biochemistry from local or remote database"; }
sub usage_desc { return "ms import biochemistry [biochemistry id] [options]"; }
sub description { return <<END;
Import biochemistry data (compounds, reactions, media, compartments,
etc.) Alias, required, is the name that you would like to save the
biochemistry as.
    
The [--filepath path] argument indicates where flatfiles are for import.
    
--filepath path : import from flatfiles on local computer

END
}
sub options {
    return (
    	["filepath|f:s", "Directory with flatfiles of data you are importing"],
        ["namespace|n:s", "Name space of database (default is 'ModelSEED')"],
	);
}
sub sub_execute {
    my ($self, $opts, $args) = @_;
    # Check that required argument are present
    my $alias = shift(@$args);
    $self->usage_error("Must supply an alias") unless(defined($alias));
    # Make sure the alias object is valid "username/alias_string"
    my $bio;
    if (!defined($opts->{namespace})) {
    	$opts->{namespace} = "ModelSEED";
    }
    if($opts->{filepath}) {
        my $factory = ModelSEED::MS::Factories::TableFileFactory->new({
             filepath => $opts->{filepath},
             namespace => $opts->{namespace},
        });
        $bio = $factory->createBiochemistry({
			name => $alias,
			addAliases => 1,
			addStructuralCues => 1,
			addStructure => 1,
			addPk => 1,
			verbose => $opts->{verbose},
        });
    } else {
        # Just fetch a pre-built biochemistry from the web
        my $url = "http://bioseed.mcs.anl.gov/~chenry/exampleObjects/defaultBiochem.json.gz";
        my $data;
        {
            my ($fh1, $compressed_filename) = tempfile();
            my ($fh2, $uncompressed_filename) = tempfile();
            close($fh1);
            close($fh2);
            verbose("Fetching biochemistry from web...");
            my $status = getstore($url, $compressed_filename);
            # This should probably be >= 200 <= 400? does getstore handle redirects?
            die "Unable to fetch from model_seed\n" unless($status == 200);
            print "Extracting...\n" if($opts->{verbose});
            gunzip $compressed_filename => $uncompressed_filename
                or die "Extract failed: $GunzipError\n";

            my $string;
            {
                local $/;
                open(my $fh, "<", $uncompressed_filename) || die "$!: $@";
                $string = <$fh>;
            }
            $data = JSON::XS->new->utf8->decode($string);
        }
        verbose("Validating fetched biochemistry...");
        $bio = ModelSEED::MS::Biochemistry->new($data);
    }
    verbose("Saved biochemistry to $alias!");
    $self->save_object({
    	object => $bio,
    	type => "Biochemistry",
    	reference => $alias
    });
}

1;
