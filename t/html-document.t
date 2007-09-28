#!/usr/bin/perl -T

# This script tests the HTMLDocument interface of HTML::DOM.
# For the other features, see document.t and html-dom.t.

use strict; use warnings;

use Test::More tests => 60;


# -------------------------#
# Test 1: load the module

BEGIN { use_ok 'HTML::DOM'; }

# -------------------------#
# Tests 2: constructor

my $doc = new HTML::DOM referrer => 'the other page',
                        url      => 'http://name:pwd@localhost:12345/1234';
isa_ok $doc, 'HTML::DOM';

$doc->write('
	<title>Titlos</title>
	<body id=soma>
		<div><form id=form1><img id=eikona1></form>
		     <div><object id=applet1></object>
		</div>
		<applet id=applet2></applet>
		<form id=form2></form>
		<div><img id=eikona2></div>
		<p>
			<a href="#" name=hahaha id=anchorlink>aoeu</a>
			<map>
				<area alt="" id=link2>
			</map>
			<a name=onethoenh id=anchor2></a>
			<a href="about:blank" id=link3></a>
		</p>
');
$doc->close;

# -------------------------#
# Tests 3-11: simple attributes (not HTMLCollections or cookie)
#     (not including the weird ones [fgColor, et al.]; see below for those)

is    title $doc, 'Titlos', 'title';
is $doc->title('new title'), 'Titlos', 'set title';
is    title $doc, 'new title', 'see whether the title was set';

# These three are read-only:

$doc->referrer(1234); # should be a no-op
is referrer $doc, 'the other page', 'referrer';
$doc-> domain(1234); # should be a no-op
is domain   $doc, 'localhost', 'domain';
$doc-> URL(1234); # should be a no-op
is URL      $doc, 'http://name:pwd@localhost:12345/1234', 'URL';

is body $doc ->id, 'soma',                                'body';
{
	my $new_body = $doc->createElement('body');
	is +(my $body = $doc->body($new_body))->id, 'soma', 'set body';
	is $doc->body, $new_body, 'see whether body was set';
	
	# put the old one back
	$doc->body($body)->delete;
}


# -------------------------#
# Tests 12-21: HTMLCollection attributes

# list context
is_deeply [map id $_, images $doc], ['eikona1','eikona2'], 'images (list)';
is_deeply [map id $_, applets$doc], ['applet1','applet2'],'applets (list)';
is_deeply [map id $_, links $doc], ['anchorlink','link2','link3'],
	'links (list)';
is_deeply [map id $_, forms $doc], ['form1','form2'], 'forms (list)';
is_deeply [map id $_, anchors$doc], ['anchorlink','anchor2'],
	'anchors (list)';

# scalar context
is_deeply [map id $_, @{images $doc}], ['eikona1','eikona2'],
	'images (scalar)';
is_deeply [map id $_, @{applets$doc}], ['applet1','applet2'],
	'applets (scalar)';
is_deeply [map id $_, @{links $doc}], ['anchorlink','link2','link3'],
	'links (scalar)';
is_deeply [map id $_, @{forms $doc}], ['form1','form2'],
	'forms (scalar)';
is_deeply [map id $_, @{anchors$doc}], ['anchorlink','anchor2'],
	'anchors (scalar)';

# ~~~ Perhaps I should save the collection objects, try removing some of
#     these elements, and then see whether the collections automatically
#     updated.

# -------------------------#
# Tests 22-5: URL and referrer with a response object

SKIP: {
	skip 'HTTP::Re(sponse|quest) not installed', 4,
		unless eval{require HTTP::Response; require HTTP::Request};

	(my $response = new HTTP::Response 202)->request(new HTTP::Request
		GET => 'http://localhost:5432/' # pgsql?
		,[Referer => 'about:blank']
			# seems odd that about:blank has a link on it :-)
	);
	my $doc = new HTML::DOM response => $response;

	is URL $doc, 'http://localhost:5432/', 'inferred URL';
	is referrer $doc, 'about:blank', 'inferred referrer';

	# clobber that doc
	$doc = new HTML::DOM	
		response => $response
	,	referrer => 'http://soiiiiiiiihososbmaoeshb/'
	,	url      => 'https://secure.secure.secure/'
	;

	is URL $doc, 'https://secure.secure.secure/',
		'explicit url overrides response object';
	is referrer $doc, 'http://soiiiiiiiihososbmaoeshb/',
		'explicit referrer overrides response object';
}

# -------------------------#
# Tests 26-32: cookies

# Some things here are stolen from LWP's t/base/cookies.t.

my $year_plus_one = (localtime)[5] + 1900 + 1;

# $doc has no cookie jar
is $doc->cookie('PART_NUMBER=ROCKET_LAUNCHER_0001; path=/'), '',
    'set cookies without a cookie jar';
is $doc->cookie(), '',
    'get cookies without a cookie jar'; # and test result of prev statement

SKIP: {
	eval 'require "HTTP/$_.pm" for qw/Cookies Response Request/';
	skip 'HTTP::(Cookies|Re(sponse|quest)) not installed', 5 if $@;

	my $jar = new HTTP::Cookies;

	(my $response = new HTTP::Response 202)->request(new HTTP::Request
		GET => 'http://localhost/'
	);
	my $doc = new HTML::DOM response => $response, cookie_jar=>$jar;

	is $doc->cookie(
		'cookie1=val1; ' .
		'path=/; ' .
		"expires=Wednesday, 09-Nov-$year_plus_one 23:12:40 GMT"
	), '', 'set NS-style cookie';

	is $doc->cookie(
		'cookie2=val2; ' .
		'path=/; ' .
		"expires=Wednesday, 09-Nov-$year_plus_one 23:12:40 GMT"
	), 'cookie1=val1',
	   'set another NS-style cookie';

	is join(';', sort split /;/, $doc->cookie),
		'cookie1=val1;cookie2=val2',
		'get cookies';

	is join(';', sort split /;/, $doc->cookie(
		'cookie3=val3; Version="1"; path="/"; Max-Age=86400'
	)), 'cookie1=val1;cookie2=val2', 'set RFC-???? cookie';
		# can't remember the RFC number and can't be bothered to
		#  look it up

	is join(';', sort split /;/, $doc->cookie),
		'cookie1=val1;cookie2=val2;cookie3=val3',
		'get cookies after added with both syntaxes';


}

# -------------------------#
# Tests 33-46: open, close, unbuffaloed write

# Buffaloed write is tested in html-dom.t together with
# elem_handler with which it is closely tied.

{
	my $response = \'esnopser'; # This isn't a response object, but
	                            # that doesn't matter;
	my $jar = \'raj';
	my $doc = new HTML::DOM url=>'lru', referrer => 'rerrefer',
		response => $response, cookie_jar=>$jar;
	
	is $doc->write('<p id=para></p>'), undef,
		'write (parse/unbuffaloed)';

	is $doc->close, undef, 'close';

	ok!$doc->documentElement->isa('HTML::TreeBuilder'),
		'close calls eof';

	isa_ok $doc->getElementById('para'), 'HTML::DOM::Element',
		'write actually worked like parse!';

	is $doc->open, undef, 'return value of open';

	is $doc->getElementById('p'), undef,
		'seems that open() clobbered everything';
	is $doc->{_HTML_DOM_response}, $response,
		'except the response object';
	is $doc->{_HTML_DOM_jar}, $jar, 'and the cookie jar';
	is $doc->URL, 'lru', 'oh, and the URL, too!';
	is $doc->referrer, 'rerrefer',
		'I nearly forgot--the referrer as well, of course.';
	ok $doc->documentElement->isa('HTML::TreeBuilder'),
		'Ah, I see we have our tree builder back again!';
	is $doc->documentElement->parent, $doc,
		'the HTML elem\'s parent is the document';
		# that one wasn't working in 0.005
	
	# Let's write something, close it, write again, and close again and
	# see whether the first write's HTML code was clobbered.

	$doc->write('<p>aoeus-nthaosenthaosenthu</p>');
	$doc->close;
	$doc->write('<p>This is a new paragraph.</p>');
	$doc->close;
	is $doc->getElementsByTagName('p')->[0]->firstChild->data,
		'This is a new paragraph.',
		'write calls open if it feels the need.';

	eval{$doc->close;};
	is $@, '', 'redudant close() throws no errors';

}

# -------------------------#
# Tests 47-8: ^getElements?By

$doc->write('<p name=para>para 1</p><p name=para>para 2</p><p id=p>3');
$doc->close;

is_deeply [map data{firstChild $_}, getElementsByName $doc 'para'],
	['para 1', 'para 2'],
	'getElementsByName';
is $doc->getElementById('p')->firstChild->data, 3, 'getElementById';

# -------------------------#
# Tests 49-60: weird attributes (fgColor et al.)

$doc->write('<body alink=red background=white.gif bgcolor=white
                   text=black link=blue vlink=fuschia>');
$doc->close;

is $doc->alinkColor('green'), 'red',           'set/get alinkColor';
is $doc->alinkColor,'green',                 , 'get alinkColor';
is $doc->background('black.gif'), 'white.gif', 'set/get background';
is $doc->background,'black.gif',             , 'get background';
is $doc->bgColor   ('black'),         'white', 'set/get bgColor';
is $doc->bgColor   ,'black',                 , 'get bgColor';
is $doc->fgColor   ('white'),         'black', 'set/get fgColor';
is $doc->fgColor   ,'white',                 , 'get fgColor';
is $doc->linkColor ('yellow'),         'blue', 'set/get linkColor';
is $doc->linkColor ,'yellow',                , 'get linkColor';
is $doc->vlinkColor('silver'),      'fuschia', 'set/get vlinkColor';
is $doc->vlinkColor,'silver',                , 'get vlinkColor';


