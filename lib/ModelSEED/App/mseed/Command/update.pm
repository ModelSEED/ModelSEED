package ModelSEED::App::mseed::Command::update;

use Try::Tiny;
use Module::Load;

use base 'App::Cmd::Command';

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
    } catch {
        print STDERR "Cannot update your system automatically\n";
        exit;
    };
}

sub nix_update_dev {
    my ($self) = @_;

    # simple update using git pull, could eventually make it smarter
    # no checking for local changes, no notion of branches/remotes

    my $install = $ModelSEED::PackageConfig::INSTALL;
    my $local   = $ModelSEED::PackageConfig::LOCAL;
    my $root    = $ModelSEED::PackageConfig::ROOT;

    if (!defined($local)) {
        $local = '-';
    }

    print "Beginning update...\n";

    my $output = `if [ $local != '-' ]; then
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
         ./Build installdeps --cpan_client "cpanm -n -l $local" 2>&1
     fi
     cd ../MFAToolkit
     git pull 2>&1
     if [ $local = '-' ]; then
         make 2>&1
     else
         INC="-I$local/include -L$local/lib" LD_RUN_PATH=$local/lib make 2>&1
     fi`;

    $ec = $? >> 8;

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

    # check if new tarball is available, if yes, download and unzip
    # then system commands to compile

}

1;
