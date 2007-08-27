#!/usr/bin/perl -T

# This script tests the HTMLElement interface and those interfaces that are
# derived from it.

use strict; use warnings;

use Test::More tests => 107;


# -------------------------#
# Test 1: load the module

BEGIN { use_ok 'HTML::DOM'; }

# -------------------------#
# Test 2: document constructor

my $doc = new HTML::DOM;
isa_ok $doc, 'HTML::DOM';

# -------------------------#
# Tests 3-40: Element types that just use the HTMLElement interface

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

	is $elem->id       ('eyeD'), 'di',           'set/get id';
	is $elem->id       ,'eyeD',                ,     'get id';
	is $elem->title    ('titulus'),     'eltit', 'set/get titl';
	is $elem->title    ,'titulus',             ,     'get titl';
	is $elem->lang     ('el'),             'en', 'set/get lang';
	is $elem->lang     ,'el',                  ,     'get lang';
	is $elem->dir      ('right'),        'left', 'set/get dir';
	is $elem->dir      ,'right',               ,     'get dir';
	is $elem->className('taxis'),       'ssalc', 'set/get className';
	is $elem->className,'taxis',               ,     'get className';
}

# -------------------------#
# Tests 41-3: HTMLHtmlElement

{
	is ref(
		my $elem = $doc->createElement('html'),
	), 'HTML::DOM::Element::HTML',
		"class for html";
	;
	$elem->attr(version => 'noisrev');

	is $elem->version       ('ekdosis'), 'noisrev',  'set/get version';
	is $elem->version       ,'ekdosis',           ,      'get version';
}

# -------------------------#
# Tests 44-6: HTMLHeadElement

{
	is ref(
		my $elem = $doc->createElement('head'),
	), 'HTML::DOM::Element::Head',
		"class for head";
	;
	$elem->attr(profile => 'eliforp');

	is $elem->profile       ('prolific'), 'eliforp', 'set/get profile';
	is $elem->profile       ,'prolific',           ,     'get profile';
}

# -------------------------#
# Tests 47-65: HTMLLinkElement

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

	ok!$elem->disabled       (1),                 , 'set/get disabled';
	ok $elem->disabled                            ,     'get disabled';
	is $elem->charset        ('utf-32be'), 'utf-8', 'set/get charset';
	is $elem->charset        ,'utf-32be',         ,     'get charset';
	is $elem->href  ('/stylesheet.css'), '/styles.css', 'set/get href';
	is $elem->href  ,'/stylesheet.css',               ,     'get href';
	is $elem->hreflang       ('fr'), 'ru', 'set/get hreflang';
	is $elem->hreflang       ,'fr',      ,     'get hreflang';
	is $elem->media('avian-carrier'), 'radio', 'set/get media';
	is $elem->media,'avian-carrier',         ,     'get media';
	is $elem->rel  ('lure'),            'ler', 'set/get rel';
	is $elem->rel  ,'lure',                  ,     'get rel';
	is $elem->rev  ('ekd'),             'ver', 'set/get rev';
	is $elem->rev  ,'ekd',                   ,     'get rev';
	is $elem->target     ('guitar'), 'tegrat', 'set/get target';
	is $elem->target     ,'guitar',          ,     'get target';
	is $elem->type('text/richtext'), 'application/pdf', 'set/get type';
	is $elem->type,'text/richtext',                   ,     'get type';
}

# -------------------------#
# Tests 66-8: HTMLTitleElement

{
	is ref(
		my $elem = $doc->createElement('title'),
	), 'HTML::DOM::Element::Title',
		"class for title";
	;

	is $elem->text       ('tittle'), '', 'set/get text';
	is $elem->text       ,'tittle',    ,     'get text';
}

# -------------------------#
# Tests 69-77: HTMLMetaElement

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

	is $elem->content('no-cache'), 'text/html; charset=utf-8',
		'set/get content';
	is $elem->content,'no-cache',                            ,
		    'get content';
	is $elem->httpEquiv('Pragma'), 'Content-Type', 'set/get httpEquiv';
	is $elem->httpEquiv,'Pragma',                ,     'get httpEquiv';
	is $elem->name     ('George'),         'Fred', 'set/get name';
	is $elem->name     ,'George',                ,     'get name';
	is $elem->scheme   ('divisive'),    'devious', 'set/get scheme';
	is $elem->scheme   ,'divisive',              ,     'get scheme';
}

# -------------------------#
# Tests 78-82: HTMLBaseElement

{
	is ref(
		my $elem = $doc->createElement('base'),
	), 'HTML::DOM::Element::Base',
		"class for base";
	;
	$elem->attr(href     => '/styles.css');
	$elem->attr(target   => 'tegrat');

	is $elem->href  ('/stylesheet.css'), '/styles.css', 'set/get href';
	is $elem->href  ,'/stylesheet.css',               ,     'get href';
	is $elem->target     ('guitar'), 'tegrat', 'set/get target';
	is $elem->target     ,'guitar',          ,     'get target';
}

# -------------------------#
# Tests 83-7: HTMLIsIndexElement

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

	is $elem->prompt    ('01504'), 'Yayayyayayaayay', 'set/get prompt';
	is $elem->prompt    ,'01504',                   ,     'get prompt';
}

# -------------------------#
# Tests 88-94: HTMLStyleElement

{
	is ref(
		my $elem = $doc->createElement('style'),
	), 'HTML::DOM::Element::Style',
		"class for style";
	;
	$elem->attr(media    => 'radio');
	$elem->attr(type     => 'application/pdf');

	ok!$elem->disabled       (1),                 , 'set/get disabled';
	ok $elem->disabled                            ,     'get disabled';
	is $elem->media('avian-carrier'), 'radio', 'set/get media';
	is $elem->media,'avian-carrier',         ,     'get media';
	is $elem->type('text/richtext'), 'application/pdf', 'set/get type';
	is $elem->type,'text/richtext',                   ,     'get type';
}

# -------------------------#
# Tests 95-107: HTMLBodyElement

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

	is $elem->aLink     ('kokkino'),       'red', 'set/get aLink';
	is $elem->aLink     ,'kokkino',             ,     'get aLink';
	is $elem->background('portokali'),  'orange', 'set/get background';
	is $elem->background,'portokali',           ,     'get background';
	is $elem->bgColor   ('kitrino'),    'yellow', 'set/get bgColor';
	is $elem->bgColor   ,'kitrino',             ,     'get bgColor';
	is $elem->link      ('prasino'),     'green', 'set/get link';
	is $elem->link      ,'prasino',             ,     'get link';
	is $elem->text      ('mple'),         'blue', 'set/get text';
	is $elem->text      ,'mple',                ,     'get text';
	is $elem->vLink     ('eidos skylou'),'dingo', 'set/get vLink ';
	is $elem->vLink     ,'eidos skylou',        ,     'get vLink ';
}


