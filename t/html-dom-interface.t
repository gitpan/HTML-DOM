#!/usr/bin/perl -T

# Right now this simply checks to make sure the module is actually there
# and that %HTML::DOM::Interface has something in it (plus a few things
# to make sure the last update is not undone). I'll make the tests more
# comprehensive later.

use strict; use warnings;

use Test::More tests => 6;


# -------------------------#
# Test 1: load the module

BEGIN { use_ok 'HTML::DOM::Interface'; }

# -------------------------#
# Test 2: is the hash there (and does it have somthing in it?)

ok(%HTML::DOM::Interface);

# -------------------------#
# Tests 3-5: changes made in 0.018

ok !exists $HTML::DOM::Interface{Document}, '{Document} doesn\'t exist';
ok exists $HTML::DOM::Interface{HTMLDocument}{createComment},
	"{HTMLDocument}{createComment} exists";
is $HTML::DOM::Interface{HTMLDocument}{_isa}, "Node",
	'HTMLDocument isa Node';

# -------------------------#
# Test 6: placeholder for more tests (reminder, too)

SKIP:{skip 'not written yet', 1}
