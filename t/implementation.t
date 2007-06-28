#!/usr/bin/perl -T

use strict; use warnings;

use Test::More tests => 10;


# -------------------------#
# Test 1: load the module

BEGIN { use_ok 'HTML::DOM::Implementation'; }
package HTML::DOM::Implementation; our $it; package main; # fake import

# -------------------------#
# Tests 2-10: hasFeature

for (qw/html hTML/) {
	ok $it->hasFeature($_ => '1.0'), qq'hasFeature("$_","1.0")';
	ok!$it->hasFeature($_ => '2.0'), qq'hasFeature("$_","2.0")';
	ok $it->hasFeature($_),          qq'hasFeature("$_")';
}
ok!$it->hasFeature('exeotuht.cg.');
ok!$it->hasFeature('etg.d.h', '1.0');
ok!$it->hasFeature('nuthotgud,gd',haonuhoentuh=>);
