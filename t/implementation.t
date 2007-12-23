#!/usr/bin/perl -T

use strict; use warnings;

use Test::More tests => 15;


# -------------------------#
# Test 1: load the module

BEGIN { use_ok 'HTML::DOM::Implementation'; }
package HTML::DOM::Implementation; our $it; package main; # fake import

# -------------------------#
# Tests 2-15: hasFeature

for (qw/html hTML/) {
	ok $it->hasFeature($_ => '1.0'), qq'hasFeature("$_","1.0")';
	ok!$it->hasFeature($_ => '2.0'), qq'hasFeature("$_","2.0")';
	ok $it->hasFeature($_),          qq'hasFeature("$_")';
}
ok!$it->hasFeature('exeotuht.cg.');
ok!$it->hasFeature('etg.d.h', '1.0');
ok!$it->hasFeature('nuthotgud,gd',haonuhoentuh=>);

ok$it->hasFeature('core','2.0');
ok$it->hasFeature('views','2.0');

++$INC{'CSS/DOM.pm'};
sub CSS::DOM::hasFeature { join '-', @_ }
is $it->hasFeature('stylesheets','2.0'), 'CSS::DOM-stylesheets-2.0',
	'hasFeature(stylesheets)';
is $it->hasFeature('css','2.0'), 'CSS::DOM-css-2.0',
	'hasFeature(css)';
is $it->hasFeature('css2','2.0'), 'CSS::DOM-css2-2.0',
	'hasFeature(css2)';
