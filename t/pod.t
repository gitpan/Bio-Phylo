#!perl -T
# $Id: pod.t,v 1.2 2005/07/22 00:46:33 rvosa Exp $
use Test::More;
eval "use Test::Pod 1.14";
plan skip_all => "Test::Pod 1.14 required for testing POD" if $@;
all_pod_files_ok();
