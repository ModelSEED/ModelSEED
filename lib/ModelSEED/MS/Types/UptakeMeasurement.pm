#
# Subtypes for ModelSEED::MS::UptakeMeasurement
#
package ModelSEED::MS::Types::UptakeMeasurement;
use Moose::Util::TypeConstraints;
use Class::Autouse qw ( ModelSEED::MS::DB::UptakeMeasurement );

coerce 'ModelSEED::MS::UptakeMeasurement',
    from 'HashRef',
    via { ModelSEED::MS::DB::UptakeMeasurement->new($_) };
subtype 'ModelSEED::MS::ArrayRefOfUptakeMeasurement',
    as 'ArrayRef[ModelSEED::MS::DB::UptakeMeasurement]';
coerce 'ModelSEED::MS::ArrayRefOfUptakeMeasurement',
    from 'ArrayRef',
    via { [ map { ModelSEED::MS::DB::UptakeMeasurement->new( $_ ) } @{$_} ] };

1;
