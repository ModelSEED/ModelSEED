use strict;
use warnings;
use Test::More;

# Ensure a recent version of Test::Pod::Coverage
my $min_tpc = 1.08;
eval "use Test::Pod::Coverage $min_tpc";
plan skip_all => "Test::Pod::Coverage $min_tpc required for testing POD coverage"
    if $@;

# Test::Pod::Coverage doesn't require a minimum Pod::Coverage version,
# but older versions don't recognize some common documentation styles
my $min_pc = 0.18;
eval "use Pod::Coverage $min_pc";
plan skip_all => "Pod::Coverage $min_pc required for testing POD coverage"
    if $@;

my @modules = all_modules();
my @excludes = (
    qr/ModelSEED::App::mseed/,
    qr/ModelSEED::App::stores/,
    qr/ModelSEED::App::bio/,
    qr/ModelSEED::App::model/,
    qr/ModelSEED::App::mapping/,
    qr/ModelSEED::App::genome/,
    qr/ModelSEED::App::import/,
    qr/ModelSEED::MS::DB/,
    qr/Bio::KBase/,
);
@modules = sort @modules;
foreach my $module (@modules) {
    my $next;
    foreach (@excludes) {
        $next = 1 if $module =~ $_;
    }
    next if $next;
    pod_coverage_ok($module, { coverage_class => 'Pod::Coverage::CountParents' } );
}
#all_pod_coverage_ok();
