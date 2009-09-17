#!/usr/bin/perl -T

# This script tests the HTMLDocument interface of HTML::DOM.
# For the other features, see document.t and html-dom.t.

use strict; use warnings; use utf8; use lib 't';

use Test::More tests => 82;


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
# Tests 3-12: simple attributes (not HTMLCollections or cookie)
#     (not including the weird ones [fgColor, et al.]; see below for those)

is    title $doc, 'Titlos', 'title';
is $doc->title('new title'), 'Titlos', 'set title';
is    title $doc, 'new title', 'see whether the title was set';
$doc->find('title')->delete_content;
is title $doc, '', 'title returns "" when the title element is empty';

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
# Tests 13-22: HTMLCollection attributes

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
# Tests 23-6: URL and referrer with a response object

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
# Tests 27-33: cookies

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
# Tests 34-52: open, close, unbuffaloed write(ln)

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
	my($_response, $_jar) = do {
		package HTML::DOM; # we need this to circumvent %{}
		@$doc{map "_HTML_DOM_$_", qw/response jar/}  # overloading
	};
	is $response, $response,
		'except the response object';
	is $jar, $jar, 'and the cookie jar';
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

	my $p_handler = sub { ++ $p's };
	$doc->elem_handler(p => $p_handler);
	$doc->open; # all the way up to 0.009, this would clobber the
	            # element handler
	$doc->write('<p>oenheuo<p>oenuth'); $doc->close;
	is $p's, 2, 'Our clobbered element handler bug is gone';
	
	# Bug in 0.011 (and probably much earlier): close is too good
	# about suppressing errors and eliminates all of them, even when
	# it shouldn’t.
	$doc->open;
	$doc->elem_handler(p => sub { die });
	$doc->write('<p>');
	ok !eval { $doc->close; 1 },
		'close doesn\'t erroneously suppress errors';

	$doc->open;
	$doc->write('<ti','tle>a','b','c','</title>');
	$doc->close;
	is $doc->title, 'abc', 'multi-arg write';
	$doc->writeln("<script>a");
	$doc->writeln("b</script>");
	$doc->close;
	is $doc->find('script')->firstChild->data, "a\nb", 'writeln';
	$doc->writeln("<s","cript>a");
	$doc->writeln("b</script>");
	$doc->close;
	is $doc->find('script')->firstChild->data, "a\nb",
	 'multi-arg writeln';
}

# -------------------------#
# Tests 53-7: ^getElements?By

$doc->write('<p name=para>para 1</p><p name=para>para 2</p><p id=p>3');
$doc->close;

{ package oVerload;
	use overload '""' => sub {${+shift}};
 }

is_deeply [map data{firstChild $_}, getElementsByName $doc 'para'],
	['para 1', 'para 2'],
	'getElementsByName';
is_deeply [map data{firstChild $_}, getElementsByName $doc
                                    bless \do{my $v = 'para'}, 'oVerload'],
	['para 1', 'para 2'],
	'getElementsByName stringfication';
is_deeply [map data{firstChild $_}, @{
               getElementsByName $doc bless \do{my $v = 'para'}, 'oVerload'
          }],
	['para 1', 'para 2'],
	'getElementsByName stringfication in scalar context';
is $doc->getElementById('p')->firstChild->data, 3, 'getElementById';
is $doc->getElementById(bless \do{my $v = 'p'}, 'oVerload')->firstChild
	->data, 3, 'getElementById stringification';

# -------------------------#
# Tests 58-69: weird attributes (fgColor et al.)

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

# -------------------------#
# Tests 70-1: hashness

$doc->write('<form name=fred></form><form name=alcibiades></form>');
$doc->close;

is $doc->{fred}, $doc->forms->[0],           'hashness (1)';
is $doc->{alcibiades}, $doc->forms->[1],     'hashness (2)';

# -------------------------#
# Tests 72-5: innerHTML
{
	my $doc = new HTML::DOM;
	$doc->write('
		<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN"
			"http://www.w3.org/TR/html4/strict.dtd">
		<title></title><p>
		<a href=foo>hello<br>goodbye</a>
	');
	$doc->close;
	ok $doc->innerHTML =~(
		join '\s*', "",
			qw| <!(?i)doctype html public(?-i) |,
			'"-//W3C//DTD HTML 4.01//EN"',
			'"http://www\.w3\.org/TR/html4/strict\.dtd"',
			qw| >
				<html> <head> <title></title> </head>
				<body> <p> <a href=(['"])foo\1
					>hello<br >goodbye</a>
				(?:</p>\s*)?</body> </html>
			|
	), 'innerHTML serialisation'
		or diag ("got " .$doc->innerHTML);

	my $html = $doc->innerHTML;
	is $doc->innerHTML('<title></title><div>foo</div>'),$html,
		'retval of innerHTML with arg';
	is $doc->innerHTML,
	  '<html><head><title></title></head>'
	 ."<body><div>foo</div></body></html>",
	  'result of setting innerHTML';

	$doc->innerHTML("");
	{
		package StringObj;
		use overload '""' => sub { "#mi_down_0" }
	}
	$doc->body->appendChild($doc->createTextNode(bless[],'StringObj'));
	like eval{$doc->innerHTML}, qr/#mi_down_0/,
	 'innerHTML with text nodes made from objs with string overloading'
}

# -------------------------#
# Tests 76-8: location
{
	my $href;
	no warnings 'once';
	*MyLocation::href = sub { $href = $_[1] };
	my $doc = new HTML::DOM;
	is +()=$doc->location, 0, 'location returns nothing at first';
	$doc->set_location_object(my $loc = bless[],MyLocation::);
	is $doc->location, $loc,
		'set_location_object does what its name says';
	$doc->location('fooooooo');
	is $href, 'fooooooo', 'location(arg) forwards to href';
}

# -------------------------#
# Tests 79-82: lastModified
SKIP: {
	my $doc = new HTML::DOM;
	is $doc->lastModified, '',
	 'lastModified when there is no response object';

	skip 'HTTP::Response not installed', 2,
		unless eval{require HTTP::Response};

	$doc = new HTML::DOM response => new HTTP'Response;
	is lastModified $doc, '',
	 'lastModified when response contains no mod time';

	my $response = new HTTP::Response;
	my $time = time;
	my ($s,$m,$h,$d,$mo,$y) = localtime $time;
	$mo += 1; $y += 1900;
	$response->last_modified($time);
	$doc = new HTML::DOM response => $response;
	like $doc->lastModified, qr|^\d\d/\d\d/\d{4,} \d\d:\d\d:\d\d|,
	 'format of lastModified';
	is join("-", map 0+$_, split /\D/, $doc->lastModified),
	   join("-", $d,$mo,$y,$h,$m,$s), "numbers in lastModified retval";
}
