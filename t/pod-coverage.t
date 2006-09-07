#!perl -T
# $Id: pod-coverage.t 1185 2006-05-26 09:04:17Z rvosa $
use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage"
  if $@;
all_pod_coverage_ok();
