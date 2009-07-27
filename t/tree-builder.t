#!/usr/bin/perl -T

use strict; use warnings; use lib 't';
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

# -------------------------#
use tests 1; # make sure <td><td> doesn’t try to insert an extra <tr>
{            # inside the current <tr>. Version 0.011 broke this, and
             # 0.016 fixed it.
	my $doc = new HTML::DOM;
	$doc->write('<table><tr><td>a<td>b</table>');
	$doc->close;
	is $doc->documentElement->as_HTML,
	   '<html><head></head><body>'
	  ."<table><tbody><tr><td>a</td><td>b</td></tr></tbody></table>"
	  ."</body></html>\n",
		'<td><td>';
}

# -------------------------#
use tests 2; # Make sure comments get parsed and added to the tree as
{            # comment nodes (added in 0.026)
	my $doc = new HTML::DOM;
	$doc->write('<body><!--foo-->');
	$doc->close;
	is $doc->documentElement->as_HTML,
	   '<html><head></head><body>'
	  ."<!--foo-->"
	  ."</body></html>\n",
		'parsing comments';
	isa_ok $doc->body->firstChild, 'HTML::DOM::Comment',
	 'parsed comment';
}
