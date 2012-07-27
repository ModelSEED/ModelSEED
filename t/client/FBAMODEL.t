use strict;
use warnings;
use Test::More tests => 2;
use ModelSEED::Client::FBAMODEL;

my $fbamodel = ModelSEED::Client::FBAMODEL->new();
ok defined $fbamodel;
ok $fbamodel->methods > 0;
exit;
