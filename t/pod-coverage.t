#!perl -T
# $Id: pod-coverage.t,v 1.3 2005/07/22 00:46:33 rvosa Exp $
use Test::More;
eval "use Test::Pod::Coverage 1.04";
plan skip_all => "Test::Pod::Coverage 1.04 required for testing POD coverage"
  if $@;
all_pod_coverage_ok();
