#!/usr/bin/perl -T

# This script tests the HTMLElement interface and most of the interfaces
# that are derived from it.

use strict; use warnings;

use Test::More tests => 140+337;


sub test_attr {
	my ($obj, $attr, $val, $new_val) = @_;
	my $attr_name = (ref($obj) =~ /[^:]+\z/g)[0] . "'s $attr";

	# I get the attribute first before setting it, because at one point
	# I had it setting it to undef with no arg.
	is $obj->$attr,          $val,     "get $attr_name";
	is $obj->$attr($new_val),$val, "set/get $attr_name";
	is $obj->$attr,$new_val,     ,     "get $attr_name again";
}


# -------------------------#
# Test 1: load the module

BEGIN { use_ok 'HTML::DOM'; }

# -------------------------#
# Test 2: document constructor

my $doc = new HTML::DOM;
isa_ok $doc, 'HTML::DOM';

# -------------------------#
# Tests 3-45: Element types that just use the HTMLElement interface

for (qw/ sub sup span bdo tt i b u s strike big small em strong dfn code
         samp kbd var cite acronym abbr dd dt noframes noscript
         address center /) {
	is ref $doc->createElement($_), 'HTML::DOM::Element',
		"class for $_";
}

{
	my $elem = $doc->createElement('sub');
	$elem->attr(id => 'di');
	$elem->attr(title => 'eltit');
	$elem->attr(lang => 'en');
	$elem->attr(dir => 'left');
	$elem->attr(class => 'ssalc');

	test_attr $elem, qw/ id        di    eyeD /;
	test_attr $elem, qw/ title     eltit titulus /;
	test_attr $elem, qw/ lang      en    el /;
	test_attr $elem, qw/ dir       left  right /;
	is $elem->className,'ssalc',               ,     'get className';
	is $elem->className('taxis'),       'ssalc', 'set/get className';
	is $elem->className,'taxis',               , 'get className again';
}

# -------------------------#
# Tests 46-9: HTMLHtmlElement

{
	is ref(
		my $elem = $doc->createElement('html'),
	), 'HTML::DOM::Element::HTML',
		"class for html";
	;
	$elem->attr(version => 'noisrev');

	test_attr $elem, qw/ version noisrev ekdosis /;
}

# -------------------------#
# Tests 50-3: HTMLHeadElement

{
	is ref(
		my $elem = $doc->createElement('head'),
	), 'HTML::DOM::Element::Head',
		"class for head";
	;
	$elem->attr(profile => 'eliforp');

	test_attr $elem, qw/ profile eliforp prolific /;
}

# -------------------------#
# Tests 54-81: HTMLLinkElement

{
	is ref(
		my $elem = $doc->createElement('link'),
	), 'HTML::DOM::Element::Link',
		"class for link";
	;
	$elem->attr(charset  => 'utf-8');
	$elem->attr(href     => '/styles.css');
	$elem->attr(hreflang => 'ru');
	$elem->attr(media    => 'radio');
	$elem->attr(rel      => 'ler');
	$elem->attr(rev      => 'ver');
	$elem->attr(target   => 'tegrat');
	$elem->attr(type     => 'application/pdf');

	ok!$elem->disabled                      ,     'get disabled';
	ok!$elem->disabled       (1),           , 'set/get disabled';
	ok $elem->disabled                      ,     'get disabled again';
	test_attr $elem, qw/ charset  utf-8           utf-32be        /;
	test_attr $elem, qw\ href     /styles.css     /stylesheet.css \;
	test_attr $elem, qw/ hreflang ru              fr              /;
	test_attr $elem, qw\ media    radio           avian-carrier   \;
	test_attr $elem, qw/ rel      ler             lure            /;
	test_attr $elem, qw\ rev      ver             ekd             \;
	test_attr $elem, qw/ target   tegrat          guitar          /;
	test_attr $elem, qw\ type     application/pdf text/richtext   \;
}

# -------------------------#
# Tests 82-5: HTMLTitleElement

{
	is ref(
		my $elem = $doc->createElement('title'),
	), 'HTML::DOM::Element::Title',
		"class for title";
	;

	test_attr $elem, 'text', '', 'tittle';
}

# -------------------------#
# Tests 86-98: HTMLMetaElement

{
	is ref(
		my $elem = $doc->createElement('meta'),
	), 'HTML::DOM::Element::Meta',
		"class for meta";
	;
	$elem->attr( content     => 'text/html; charset=utf-8');
	$elem->attr('http-equiv' => 'Content-Type');
	$elem->attr( name        => 'Fred');
	$elem->attr( scheme      => 'devious');

	test_attr $elem, 'content', 'text/html; charset=utf-8', 'no-cache';
	is $elem->httpEquiv,'Content-Type',          ,     'get httpEquiv';
	is $elem->httpEquiv('Pragma'), 'Content-Type', 'set/get httpEquiv';
	is $elem->httpEquiv,'Pragma',                'get httpEquiv again';
	test_attr $elem, qw` name    Fred             George             `;
	test_attr $elem, qw` scheme  devious          divisive           `;
}

# -------------------------#
# Tests 99-105: HTMLBaseElement

{
	is ref(
		my $elem = $doc->createElement('base'),
	), 'HTML::DOM::Element::Base',
		"class for base";
	;
	$elem->attr(href     => '/styles.css');
	$elem->attr(target   => 'tegrat');

	test_attr $elem, qw~ href   /styles.css /stylesheet.css  ~;
	test_attr $elem, qw~ target tegrat      guitar           ~;
}

# -------------------------#
# Tests 106-11: HTMLIsIndexElement

{
	is ref(
		my $elem = $doc->createElement('isindex'),
	), 'HTML::DOM::Element::IsIndex',
		"class for isindex";
	;
	$elem->attr(prompt     => 'Yayayyayayaayay');

	is $elem->form, undef, 'IsIndex undef form';
	(my $form = $doc->createElement('form'))->appendChild(
		$doc->createElement('div'));
	$form->firstChild->appendChild($elem);
	is $elem->form, $form, 'IsIndex form';

	test_attr $elem, qw @ prompt Yayayyayayaayay     01504           @;
}

# -------------------------#
# Tests 112-21: HTMLStyleElement

{
	is ref(
		my $elem = $doc->createElement('style'),
	), 'HTML::DOM::Element::Style',
		"class for style";
	;
	$elem->attr(media    => 'radio');
	$elem->attr(type     => 'application/pdf');

	ok!$elem->disabled                           ,      'get disabled';
	ok!$elem->disabled       (1),                ,  'set/get disabled';
	ok $elem->disabled                           ,'get disabled again';
	test_attr $elem, qw! media radio           avian-carrier         !;
	test_attr $elem, qw! type  application/pdf text/richtext         !;
}

# -------------------------#
# Tests 122-40: HTMLBodyElement

{
	is ref(
		my $elem = $doc->createElement('body'),
	), 'HTML::DOM::Element::Body',
		"class for body";
	;
	$elem->attr(aLink     => 'red');
	$elem->attr(background=> 'orange');
	$elem->attr(bgColor   => 'yellow');
	$elem->attr(link      => 'green');
	$elem->attr(text      => 'blue');
	$elem->attr(vLink     => 'dingo');

	test_attr $elem, qw 2 aLink      red     kokkino           2;
	test_attr $elem, qw 3 background orange  portokali         3;
	test_attr $elem, qw 4 bgColor    yellow  kitrino           4;
	test_attr $elem, qw 5 link       green   prasino           5;
	test_attr $elem, qw 6 text       blue    mple              6;
	test_attr $elem, qw 7 vLink      dingo   eidos_skylou      7;
}


SKIP: { skip "not written yet", 337 }

