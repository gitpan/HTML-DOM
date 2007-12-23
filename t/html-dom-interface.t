#!/usr/bin/perl -T

# This checks to make sure the module is actually  there  and  that
# %HTML::DOM::Interface has something in it.  It also makes sure  that
# changes made since its introduction are not undone. Is there any way to
# test this  fully  without  simply  copying  the  entire  hash  into  this
# test file?

use strict; use warnings;

use Test::More tests => 32;


# -------------------------#
# Test 1: load the module

BEGIN { use_ok 'HTML::DOM::Interface'; }

# -------------------------#
# Test 2: is the hash there (and does it have somthing in it?)

ok(%HTML::DOM::Interface);

# -------------------------#
# Tests 3-6: changes made in 0.009

ok !exists $HTML::DOM::Interface{Document}, '{Document} doesn\'t exist';
ok exists $HTML::DOM::Interface{HTMLDocument}{createComment},
	"{HTMLDocument}{createComment} exists";
is $HTML::DOM::Interface{HTMLDocument}{_isa}, "Node",
	'HTMLDocument isa Node';
is $HTML::DOM::Interface{'HTML::DOM::Collection::Options'},
	'HTMLCollection', 'HTML::DOM::Collection::Options is there';

# -------------------------#
# Test 7-32: changes made in 0.010

is $HTML::DOM::Interface{'HTML::DOM::TreeBuilder'},
	'HTMLElement', 'HTML::DOM::TreeBuilder';
ok exists $HTML::DOM::Interface{$_}, $_ for map "HTML::DOM::Element::$_",
	qw/ Table Caption TableColumn TableSection TR TableCell
	    FrameSet Frame IFrame /;
ok exists $HTML::DOM::Interface{HTMLFormElement}{reset},
	'form reset';

# DOM 2 core stuff
{
	my $constants = join ' ', '',
		@{ $HTML::DOM::Interface{DOMException}{_constants} }, '';
	like $constants, qr/ HTML::DOM::Exception::$_ /, $_,
		for qw/ INVALID_STATE_ERR SYNTAX_ERR
		       INVALID_MODIFICATION_ERR NAMESPACE_ERR
		     INVALID_ACCESS_ERR /;
}
ok exists $HTML::DOM::Interface{Attr}{ownerElement}, 'Attr->ownerElement';
ok exists $HTML::DOM::Interface{HTMLDocument}{importNode},
	'Document->importNode';
ok exists $HTML::DOM::Interface{Node}{$_}, "Node->$_"
	for qw/ isSupported hasAttributes normalize /;
ok !exists $HTML::DOM::Interface{HTMLElement}{normalize},
	"Element->normalize is gone";
ok exists $HTML::DOM::Interface{HTMLElement}{hasAttribute},
	"Element->hasAttribute";

# DOM 2 view stuff
ok exists $HTML::DOM::Interface{HTMLDocument}{defaultView}, 'defaultView';
ok exists $HTML::DOM::Interface{AbstractView};

# CSS stuff
ok exists $HTML::DOM::Interface{HTMLElement}{style}, 'style';
