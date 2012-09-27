########################################################################
# ModelSEED::Configuration - This moose object stores data on user env
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location:
#   Mathematics and Computer Science Division, Argonne National Lab;
#   Computation Institute, University of Chicago
#
# Date of module creation: 2012-03-18
########################################################################

=head1 ModelSEED::Configuration 

Simple interface to store configuration info

=head1 DESCRIPTION

This module provides a simple interface to get and store configuration
information for the ModelSEED environment. This information is backed
by a JSON file whose location is defined at object construction.

=head1 METHODS

=head2 new

This initializes a configuration object. The method accepts an optional
filename inside a hashref:

    my $Config = ModelSEED::Configuration->new({filename => 'path/to/file.json'});

If no filename is supplied, the enviornment variable C<MODELSEED_CONFIG>
is checked. If this variable is defined and is a valid path, it is
used.  Otherwise the default is to store configuration at C<.modelseed>
in the current user's C<$HOME> directory. Note that you should probably
use the C<instance> method instead.

=head2 instance

Returns an instance of the C<MODELSEED_CONFIG> object.

=head2 config

Returns a hashref of configuration information. From the perspective
of ModelSEED::Configuration, this hashref is unstructured, and may
contain keys pointing to strings, arrays or other hashrefs.

    my $item = $Config->config->{key};

=head2 user_options

Returns a hashref of options.

=head2 possible_user_options

Returns the default values for the C<user_options> field.

=head2 save

Saves the data to the JSON file. Note that this happens on object
destruction, so it's not absolutely neccesary.

    $Config->save();

=cut

package ModelSEED::Configuration;
use Moose; #X::Singleton;
use namespace::autoclean;
use JSON::XS;
use Try::Tiny;
use Cwd qw(abs_path);
use File::Path qw(mkpath);
use File::Basename qw(dirname);
use autodie;

has filename => (
    is       => 'rw',
    isa      => 'Str',
    builder  => '_buildFilename',
    lazy     => 1,
);

has config => (
    is       => 'rw',
    isa      => 'HashRef',
    builder  => '_buildConfig',
    lazy     => 1,
    init_arg => undef,
);

has JSON => (
    is       => 'ro',
    isa      => 'JSON::XS',
    builder  => '_buildJSON',
    lazy     => 1,
    init_arg => undef
);

sub possible_user_options {
    return {
        ERROR_DIR => $ENV{HOME} . '/.modelseed_error',
        MFATK_CACHE => '/tmp', #Actually, this appears to work fine in windows.
        MFATK_BIN => undef,
        CPLEX_LICENCE => undef
    }
}

sub user_options {
    my ($self) = @_;
    my $options = $self->config->{user_options};
    if(!defined $options) {
        $options = $self->config->{user_options} =
            $self->possible_user_options();
    }
    return $options;
}

sub validate_user_option {
    my ($self, $option, $value) = @_;

    # transform relative path to absolute, if dealing with files/dirs
    if ($option eq "ERROR_DIR"
        || $option eq "MFATK_CACHE"
        || $option eq "MFATK_BIN"
        || $option eq "CPLEX_LICENCE") {
        $value = abs_path($value);
    }

    # should do additional validation on options

    return $value
}

sub _buildConfig {
    my ($self) = @_;
    my $default = {
        user_options => $self->possible_user_options
    };
    if (-f $self->filename) {
        local $/;
        open(my $fh, "<", $self->filename);
        my $text = <$fh>;
        close($fh);
        my $json;
        try {
            $json = $self->JSON->decode($text);
        } catch {
            $json = $default;
        };
        return $json;
    } else {
        return $default;
    }
}

sub _buildJSON {
    return JSON::XS->new->utf8(1)->pretty(1);
}

sub _buildFilename {
    my $filename = $ENV{MODELSEED_CONF};
    $filename  ||= $ENV{HOME} . "/.modelseed";
    mkpath dirname($filename) unless(-d dirname($filename));
    return $filename;
}

sub save {
    my ($self) = @_;
    open(my $fh, ">", $self->filename);
    print $fh $self->JSON->encode($self->config);
    close($fh);
}

# FIXME - kludge until MooseX::Singleton fixed
sub instance {
    my $class = shift @_;
    return $class->new(@_);
}

__PACKAGE__->meta->make_immutable;
1;
