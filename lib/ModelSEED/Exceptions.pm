########################################################################
# ModelSEED::Exceptions - Object Oriented Exceptions for ModelSEEd
# Authors: Christopher Henry, Scott Devoid, Paul Frybarger
# Contact email: chenry@mcs.anl.gov
# Development location:
#   Mathematics and Computer Science Division, Argonne National Lab;
#   Computation Institute, University of Chicago
#
# Date of module creation: 2012-08-14
########################################################################
package ModelSEED::Exceptions;
use strict;
use warnings;
use Exception::Class (
    'ModelSEED::Exception::CLI' => {
        description => "Base class for exceptions that support cli_error_text",
    },
    'ModelSEED::Exception::Database' => {
        isa => "ModelSEED::Exception::CLI",
        description => "Exception with ModelSEED::Database"
    },
    'ModelSEED::Exception::NoDatabase' => {
        isa => "ModelSEED::Exception::Database",
        description => "When there is no database configuration",
    },
    'ModelSEED::Exception::DatabaseConfigError' => {
        isa => "ModelSEED::Exception::Database",
        description => "For invalid database configuration",
        fields => [qw( configText dbName )],
    }
);
1; 

package ModelSEED::Exception::CLI;
use strict;
use warnings;
sub cli_error_text {
    return "An unknown error occured.";
}
1;
package ModelSEED::Exception::NoDatabase;
use strict;
use warnings;
sub cli_error_text { return <<ND;
Unable to construct a database connection.
Configure a database with the "stores" command
to add a database. For usage, run: 

\$ stores help
ND
}
1;
package ModelSEED::Exception::DatabaseConfigError;
sub cli_error_text {
    my ($self) = @_;
    my $dbName = $self->dbName;
    my $configText = $self->configText;
return <<ND;
Error configuring Database: $dbName
Got invalid configuration:
$configText
Use the "stores" command to reconfigure this database.
ND
}
1;
