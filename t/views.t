#!/usr/bin/perl -T

use strict; use warnings;
our $tests;
BEGIN { ++$INC{'tests.pm'} }
sub tests'VERSION { $tests += pop };
use Test::More;
plan tests => $tests;

use HTML::DOM;
my $doc = new HTML::DOM;

use tests 2;
isa_ok $doc->defaultView, 'HTML::DOM::View', 'defaultView';
is $doc->defaultView->document, $doc, 'view->document';
