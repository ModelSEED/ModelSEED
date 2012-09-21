package ModelSEED::App::mseed::Command::update;
use strict;
use common::sense;

use Try::Tiny;
use Module::Load;
use LWP::Simple;
use JSON::XS;
use File::Temp qw(tempdir);

use ModelSEED::Version;

use base 'App::Cmd::Command';

my $base_url = "http://blog.theseed.org/downloads/ModelSEED";

sub abstract { "Update the ModelSEED" }
sub usage_desc { "ms update" }

# do we need any opts?
sub opt_spec {
    return ();
}

sub execute {
    my ($self, $opts, $args) = @_;

    try {
        load ModelSEED::PackageConfig;
    } catch {
        print STDERR "Cannot update your system automatically\n";
        exit;
    };

    if ($ModelSEED::PackageConfig::DIST_OS eq '*nix') {
        my $dist_type = $ModelSEED::PackageConfig::DIST_TYPE;
        if ($dist_type eq 'dev') {
            $self->nix_update_dev();
        } elsif ($dist_type eq 'user') {
            $self->nix_update_user();
        } else {
            print STDERR "Unknown distribution type: $dist_type\n";
            exit;
        }
    } else {
        print STDERR "Sorry, your os is not supported\n";
        exit;
    }
}

# developer update, use shell to run git pull on ModelSEED and MFAToolkit
# also installs perl dependencies
#
# should have flags in PackageConfig for ModelSEED and MFAToolkit directories, instead of just install
# that way we can move/rename those dirs. Also should have 'ms move' command which moves these dirs and
# changes config info in PackageConfig and the modelseed.env source script
sub nix_update_dev {
    my ($self) = @_;

    # simple update using git pull, could eventually make it smarter
    # no checking for local changes, no notion of branches/remotes

    my $install = $ModelSEED::PackageConfig::INSTALL;
    my $local   = $ModelSEED::PackageConfig::LOCAL;
    my $root    = $ModelSEED::PackageConfig::ROOT;

    if (!defined($local)) {
        if ($root) {
            $local = '-';
        } else {
            $local = $ENV{HOME} . "/local";
        }
    }

    print "Beginning update...\n";

    # should do checking for MS and MFA directories in perl, warn if not there.

    my $output =
    `if [ $local != '-' ]; then
         export PATH=$local/bin:\$PATH
         export PERL5LIB=$local/lib/perl5:\$PERL5LIB
     fi
     if [ ! -d $install ]; then
         echo "could not find directory where ModelSEED was originally installed"
         exit 2
     fi
     cd $install
     if [ ! -d ModelSEED ]; then
         echo "could not find ModelSEED directory within '$install'"
         exit 2
     fi
     if [ ! -d MFAToolkit ]; then
         echo "could not find MFAToolkit directory within '$install'"
         exit 2
     fi
     cd ModelSEED
     git pull 2>&1
     if [ -f 'Build' ]; then
         ./Build realclean 2>&1
     fi
     perl Build.PL 2>&1
     if [ $local = '-' ]; then
         ./Build installdeps --cpan_client "cpanm -n" 2>&1
     else
         ./Build installdeps --cpan_client "$local/bin/cpanm -n -l $local" 2>&1
     fi
     cd ../MFAToolkit
     git pull 2>&1
     if [ $local = '-' ]; then
         make 2>&1
     else
         INC="-I$local/include -L$local/lib" LD_RUN_PATH=$local/lib make 2>&1
     fi`;

    my $ec = $? >> 8;

    if ($ec != 0) {
        print "Error, update failed: $ec\n";
        print "\n$output\n";
        exit
    }

    print "Finished!\n";
    exit;
}

sub nix_update_user {
    my ($self) = @_;

    # check if new tarball is available, if yes, download and uncompress
    # then system commands to compile
    my $url = $base_url . "/ModelSEED.json";
    my $json = get $url;
    unless (defined($json)) {
        print STDERR "Couldn't find json version file.\n";
        exit;
    }

    my $versions = decode_json($json);
    if ($ModelSEED::Version::VERSION eq $versions->{current}) {
        print "Already up-to-date.\n";
        exit;
    }

    # search through versions for any special flags
    my $fresh = 0;
    my $ver = $ModelSEED::Version::VERSION;
    while ($ver ne $versions->{current}) {
        unless (defined($versions->{$ver}) && defined($versions->{$ver}->{next})) {
            print STDERR "Error with version file!\n";
            exit;
        }

        if (defined($versions->{$ver}->{fresh}) && $versions->{$ver}->{fresh}) {
            $fresh = 1;
        }

        $ver = $versions->{$ver}->{next};
    }

    # download ModelSEED and MFAToolkit tarballs
    my $tmp = tempdir();
    # remove
    print "$tmp\n";
    # end remove
    my $ms_tgz = "ModelSEED_v" . $ver . ".tgz";
    my $mfa_tgz = "MFAToolkit_v" . $ver . ".tgz";
    getstore($base_url . "/" . $ms_tgz, $tmp . "/" . $ms_tgz);
    unless (-e "$tmp/$ms_tgz") {
        print STDERR "Error, could not download '$ms_tgz'\n";
        exit;
    }
    getstore($base_url . "/" . $mfa_tgz, $tmp . "/" . $mfa_tgz);
    unless (-e "$tmp/$mfa_tgz") {
        print STDERR "Error, could not download '$mfa_tgz'\n";
        exit;
    }

    # everything ok, now do the installs
    my $install = $ModelSEED::PackageConfig::INSTALL;
    my $local   = $ModelSEED::PackageConfig::LOCAL;
    my $root    = $ModelSEED::PackageConfig::ROOT;

    if (!defined($local)) {
        if ($root) {
            $local = '-';
        } else {
            $local = $ENV{HOME} . "/local";
        }
    }

    my $output =
    `if [ $local != '-' ]; then
         export PATH=$local/bin:\$PATH
         export PERL5LIB=$local/lib/perl5:\$PERL5LIB
     fi
     cd $tmp
     tar -xzf $ms_tgz
     cd ModelSEED
     perl Build.PL 2>&1
     if [ $local = '-' ]; then
         ./Build installdeps --cpan_client "cpanm -n" 2>&1
         if [ -d /usr/local/bin ]; then
             ./Build install --install_path script=/usr/local/bin 2>&1
         else
             ./Build install --install_path script=/usr/bin 2>&1
         fi
     else
         ./Build installdeps --cpan_client "$local/bin/cpanm -n -l $local" 2>&1
         ./Build install --install_base $local 2>&1
     fi

     cd ..
     tar -xzf $mfa_tgz
     cd MFAToolkit
     if [ $local = '-' ]; then
         make 2>&1
         make deploy-mfatoolkit 2>&1
     else
         INC="-I$local/include -L$local/lib" LD_RUN_PATH=$local/lib make 2>&1
         TARGET=$local make deploy-mfatoolkit 2>&1
     fi`;

    my $ec = $? >> 8;

    if ($ec != 0) {
        print "Error, update failed: $ec\n";
        print "\n$output\n";
        exit
    }
}

1;
