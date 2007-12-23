#!/usr/bin/perl -T

use strict; use warnings;
our $tests;
BEGIN { ++$INC{'tests.pm'} }
sub tests'VERSION { $tests += pop };
use Test::More;
plan tests => $tests;

use HTML::DOM;
my $doc = new HTML::DOM;

# -------------------------------- #
use tests 9; # ElementCSSInlineStyle

{
	(my $elem = $doc->createElement('div'))
		->setAttribute('style', 'margin-top: 3px');
	isa_ok($elem->style, 'CSS::DOM::StyleDecl');
	is $elem->style->marginTop, '3px',
		'the css dom is copied from the style attribute';
	$elem->style->marginTop('4em');
	is $elem->getAttribute('style'), 'margin-top: 4em',
		'modifications to the css dom are reflected in the attr';
	$elem->setAttribute('style', 'margin-bottom: 2px');
	is $elem->style->marginBottom(), '2px',
		'Subsequent changes to the attr change the dom,';
	is $elem->style->marginTop, '', 'even deleting properties.';

	$elem->removeAttribute('style');
	like $elem->style->cssText, qr/^\s*\z/,
		'removeAttribute erases the css data';

	$elem->style->paddingTop('3in');
	is $elem->getAttributeNode('style')->value, 'padding-top: 3in',
		'getAttributeNode reads the CSS data';
	my $attr = $doc->createAttribute('style');
	$attr->value('padding-top: 4cm');
	$elem->setAttributeNode($attr);
	is $elem->style->paddingTop,'4cm',
		'setAttributeNode sets the CSS data';
		# (Actually, it deletes it, but that’s merely an implemen-
		#  tation detail.)

	$elem->removeAttributeNode($elem->getAttributeNode('style'));
	like $elem->style->cssText, qr/^\s*\z/,
		'removeAttributeNode erases the css data';
}
