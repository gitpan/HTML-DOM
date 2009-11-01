#!/usr/bin/perl -T

# This script tests HTML::DOM features that are not part of the DOM inter-
# faces.

# See html-element.t for css_url_fetcher.

# ~~~ I need a test that makes sure HTML::TreeBuilder doesn’t spit out
#     warnings because of hash deref overloading.

use strict; use warnings; use utf8; use lib 't';

use Test::More tests => 41;


# -------------------------#
# Test 1: load the module

BEGIN { use_ok 'HTML::DOM'; }

# -------------------------#
# Tests 2: constructor

my $doc = new HTML::DOM;
isa_ok $doc, 'HTML::DOM';

# -------------------------#
# Tests 3-21: elem_handler, parse, eof and write

$doc->elem_handler(script => sub {
	eval($_[1]->firstChild->data);
	$@ and die;
});

$doc->write(<<'-----');

<body><p>Para 1
<p>Para 2
<script type='application/x-perl'>
$doc->write('<p>Para ' . ($doc->body->childNodes->length+1))
</script>
<p>Para 4
<p>Para 5
<script type='application/x-perl'>
$doc->write('<p>Para ' . ($doc->body->childNodes->length+1))
</script>
</body>

-----

$doc->close;

{
	no warnings 'deprecated';
	local $[ = 1;
	use warnings 'deprecated';
	my @p_tags = $doc->body->childNodes;
	for(1..6){ 
		is $p_tags[$_]->tagName, 'P',
			"body\'s child node no. $_ is a P elem";
		isa_ok $p_tags[$_]->firstChild, 'HTML::DOM::Text',
			"first child of para $_";
		like $p_tags[$_]->firstChild->data, qr/Para $_\b/,
			"contents of para $_";
	}
}

{
 my $script = $doc->createElement('script');
 $script->appendChild($doc->createTextNode('$doc->title("scred")'));
 $doc->body->appendChild($script);
 is $doc->title, 'scred', "elem_handlers are triggered on node insertion";
}

# -------------------------#
# Tests 22-30: parse_file & charset

use File::Basename;
use File::Spec::Functions 'catfile';

is $doc->charset, undef, 'undefined charset';
ok +($doc = new HTML::DOM) # clobber the existing one
   ->parse_file(catfile(dirname ($0),'test.html')),
	'parse_file returns true';
is $doc->charset, 'utf-8', 'charset';

sub traverse($) {
	my $thing = shift;
	[ map {
		nodeName $_,
		{
			defined(attributes $_)
				? do {
					my $attrs = attributes $_;
					map +($attrs->item($_)->name,
					      $attrs->item($_)->value),
						0..$attrs->length-1;
				}  :()  ,
			$_->isa('HTML::DOM::CharacterData') ?
				(data => data $_)  :()  ,
			hasChildNodes $_ ? (children => &traverse($_))  :()
		}
	} childNodes $thing ]
}

is_deeply traverse $doc, [
  HTML => {
    children => [
      HEAD => {
        children => [
          META => {
            'http-equiv' => 'Content-Type',
             content     => 'text/html; charset=utf-8',
          }
        ],
      },
      BODY => {
        children => [
          P => {
            children => [
              '#text' => {
                data => 'Para 1',
              },
            ],
          },
          P => {
            id => 'aoeu',
            children => [
              '#text' => {
                data => 'Para ',
              },
              B => {
                children => [
                  '#text' => {
                    data => '2',
                  },
                ],
              },
            ],
          },
          P => {
            children => [
              '#text' => {
                data => 'Para ',
              },
              I => {
                children => [
                  '#text' => {
                    data => '3',
                  },
                ],
              },
            ],
          },
          P => {
            children => [
              '#text' => {
                data => 'Para ',
              },
              SPAN => {
                class => 'ssalc',
                children => [
                  '#text' => {
                    data => '4',
                  },
                ],
              },
              '#text' => {
                data => '‼',
              },
              '#text' => {
                data => "\n", # the line break after </html>
              },
            ],
          }
        ],
      },
    ],
  },
], 'parse_file';

ok !(new HTML::DOM)
 ->parse_file(catfile(dirname ($0),'I know this file does not exist.')),
	'parse_file can return false';

($doc = new HTML::DOM charset => 'x-mac-roman') # clobber the existing one
   ->parse_file(catfile(dirname ($0),'test.html'));
like $doc->getElementsByTagName('p')->[-1]->as_text, qr/‚Äº/,
	'parse_file respects existing charset';


$doc = new HTML::DOM charset => 'iso-8859-1';
is $doc->charset, 'iso-8859-1', 'charset in constructor';
is $doc->charset('utf-16be'), 'iso-8859-1', 'charset get/set';
is $doc->charset, 'utf-16be', 'get charset after set';

# -------------------------#
# Test 31: another elem_handler test with nested <script> elems
#          This was causing infinite recursion before version 0.004.

{
	my $counter; my $doc = new HTML::DOM;
	$doc->elem_handler(script => sub {
		++$counter == 3 and die; # avoid infinite recursion
		(my $data = $_[1]->firstChild->data) =~ s/\\\//\//g;
		$doc->write($data);
		$@ and die;
	});

	eval {
	$doc->write(<<'	-----');
		<script>
			<script>stuff<\/script>
		</script>
	-----
	$doc->close;
	};

	is $counter,2,  'nested <script> elems';
}

# -------------------------#
# Test 32: Yet another elem_handler test, this time with '*' for the tag.
#          I broke this in 0.009 and fixed it in 0.010.

{
	my $counter; my $doc = new HTML::DOM;
	$doc->elem_handler('*' => sub {
		++$counter;
	});

	$doc->write('<p><b><i></i></b></p>');

	is $counter,3,  'elem_handler(*)';
}


# -------------------------#
# Tests 33-5: event_parent

{
	my $doc = new HTML::DOM;
	my $thing = bless[];
	is $doc->event_parent, undef, 'event_parent is initially undef';
	is $doc->event_parent($thing), undef,
		'event parent returns undef when setting the first time';;
	is $doc->event_parent, $thing,, 'and setting it actually worked';


}

# -------------------------#
# Tests 36-41: base

{
 my $doc = new HTML::DOM url => 'file:///';
 $doc->close;
 is $doc->base, 'file:///', '->base with no <base>';
 $doc->find('head')->innerHTML('<base href="file:///Volumes/">');
 is $doc->base, 'file:///Volumes/', '->base from <base>';
 $doc->find('base')->getAttributeNode('href'); # autoviv the attr node
 ok !ref $doc->base, 'base returns a plain scalar';

 require HTTP'Response;
 $doc = new HTML::DOM response => new HTTP'Response 200, OK => [
  content_type => 'text/html',
  content_base => 'http://websms.rogers.page.ca/skins/rogers-oct2009/',
 ], '';
 is $doc->base, 'http://websms.rogers.page.ca/skins/rogers-oct2009/',
     'base from response object';

 $doc->innerHTML("<base target=_blank><base href='http://rext/'>");
 is $doc->base, "http://rext/",
  'retval of base when <base target> comes before <base href>';

 "z" =~ /z/;  # (test for weird bug introduced in 0.033 & fixed in 0.034)
 is $doc->base, "http://rext/",
  'base after regexp match that does not match the base';
}
