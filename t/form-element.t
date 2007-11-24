#!/usr/bin/perl -T

# This script tests the following DOM interfaces:
#    HTMLFormElement
#    HTMLSelectElement
#    HTMLOptGroupElement
#    HTMLOptionElement
#    HTMLInputElement
#    HTMLTextAreaElement
#    HTMLButtonElement
#    HTMLLabelElement
#    HTMLFieldSetElement
#    HTMLLegendElement

use strict; use warnings;
our $tests;
BEGIN { ++$INC{'tests.pm'} }
sub tests'VERSION { $tests += pop };
use Test::More;
plan tests => $tests;
use Scalar::Util 'refaddr';
use HTML::DOM;

# Each call to test_attr runs 3 tests.
# Each call to test_event runs 2 tests.

sub test_attr {
	my ($obj, $attr, $val, $new_val) = @_;
	my $attr_name = (ref($obj) =~ /[^:]+\z/g)[0] . "'s $attr";

	# I get the attribute first before setting it, because at one point
	# I had it setting it to undef with no arg.
	is $obj->$attr,          $val,     "get $attr_name";
	is $obj->$attr($new_val),$val, "set/get $attr_name";
	is $obj->$attr,$new_val,     ,     "get $attr_name again";
}

my $doc;
{
	my ($evt,$targ);
	($doc = new HTML::DOM)
	 ->default_event_handler(sub{
		($evt,$targ) = ($_[0]->type, shift->target);
	});
	
	sub test_event {
		my($obj, $event) = @_;
		($evt,$targ) = ();
		$obj->$event;
		my $class = (ref($obj) =~ /[^:]+\z/g)[0];
		is $evt, $event, "$class\'s $event method";
		is refaddr $targ, refaddr $obj, 
			"$class\'s $event event is on target"
	}
}
	
my $form;

# -------------------------#
use tests 28; # HTMLFormElement

{
	is ref(
		$form = $doc->createElement('form'),
	), 'HTML::DOM::Element::Form',
		"class for form";
	;
	$form->attr(name => 'Fred');
	$form->attr('accept-charset' => 'utf-8');
	$form->attr(action => 'http:///');
	$form->attr(enctype => '');
	$form->attr(method => 'GET');
	$form->attr(target => 'foo');
	
	test_attr $form, qw/ name Fred George /;
	test_attr $form, qw/ acceptCharset utf-8 iso-8859-1 /;
	test_attr $form, qw/ action http:\/\/\/ http:\/\/remote.host\/ /;
	test_attr $form, enctype=>'',q/application\/x-www-form-urlencoded/;
	test_attr $form, qw/ method GET POST /;
	test_attr $form, qw/ target foo phoo /;

	my $elements = $form->elements;
	isa_ok $elements, 'HTML::DOM::Collection::Elements';

	is $elements->length, 0, '$elements->length eq 0';
	is $form->length, 0, '$form->length eq 0';

	for (1..3) {
		(my $r = $doc->createElement('input'))
			->name('foo');
		$r->type('radio'); 
		$form->appendChild($r);
	}

	is $form->length, 3, '$form->length';
	is $elements->length, 3., '$elements->length';

	test_event $form, 'submit';
	SKIP: { skip 'unimplemented', 2;test_event $form, 'reset';}
}

# -------------------------#
use tests 41; # HTMLSelectElement

# ~~~ I need to write tests that make sure that H:D:NodeList::Magic's
#     STORE and DELETE methods call ->ownerDocument on the detached node.
#     (See the comment in H:D:Node::replaceChild for what it's for.)

{
	is ref(
		my $elem = $doc->createElement('select'),
	), 'HTML::DOM::Element::Select',
		"class for select";
	$elem->appendChild(my $opt1 = $doc->createElement('option'));
	$elem->appendChild(my $opt2 = $doc->createElement('option'));
	
	is $elem->[0], $opt1, 'select ->[]';
	$opt1->attr('selected', 'selected');
	$opt1->attr('value', 'foo');
	$opt2->attr('value', 'bar');
	
	is $elem->type, 'select-one', 'select ->type';
	is $elem->value, 'foo', 'select value';
	test_attr $elem, selectedIndex => 0, 1;
	is $elem->value, 'bar', 'select value again';
	is $elem->length, 2, 'select length';
	
	$form->appendChild($elem);
	is $elem->form ,$form, 'select form';

	my $opts = options $elem;
	isa_ok $opts, 'HTML::DOM::Collection::Options';
	isa_ok tied @$elem, 'HTML::DOM::NodeList::Magic',
		'tied @$select'; # ~~~ later I’d like to change this to
		# check whether @$elem and @$opts are the same array, but
		# since they currently are not (an implementation defici-
		# ency), I can’t do that yet.

	is $opts->[0], $opt1, 'options ->[]';
	$opts->[0] = undef;
	is $opts->[0], $opt2, 'undef assignment to options ->[]';

	ok!$elem->disabled              ,     'select: get disabled';
	ok!$elem->disabled(1),          , 'select: set/get disabled';
	ok $elem->disabled              ,     'select: get disabled again';
	ok!$elem->multiple              ,     'select: get multiple';
	ok!$elem->multiple(1),          , 'select: set/get multiple';
	ok $elem->multiple              ,     'select: get multiple again';
	$elem->name('foo');
	$elem->size(5);
	$elem->tabIndex(3);
	test_attr $elem, qw/ name     foo bar /;
	test_attr $elem, qw/ size     5   1   /;
	test_attr $elem, qw/ tabIndex 3   4   /;

	is $elem->add($opt1, $opt2), undef, 'return value of select add';
	is join('',@$elem), "$opt1$opt2", 'select add';
	$elem->add(my $opt3 = $doc->createElement('option'), undef);

	is $elem->[2], $opt3, 'select add with null 2nd arg';
	$elem->remove(1);
	is $elem->[1], $opt3, 'select remove';

	test_event $elem, 'blur';
	test_event $elem, 'focus';

	$elem->multiple(1);
	is $elem->type, 'select-multiple', 'multiple select ->type';
	$elem->[0]->selected(1);
	$elem->[1]->selected(1);
	is $elem->selectedIndex, 0, 'selectedIndex with multiple';
	$elem->[0]->selected(0);
	is $elem->selectedIndex, 1, 'selectedIndex with multiple (2)';
	$elem->[1]->selected(0);
	is $elem->selectedIndex, -1, 'selectedIndex with multiple (2)';
}

# ~~~ I need a test that makes sure an input element's click method returns
#     an empty list. (This probably applies to all event methods. Maybe I
#     should add it to test_event.)

use tests 337;
SKIP: { skip "not written yet", 337 }


