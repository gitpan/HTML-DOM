#!/usr/bin/perl -w

use strict; use warnings;
our $tests;
BEGIN { ++$INC{'tests.pm'} }
sub tests'VERSION { $tests += pop };
use Test::More;
plan tests => $tests;

use utf8;
use HTML::DOM;
use Scalar::Util 'weaken';

#use Devel::Cycle;
#use Scalar::Util 'isweak';

# -------------------------#
use tests 4; # Make sure the dust cart comes.

my $doc = new HTML::DOM;
$doc->write('<title>A</title><body>hole<div>bunch<i>o’</i>stuff</div>');
$doc->close;
weaken $doc;
is $doc, undef, 'poof';

$doc = new HTML::DOM;
$doc->write('stuff');
$doc->open;
weaken $doc;
is $doc, undef, 'poof after open';

$doc = new HTML::DOM;
$doc->write('<table></table>');
$doc->close;
(my $table = $doc->getElementsByTagName('table')->[0])->caption(
	$doc->createElement('caption')
);
weaken $table;
undef $doc;
is $table, undef, 'poof after unshift_content (implied by table->caption)';

$doc = new HTML::DOM;
$doc->write('<body>stuff');
$doc->close;
my $body = $doc->body;
weaken $body;
undef $doc;
is $body, undef,
	'poof after splice_content (text nodes are added that way)';



__END__

Copy and paste this stuff for debugging:

find_cycle $doc;
diag 'isweak: ',isweak ${$doc->defaultView};
diag 'isweak: ',isweak $doc->documentElement->{_parent};
