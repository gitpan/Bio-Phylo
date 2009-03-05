#!perl
# $Id: pod-coverage.t 838 2009-03-04 20:47:20Z rvos $
use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage"
  if $@;
all_pod_coverage_ok();
