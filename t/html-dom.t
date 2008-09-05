#!/usr/bin/perl -T

# ~~~ I need a test that makes sure HTML::TreeBuilder doesn’t spit out
#     warnings because of hash deref overloading.

use strict; use warnings; use utf8; use lib 't';

use Test::More tests => 31;


# -------------------------#
# Test 1: load the module

BEGIN { use_ok 'HTML::DOM'; }

# -------------------------#
# Tests 2: constructor

my $doc = new HTML::DOM;
isa_ok $doc, 'HTML::DOM';

# -------------------------#
# Tests 3-20: elem_handler, parse, eof and write

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
	local $[ = 1;
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

# -------------------------#
# Tests 21-9: parse_file & charset

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
                data => ' ', # the line break after </html>
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
# Test 30: another elem_handler test with nested <script> elems
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
# Test 31: Yet another elem_handler test, this time with '*' for the tag.
#          I broke this in 0.009 and fixed it in 0.010.

{
	my $counter; my $doc = new HTML::DOM;
	$doc->elem_handler('*' => sub {
		++$counter;
	});

	$doc->write('<p><b><i></i></b></p>');

	is $counter,3,  'elem_handler(*)';
}
