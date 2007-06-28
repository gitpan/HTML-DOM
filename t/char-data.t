#!/usr/bin/perl -T

# This script tests the CharacterData interface. Since objects are never
# blessed into the HTML::DOM::CharacteData class, I am using a comment node
# to test the interface.

use strict; use warnings;

use Test::More tests => 99/3-1;


# -------------------------#
# Test 1: load the module

BEGIN { use_ok 'HTML::DOM'; }

# -------------------------#
# Test 2: constructor

our $c = createComment{new HTML::DOM}'comment contents';
isa_ok $c, 'HTML::DOM::CharacterData';

# -------------------------#
# Tests 3-6: attributes

is data $c, 'comment contents', 'get data';
is $c->data('new contents'), 'comment contents', 'set data';
is $c->data(), 'new contents', 'get data after setting';

is $c->length, 12, 'length';

# -------------------------#
# Tests 7-12: substringData

is $c->substringData(3,4), ' con', 'substringData';
is $c->substringData(3,27866), ' contents',
	'substringData when the length arg is too long';
eval { $c->substringData(-9,39383) };
isa_ok $@, 'HTML::DOM::Exception',
	'$@ (after substringData with a negative offset)';
cmp_ok $@, '==', HTML::DOM::Exception::INDEX_SIZE_ERR,
    'substringData with a negative offset throws a index size error';
eval { $c->substringData(89,39383) };
isa_ok $@, 'HTML::DOM::Exception',
	'$@ (after substringData when offset > length)';
cmp_ok $@, '==', HTML::DOM::Exception::INDEX_SIZE_ERR,
    'substringData throws a index size error when offset > length';

# -------------------------#
# Tests 13-14: appendData

is_deeply [appendData $c '++'],[], 'appendData returns nothing';
is data $c, 'new contents++', 'result of appendData';

# -------------------------#
# Tests 15-20: insertData

is_deeply [insertData $c 0, '++'],[], 'insertData returns nothing';
is data $c, '++new contents++', 'result of insertData';
eval { $c-> insertData(-9,39383) };
isa_ok $@, 'HTML::DOM::Exception',
	'$@ (after insertData with a negative offset)';
cmp_ok $@, '==', HTML::DOM::Exception::INDEX_SIZE_ERR,
    'insertData with a negative offset throws a index size error';
eval { $c-> insertData(89,39383) };
isa_ok $@, 'HTML::DOM::Exception',
	'$@ (after insertData when offset > length)';
cmp_ok $@, '==', HTML::DOM::Exception::INDEX_SIZE_ERR,
    'insertData throws a index size error when offset > length';

# -------------------------#
# Tests 21-6: deleteData

is_deeply [deleteData $c 2, 4],[], 'deleteData returns nothing';
is data $c, '++contents++', 'result of insertData';
eval { $c-> deleteData(-9,39383) };
isa_ok $@, 'HTML::DOM::Exception',
	'$@ (after deleteData with a negative offset)';
cmp_ok $@, '==', HTML::DOM::Exception::INDEX_SIZE_ERR,
    'deleteData with a negative offset throws a index size error';
eval { $c-> deleteData(89,39383) };
isa_ok $@, 'HTML::DOM::Exception',
	'$@ (after deleteData when offset > length)';
cmp_ok $@, '==', HTML::DOM::Exception::INDEX_SIZE_ERR,
    'deleteData throws a index size error when offset > length';

# -------------------------#
# Tests 27-32: replaceData

is_deeply [replaceData $c 2, 1, 'C'],[], 'replaceData returns nothing';
is data $c, '++Contents++', 'result of replaceData';
eval { $c-> replaceData(-9,39383) };
isa_ok $@, 'HTML::DOM::Exception',
	'$@ (after replaceData with a negative offset)';
cmp_ok $@, '==', HTML::DOM::Exception::INDEX_SIZE_ERR,
    'replaceData with a negative offset throws a index size error';
eval { $c-> replaceData(89,39383) };
isa_ok $@, 'HTML::DOM::Exception',
	'$@ (after replaceData when offset > length)';
cmp_ok $@, '==', HTML::DOM::Exception::INDEX_SIZE_ERR,
    'replaceData throws a index size error when offset > length';

diag "TO DO: Write tests for the UTF-16 methods";

