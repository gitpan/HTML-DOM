#!/usr/bin/perl -T

use strict; use warnings; use lib 't';
our $tests;
BEGIN { ++$INC{'tests.pm'} }
sub tests'VERSION { $tests += pop };
use Test::More;
plan tests => $tests;

use HTML::DOM;
my $doc = new HTML::DOM;

use tests 5;
isa_ok my $view = $doc->defaultView, 'HTML::DOM::View', 'defaultView';
is $doc->defaultView->document, $doc, 'view->document';
is $doc->defaultView->document(\my@x), $doc,'retval of document with arg';
is $view->document, \@x, 'document with arg sets it';

#is
$doc->defaultView("foo"); #, $view,
#	'defaultView with an arg returns the old one';
is $doc->defaultView, 'foo', '  and sets it';
