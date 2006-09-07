#!perl -T
# $Id: pod.t 1185 2006-05-26 09:04:17Z rvosa $
use Test::More;
eval "use Test::Pod 1.14";
plan skip_all => "Test::Pod 1.14 required for testing POD" if $@;
all_pod_files_ok();
