#!/usr/bin/perl -T

use strict; use warnings; use lib 't';
our $tests;
BEGIN { ++$INC{'tests.pm'} }
sub tests'VERSION { $tests += pop };
use Test::More;
plan tests => $tests;

use HTML::DOM;
my $doc = new HTML::DOM;

# -------------------------------- #
use tests 17; # ElementCSSInlineStyle

{
	(my $elem = $doc->createElement('div'))
		->setAttribute('style', 'margin-top: 3px');
	isa_ok($elem->style, 'CSS::DOM::Style');
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

	$elem->setAttribute('style' => '');
	$attr = $elem->getAttributeNode('style');
	(my $style = $elem->style)->marginTop('30px');
	is $attr->value, 'margin-top: 30px',
		'changes to the style obj are reflected in the attr node';
	is $elem->style, $style,
		'without the style object getting clobbered';
	$attr->value('color:red');
	is $elem->style->cssText, 'color: red',
		'changes to the attr node are reflected in the style obj';
	$attr->firstChild->data('hand-color:red');
	is $elem->style->cssText, 'hand-color: red',
	   'changes to the attr\'s child text node change the style obj';
	
	$elem->removeAttribute('style');
	$elem->setAttribute('style', 'color:red');
	$attr = $elem->getAttributeNode('style');
	$elem->style->color('blue');
	is $attr->value, 'color: blue',
	   'style mods change the attr when attr was auto-vivved B4 style';
	
	my $new_attr = $doc->createAttribute('style');
	$new_attr->value( "foo:bar");
	$elem->setAttributeNode($new_attr);
	is $elem->style->cssText, 'foo: bar',
		'replacing the attr node clobbers the style obj';

	$elem->removeAttribute('style');
	$elem->setAttribute('style','color:red');
	$attr = $elem->getAttributeNode('style');
	$attr->style # auto-viv
	   ->color('green');
	is $attr->firstChild # auto-viv
	    ->data, 'color: green',
	 "an attr's text node auto-vivved after the style obj is in synch";

	is $elem->getAttribute('style'), 'color: green',
		'style attr nodes stringify properly';
}

# -------------------------------- #
use tests 4; # LinkStyle

{
	(my $elem = $doc->createElement('style'))->appendChild(
		$doc->createTextNode('a { color: black}')
	);
	isa_ok $elem->sheet, 'CSS::DOM', '<style> ->sheet';
	is +($elem->sheet->cssRules)[0]->selectorText, 'a',
		'contents are there';

	$elem = $doc->createElement('link');
	is +()=$elem->sheet, 0, 'sheet can return null';
	$elem->setAttribute('rel' => 'stylesheet');
	isa_ok $elem->sheet, 'CSS::DOM', '<link> ->sheet';
}

# -------------------------------- #
use tests 17; # DocumentStyle

{
	use Scalar::Util 'refaddr';

	my $doc = new HTML::DOM;
	$doc->write('
		<style id=stile>b { font-weight: bold }</style>
		<link id=foo rel=stylesheet>
		<link rel=bar>
	');
	$doc->close;

	isa_ok my $list = $doc->styleSheets, 'CSS::DOM::StyleSheetList',
		'retval of styleSheets';
	is $list->length, 2, 'sheet list doesn\'t include <link rel=bar>';
	is my @list = $doc->styleSheets, 2, 'styleSheets in list context';
	
	is refaddr $list->[0], refaddr $list[0],
		'both retvals have the same first item';
	is refaddr $list->[1], refaddr $list[1],
		'both retvals have the same second item';
	is refaddr $list[0], refaddr $doc->getElementById('stile')->sheet,
		'the style elem\'s sheet is in the list';
	is refaddr $list[1],
	   refaddr +(my $link = $doc->getElementById('foo'))->sheet,
		'the link elem\'s sheet is in the list';


	# $list should update automatically, since it is a reference to the
	# doc’s own style sheet list.
	# @list is static.

	$link->setAttribute(rel => "a nice big\xa0stylesheet\nhere");
	is refaddr $list->[1], refaddr $list[1],
	    'setAttribute w/o changing whether rel contains "stylesheet"';

	$link->setAttribute(rel => 'contents');
	is @$list, 1,
	    'setAttribute(rel => contents) deletes the style sheet obj';

	$link->setAttribute(rel => 'a stylesheet');
	is @$list, 2,
	    'setAttribute adds the style sheet to the list';
	isn't refaddr $list->[1], refaddr $list[1],
	    'creating it from scratch';

	@list = @$list;

	(my $attr = $doc->createAttribute('rel'))->nodeValue('stylesheEt');
	$link->setAttributeNode($attr);
	is refaddr $list[1], refaddr $list->[1],
	    'setAttributeNode w/o changing whether rel =~ "stylesheet"';

	(my $attr2 = $doc->createAttribute('rel'))->nodeValue('contents');
	$link->setAttributeNode($attr2);
	is @$list, 1,
	    'setAttributeNode(contents) deletes the style sheet obj';

	$link->setAttributeNode($attr);
	is @$list, 2,
	    'setAttributeNode adds the style sheet to the list ...';
	isn't refaddr $list->[1], refaddr $list[1],
	    '... creating it from scratch';
	
	$link->removeAttribute('rel');
	is @$list, 1, 'removeAttribute removes the style sheet';

	$link->setAttribute(rel => 'stylesheet');
	$link->removeAttributeNode($link->getAttributeNode('rel'));
	is @$list, 1, 'removeAttributeNode removes the style sheet';
}

