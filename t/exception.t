#!/usr/bin/perl -T

use strict; use warnings;

use Test::More tests => 15;


# -------------------------#
# Test 1: load the module

BEGIN { use_ok 'HTML::DOM::Exception', ':all'; }

# -------------------------#
# Tests 2-11: check constants

{
	my $x;

	for (qw/ INDEX_SIZE_ERR DOMSTRING_SIZE_ERR HIERARCHY_REQUEST_ERR
	        WRONG_DOCUMENT_ERR INVALID_CHARACTER_ERR
	       NO_DATA_ALLOWED_ERR NO_MODIFICATION_ALLOWED_ERR
	     NOT_FOUND_ERR NOT_SUPPORTED_ERR INUSE_ATTRIBUTE_ERR /) {
		eval "is $_, " . ++$x . ", '$_'";
	}
}

# --------------------------------------- #
# Tests 12-15: constructor and overloading #

{
	my $x = new HTML::DOM::Exception NOT_SUPPORTED_ERR,
		'Seems we lack this feature';
	isa_ok $x, 'HTML::DOM::Exception', 'the new exception object';
	is "$x", "Seems we lack this feature\n",
		'string overloading that adds a newline';
	is 0+$x, NOT_SUPPORTED_ERR, 'numeric overloading';
	$x = new HTML::DOM::Exception NOT_SUPPORTED_ERR,
		qq'Another exceptional object\n';
	is $x, "Another exceptional object\n",
	    'string overloading when there is already a trailing newline';
}
