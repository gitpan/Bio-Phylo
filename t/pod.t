#!perl
# $Id: pod.t 3439 2007-03-29 16:01:39Z rvosa $
use Test::More;
eval "use Test::Pod 1.14";
plan skip_all => "Test::Pod 1.14 required for testing POD" if $@;
all_pod_files_ok();
