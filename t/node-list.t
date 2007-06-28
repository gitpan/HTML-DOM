#!/usr/bin/perl -T

# This script tests both the NodeList interface and the Perl overload
# interface of both NodeList classes.

use strict; use warnings;

use Test::More tests => 024;


# -------------------------#
# Tests 1-2: load the modules

BEGIN { use_ok 'HTML::DOM::NodeList'; }
BEGIN { use_ok 'HTML::DOM::NodeList::Magic'; }

# -------------------------#
# Tests 3-5: constructors

my (@plain,@magic);

# plain node list (linked to an array)
my $plain = new HTML::DOM::NodeList \@plain;
isa_ok $plain, 'HTML::DOM::NodeList';
# magic node list (caches the list returned by a coderef)
my $magic = new HTML::DOM::NodeList::Magic sub { @magic }; 
isa_ok $magic, 'HTML::DOM::NodeList::Magic';
# Oh look, we have p5.10 roles!
ok DOES $magic 'HTML::DOM::NodeList', 'magic node list does NodeList';

@plain = qw'Te hypermachoi strategoi ta niketeria';
@magic = qw'Hos lytrotheisa ton deinon eucharisteria';

# -------------------------#
# Tests 6-11: access contents

is +(item $plain 2), 'strategoi', 'item';
is +(item $magic 3), 'deinon', 'item (magic)';
is $$plain[2], 'strategoi', 'overloading';
is $$magic[3], 'deinon', 'overloading (magic)';
is $plain->length, 5, 'length';
is $magic->length, 5, 'length (magic)';

# -------------------------#
# Tests 12-19: access contents after modification

splice @plain, 1,1;
splice @magic, 2,1;

is +(item $magic 3), 'deinon', 'item when magic list is stale';
is $magic->length, 5, 'length when magic list is stale';

$magic->_you_are_stale;

is +(item $plain 2), 'ta', 'item after modification';
is +(item $magic 3), 'eucharisteria', 'item after modification (magic)';
is $$plain[2], 'ta', 'overloading after modification';
is $$magic[3], 'eucharisteria', 'overloading after modification (magic)';
is $plain->length, 4, 'length after modification';
is $magic->length, 4, 'length after modification (magic)';

# -------------------------#
# Test 20: magic node list garbage collection

no warnings 'once';
*HTML::DOM::NodeList::Magic::DESTROY = sub { $::bye_bye++ };
bless $magic, ref $magic;
undef $magic;
ok $::bye_bye, 'make sure the dustbin man does his job';


