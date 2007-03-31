#!perl
# $Id: pod-coverage.t 3438 2007-03-29 16:01:12Z rvosa $
use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage"
  if $@;
all_pod_coverage_ok();
