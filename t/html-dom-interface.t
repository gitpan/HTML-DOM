#!/usr/bin/perl -T

# Right now this simply checks to make sure the module is actually there
# and that %HTML::DOM::Interface has something in it. I'll make the tests
# more comprehensive later.

use strict; use warnings;

use Test::More tests => 3;


# -------------------------#
# Test 1: load the module

BEGIN { use_ok 'HTML::DOM::Interface'; }

# -------------------------#
# Tests 2: is the hash there (and does it have somthing in it?)

ok(%HTML::DOM::Interface);

# -------------------------#
# Tests 3: placeholder for more tests (reminder, too)

SKIP:{skip 'not written yet', 1}