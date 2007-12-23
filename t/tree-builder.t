#!/usr/bin/perl -T

use strict; use warnings;
our $tests;
BEGIN { ++$INC{'tests.pm'} }
sub tests'VERSION { $tests += pop };
use Test::More;
plan tests => $tests;

use HTML::DOM;

# -------------------------#
use tests 4; # Make sure that HTML::DOM::TreeBuilder’s @ISA is in the
             # right order, and that it isan HTML element.
{
	my $doc = new HTML::DOM;
	$doc->write('<title></title><body>some text</body>');
	# Note that documentElement is still blessed into HTML::DOM::TB.
	is+(my $elem = $doc->documentElement)->as_text, 'some text',
		'HTML::DOM::TreeBuilder->as_text';
	like $elem->as_HTML,qr/^[^~]+\z/,'HTML::DOM::TreeBuilder->as_HTML';
	isa_ok $elem, HTML::DOM::Element::class_for('html');
	can_ok $elem, 'version';
}


# -------------------------#
use tests 1; # implicit tbody
{
	my $doc = new HTML::DOM;
	$doc->write('<table><tr><td>foo</table>');
	is $doc->find('table')->as_HTML,
		'<table><tbody><tr><td>foo</td></tr></tbody></table>
',
		'implicit tbody';
}
