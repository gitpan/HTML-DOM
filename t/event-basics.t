#!/usr/bin/perl -T

# This script tests the DocumentEvent, EventTarget and Event interfaces,
# and also the event-related methods of HTML::DOM and  HTML::DOM::Node.

use strict; use warnings;

use Test::More tests => scalar reverse 601;

# -------------------------#
# Test 1-2: load the modules

BEGIN { use_ok 'HTML::DOM'; }
BEGIN { &use_ok(qw'HTML::DOM::Event :all'); }

# -------------------------#
# Test 3: constructor

my $doc = new HTML::DOM;
isa_ok $doc, 'HTML::DOM';

my $grandchild =
	(my $child = $doc->appendChild($doc->createElement('div')))
	 ->appendChild($doc->createElement('div'));

# -------------------------#
# Tests 4-7: DocumentEvent::createEvent

my $event = $doc->createEvent;
isa_ok $event, 'HTML::DOM::Event';

SKIP :{
	skip 'unimplemented', 3;
	$event = $doc->createEvent('UIEvents');
	isa_ok $event, 'HTML::DOM::Event::UIEvent';
	$event = $doc->createEvent('MouseEvent');
	isa_ok $event, 'HTML::DOM::Event::MouseEvent';
	my $event = $doc->createEvent('MutationEvents');
	isa_ok $event, 'HTML::DOM::Event::MutationEvent';
}

# -------------------------#
# Tests 8-19: HTML::DOM::default_event_handler(_for) accessors

{
	my $coderef = sub{};
	my $coderef2 = sub{};
	is scalar $doc->default_event_handler($coderef), undef,
		'1st assignment to default_event_handler returns undef';
	is $doc->default_event_handler($coderef2), $coderef,
		'2nd assignment to default_event_handler returns old sub';
	is $doc->default_event_handler, $coderef2,
		'2nd assignment did assign the new sub';
	is $doc->default_event_handler, $coderef2,
	    'simply getting the default_event_handler doesn\'t change it';
	$doc->default_event_handler(undef);
	is $doc->default_event_handler, undef,
		'default event handlers can be deleted';

	is scalar $doc->default_event_handler_for('link',$coderef), undef,
		'1st assignment to dehf returns undef';
	is $doc->default_event_handler_for('link',$coderef2), $coderef,
		'2nd assignment to dehf returns old sub';
	is $doc->default_event_handler_for('link'), $coderef2,
		'2nd assignment to dehf did assign the new sub';
	is $doc->default_event_handler_for('link'), $coderef2,
	    'simply getting the dehf doesn\'t change it';
	$doc->default_event_handler_for('link',undef);
	is $doc->default_event_handler('link'), undef,
		'def evt handlers for specific event types can be deleted';

	$doc->default_event_handler_for('link'=>$coderef);
	is $doc->default_event_handler_for('submit', $coderef2), undef,
		'first arg to dehf is not ignored';
	is $doc->default_event_handler_for('submit'), $coderef2,
		'asignement to dffirenet event types works';
}

# -------------------------#
# Tests 20-4: HTML::DOM::event_attr_handler

{
	my $coderef = sub{};
	my $coderef2 = sub{};
	is scalar $doc-> event_attr_handler($coderef), undef,
		'1st assignment to event_attr_handler returns undef';
	is $doc-> event_attr_handler($coderef2), $coderef,
		'2nd assignment to event_attr_handler returns old sub';
	is $doc-> event_attr_handler, $coderef2,
		'2nd assignment did assign the new sub';
	is $doc-> event_attr_handler, $coderef2,
	    'simply getting the event_attr_handler doesn\'t change it';
	$doc-> event_attr_handler(undef);
	is $doc-> event_attr_handler, undef,
		'event attribute handlers can be deleted';
}

# -------------------------#
# Tests 25-32: (add|remove)EventListener and get_event_listeners

{
	my $sub1 = sub{};
	my $sub2 = sub{};
	my $sub3 = sub{};
	my $sub4 = sub{};
	is_deeply[$child->get_event_listeners('click')],[],
		'get_event_listeners initially returns nothing';
	is_deeply[$child->addEventListener(click=>$sub1)],[], 
		'addEventListener returns nothing';
	$child->addEventListener(click=>$sub2);
	is_deeply[sort $child->get_event_listeners('click')],
	         [sort $sub1, $sub2], 'get_event_listeners after adding 2';
	$child->addEventListener(click=>$sub3, 1);
	$child->addEventListener(click=>$sub4, 1);
	is_deeply[sort $child->get_event_listeners('click', 1)],
	         [sort $sub3, $sub4],
		'get_event_listeners (for capture phase) after adding 2';
	is_deeply[$child->removeEventListener(click=>$sub1)],[],
		'removeEventListener does nothing';
	is_deeply[$child->get_event_listeners('click')],
	         [$sub2],
		'get_event_listeners after removing one';
	$child->removeEventListener(click=>$sub3, 1);
	is_deeply[$child->get_event_listeners('click', 1)],
	         [$sub4],
		'get_event_listeners for capture phase after removing one';
	$child->addEventListener(focus => $sub3);
	$child->addEventListener(focus => $sub4);
	$child->addEventListener(focus => $sub2, 1);
	is_deeply[[$child->get_event_listeners('click')],
	          [$child->get_event_listeners('click', 1)],
	          [sort($child->get_event_listeners('focus'))],
	          [$child->get_event_listeners('focus', 1),]],
	         [[$sub2],
	          [$sub4],
	          [sort $sub3, $sub4],
	          [$sub2]],
	         'different slots for different event types and phases';
}

# Let's clean up after ourselves:
clear_event_listeners($child, 'click', 'focus');

# ~~~ maybe I should make this a method of HTML::DOM::Node
sub clear_event_listeners {
	my $target = shift;
	for my $type(@_) {
		$target->removeEventListener($type, $_)
			for $target->get_event_listeners($type);
		$target->removeEventListener($type, $_, 1)
			for $target->get_event_listeners($type, 1);
	}
}

# -------------------------#
# (event accessor method tests are sprinkled throughout the next
#  few sections)

# -------------------------#
# Tests 33-48: event initialisation

is $event->type, undef, 'event type before init';
is $event->eventPhase, undef, 'eventPhase before init';
ok!$event->bubbles, 'event is flat before init';
ok!$event->cancelable, 'event is not cancelable before init';
is scalar $event->currentTarget, undef, 'no currentTarget before init';
is scalar $event->target, undef, 'no target before init';

my $event2;
{
	my $prin = time;
	$event2 = $doc->createEvent;
	my $meta = time;
	my $stamp = timeStamp $event2;
	ok $stamp <= $meta && $stamp >= $prin, 'timeStamp';
}

is_deeply [initEvent $event click => 1, 1], [],
	'initEvent returns nothing';
initEvent $event2 focus => 0, 0;

ok bubbles $event, 'event is bubbly after init';
ok!bubbles $event2, 'event is flat after init';
ok cancelable $event, 'event is cancelable after init';
ok!cancelable $event2, 'event is uncancelable after init';
is scalar $event->currentTarget, undef, 'no currentTarget after init';
is scalar $event->target, undef, 'no target after init';
is $event->eventPhase, undef, 'eventPhase after init';
is $event->type, 'click', 'event type after init';

# -------------------------#
# Tests 49-51: event dispatch:
# First we'll make sure that the events are triggered in the right order,
# and for the right event type.

our $e;

# some of these never get called--or shouldn't, if the module's work-
# ing correctly.
$child->addEventListener(click => sub { $e .= '-cclick1' });
$child->addEventListener(click => sub { $e .= '-cclick2' });
$child->addEventListener(click => sub { $e .= '-cclick1-capture' }, 1);
$child->addEventListener(click => sub { $e .= '-cclick2-capture' }, 1);
$grandchild->addEventListener(click => sub { $e .= '-gcclick1' });
$grandchild->addEventListener(click => sub { $e .= '-gcclick2' });
$grandchild->addEventListener(
	click => sub { $e .= '-gcclick1-capture' }, 1);
$grandchild->addEventListener(
	click => sub { $e .= '-gcclick2-capture' }, 1);
$child->addEventListener(focus => sub { $e .= '-cfocus1' });
$child->addEventListener(focus => sub { $e .= '-cfocus2' });
$child->addEventListener(focus => sub { $e .= '-cfocus1-capture' }, 1);
$child->addEventListener(focus => sub { $e .= '-cfocus2-capture' }, 1);
$grandchild->addEventListener(focus => sub { $e .= '-gcfocus1' });
$grandchild->addEventListener(focus => sub { $e .= '-gcfocus2' });
$grandchild->addEventListener(
	focus => sub { $e .= '-gcfocus1-capture' }, 1);
$grandchild->addEventListener(
	focus => sub { $e .= '-gcfocus2-capture' }, 1);

$e = '';
ok $grandchild->dispatchEvent($event), 'dispatchEvent returns true';
like $e, qr/^-cclick(\d)-capture      # Each pair can be run in any order,
             -cclick(?!\1)\d-capture  # hence the (\d) and (?!\1)\d.
             -gcclick(\d)
             -gcclick(?!\2)\d
             -cclick(\d)
             -cclick(?!\3)\d
         \z/x, 'order of fizzy event dispatch';

$e = '';
$grandchild->dispatchEvent($event2); # This event is not bubbly.
like $e, qr/^-cfocus(\d)-capture      # Each pair can be run in any order,
             -cfocus(?!\1)\d-capture  # hence the (\d) and (?!\1)\d.
             -gcfocus(\d)
             -gcfocus(?!\2)\d
          \z/x, 'order of flat event dispatch';

clear_event_listeners($child, 'click', 'focus');
clear_event_listeners($grandchild, 'click', 'focus');


# -------------------------#
# Tests 52-5: event dispatch:
# Now we need to see whether eventPhase is set correctly.

# Let's just check the constants first:
is CAPTURING_PHASE, 1, 'CAPTURING_PHASE';
is AT_TARGET,       2, 'AT_TARGET';
is BUBBLING_PHASE,  3, 'BUBBLING_PHASE';

($event = $doc->createEvent)->initEvent(click => 1, 1);
$child->addEventListener(click => sub { $e .= $_[0]->eventPhase }, 1);
$child->addEventListener(click => sub { $e .= $_[0]->eventPhase }, 1);
$child->addEventListener(click => sub { $e .= $_[0]->eventPhase });
$child->addEventListener(click => sub { $e .= $_[0]->eventPhase });
$grandchild->addEventListener(click => sub { $e .= $_[0]->eventPhase });
$grandchild->addEventListener(click => sub { $e .= $_[0]->eventPhase });

$e = '';
$grandchild->dispatchEvent($event);
is $e, '112233', 'value of eventPhase during event dispatch';

clear_event_listeners($child, 'click');
clear_event_listeners($grandchild, 'click');


# -------------------------#
# Tests 56-60: event dispatch: stopPropagation

{
	# I put stopPropagation in both listeners for each phase, since
	# they could be called either order and I need to make sure that
	# the other handler at the same level is still called *after* the
	# first one has called stopPropagation.
	$child->addEventListener(click => my $capture1 = sub {
		is scalar $_[0]->stopPropagation, undef,
			'return value of stopPropagation';
		$e .= '-'
	}, 1);
	$child->addEventListener(click => my $capture2 = sub {
		is scalar $_[0]->stopPropagation, undef,
			'return value of stopPropagation';
		$e .= '-'
	}, 1);
	$grandchild->addEventListener(click => my $at_target1 = sub {
		$_[0]->stopPropagation; $e .= '='
	});
	$grandchild->addEventListener(click => my $at_target2 = sub {
		$_[0]->stopPropagation; $e .= '='
	});
	$child->addEventListener(click => my $fzz1 = sub {
		$_[0]->stopPropagation; $e .= '≡'
	});
	$child->addEventListener(click => my $fzz2 = sub {
		$_[0]->stopPropagation; $e .= '≡'
	});
	$doc->addEventListener(click => sub {
		$e = "You didn't expect this, did you?"
	});

	$e = '';
	($event = $doc->createEvent)->initEvent(click => 1, 1);
	$grandchild->dispatchEvent($event);
	is $e, '--', 'stopPropagation at capture phase';

	$child->removeEventListener(click => $_, 1)
		for $capture1, $capture2;

	$e = '';
	($event = $doc->createEvent)->initEvent(click => 1, 1);
	$grandchild->dispatchEvent($event);
	is $e, '==', 'stopPropagation at the target';

	$grandchild->removeEventListener(click => $_)
		for $at_target1, $at_target2;

	$e = '';
	($event = $doc->createEvent)->initEvent(click => 1, 1);
	$grandchild->dispatchEvent($event);
	is $e, '≡≡', 'stopPropagation at the bubbly phase';

}

clear_event_listeners($child, 'click');
clear_event_listeners($grandchild, 'click');
clear_event_listeners($doc, 'click');


# -------------------------#
# Tests 61-70: event dispatch:
#             qw/ target currentTarget preventDefault cancelable /
#    This section also makes sure that event types are indifferent to case.

$child->addEventListener(cLick => sub {
	is $_[0]->currentTarget, $child,
		'currentTarget at capture stage';
	is $_[0]->target, $grandchild,
		'"target" attr during capture phase';
}, 1);
$grandchild->addEventListener(clIck => sub {
	is $_[0]->currentTarget, $grandchild,
		'currentTarget at the target';
	is $_[0]->target, $grandchild,
		'"target" attr at the target';
});
$child->addEventListener(cliCk => sub {
	is scalar $_[0]->preventDefault, undef,
		'return val of preventDefault';
	is $_[0]->currentTarget, $child,
		'currentTarget while bubbles are being blown';
	is $_[0]->target, $grandchild,
		'"target" attr while froth is rising';
});

($event = $doc->createEvent)->initEvent(submit => 0, 0);
 $event                     ->initEvent(click => 1, 1);
# $event is inited twice so we can make sure later that the second call
# to initEvent takes precendence.

ok! $grandchild->dispatchEvent($event),
	'preventDefault makes dispatchEvent return false';

clear_event_listeners($child, 'click');
clear_event_listeners($grandchild, 'click');

$grandchild->addEventListener(click => sub {
	$e = 'did it'; # make sure this handler is actually called
	$_[0]->preventDefault
});
($event = $doc->createEvent)->initEvent(click => 1, 0);
ok $grandchild->dispatchEvent($event),
	'preventDefault has no effect on uncancelable actions';
is $e, 'did it', 'And, yes, preventDefault *was* actually called.';

# -------------------------#
# Tests 71-6: exceptions thrown by dispatchEvent

$event = $doc->createEvent;
eval {
	$child->dispatchEvent($event);
};
isa_ok $@, 'HTML::DOM::Exception',
'$@ (after dispatchEvent with an uninited event)';
cmp_ok $@, '==', HTML::DOM::Exception::UNSPECIFIED_EVENT_TYPE_ERR,
    'dispatchEvent with an uninited event throws the ' .
    'appropriate error';

$event->initEvent(undef, 1, 1);
eval {
	$child->dispatchEvent($event);
};
isa_ok $@, 'HTML::DOM::Exception',
'$@ (after dispatchEvent with no event type)';
cmp_ok $@, '==', HTML::DOM::Exception::UNSPECIFIED_EVENT_TYPE_ERR,
    'dispatchEvent with an no event type throws the ' .
    'appropriate error';

$event->initEvent('' => 1, 1);
eval {
	$child->dispatchEvent($event);
};
isa_ok $@, 'HTML::DOM::Exception',
'$@ (after dispatchEvent with "" for the event type)';
cmp_ok $@, '==', HTML::DOM::Exception::UNSPECIFIED_EVENT_TYPE_ERR,
    'dispatchEvent with "" for the event type throws the ' .
    'appropriate error';




# -------------------------#
# Tests 77-90: trigger_event and default_event_handler(_for)

clear_event_listeners($grandchild, 'click');
$grandchild->addEventListener(click => sub {
	$_[0]->preventDefault
});

$doc-> default_event_handler(sub {
	$e = $_[0];
});

$e = '';
($event = $doc->createEvent)->initEvent(click => 1, 1);
$grandchild->trigger_event($event);
is $e, '', 'event objects passed to trigger_event can be stopped';

$grandchild->trigger_event('click');
is $e, '', 'event names passed to trigger_event can be stopped';

$e = '';
($event = $doc->createEvent)->initEvent(click => 1, 0);
$grandchild->trigger_event($event);
is $e, $event,
    'the default event was run when an obj was passed to trigger_event';

clear_event_listeners($grandchild, 'click');
$e = '';
$grandchild->trigger_event('click');
is $e->type, 'click',
	'$event->type when an event name is passed to trigger_event';
is $e->target, $grandchild,
	'$event->target when an event name is passed to trigger_event';

{
	my $which = '';
	$doc->default_event_handler(sub { $which = 'default' });
	$doc->default_event_handler_for(submit_button =>
		sub { $which = 'sb' }
	);
	$doc->default_event_handler_for(link =>
		sub { $which = 'link' }
	);
	$doc->default_event_handler_for(submit =>
		sub { $which = 'submit' }
	);
	$doc->default_event_handler_for(reset_button =>
		sub { $which = 'resetb' }
	);

	$doc->createElement('a')->click();
	is $which, 'link', 'dehf link';
	$doc->default_event_handler_for('link' => undef);
	$doc->createElement('a')->click();
	is $which, 'default', 'link fallback to default';

	(my $el = $doc->createElement('input'))-> type('submit');
	$el->click();
	is $which, 'sb', 'dehf submit_button';
	$doc->default_event_handler_for('submit_button' => undef);
	$el->click();
	is $which, 'default', 'submit_button fallback to default';

	($el = $doc->createElement('input'))-> type('reset');
	$el->click();
	is $which, 'resetb', 'dehf reset_button';
	$doc->default_event_handler_for('reset_button' => undef);
	$el->click();
	is $which, 'default', 'reset_button fallback to default';

	$doc->createElement('form')->submit();
	is $which, 'submit', 'dehf submit';
	$doc->default_event_handler_for('submit' => undef);
	$doc->createElement('form')->submit();
	is $which, 'default', 'submit fallback to default';
	
	$which = '';
	my $doc = new HTML::DOM;
	$doc->body->appendChild(my $f = $doc->createElement('form'))
		->appendChild($el = $doc->createElement('input'))
		->type('submit');
	$f->addEventListener(submit => sub { $which .= '-form submit'});
	$f->addEventListener(reset => sub { $which .= '-form reset'});
	$el->addEventListener(click => sub { $which .= '-button'});
	$el->click();
	$el->attr(type=>'reset');
	$el->click;
	is $which, '-button-form submit-button-form reset',
		'default default event handler for submit buttons';
}


# -------------------------#
# Tests 91-9: even laster: make sure event_attr_handler is actually used

{
	$doc->close;
	my @__;
	$doc->event_attr_handler(sub {
		push @__, [@_, my $foo = sub { @__ }];
		$foo
	});

	$doc->write('
		<form name=foo onsubmit="die">
			<input Onclick="print q/foo/">
		</form>
	');
	$doc->close;
	
	isa_ok $__[0][0], 'HTML::Element',
		'1st arg to the event attr handler';
	is $__[1][1], 'submit',
		'event name is passed to the event attr handler';
	is $__[1][2], 'die', 'code is passed to the event attr handler';
	is $__[1][3], 27, 'offset is passed ...';
	is $__[0][3], 52, '... to the event attr handler';

	is_deeply [$doc->forms->[0]->get_event_listeners('submit')],
	   [$__[1][4]],
	  'coderef returned by event attr handler becomes an eavesdropper';
	is_deeply [$doc->forms->[0]->elements->[0]
	              ->get_event_listeners('click')],
	          [$__[0][4]],
	          'same when on is spelt On';

	$doc->forms->[0]->setAttribute('onsubmit' => 'live');
	is $__[2][1], 'submit',
		'setAttribute triggers the event attr handler';
	is_deeply [$doc->forms->[0]->get_event_listeners('submit')],
	   [$__[2][-1]],
	  're-assigning to an event attr can replace an existing listener';
}

# -------------------------#
# Tests 101-4: HTML::DOM::error_handler access

{
	my $coderef = sub{};
	my $coderef2 = sub{};
	is scalar $doc-> error_handler($coderef), undef,
		'1st assignment to error_handler returns undef';
	is $doc-> error_handler($coderef2), $coderef,
		'2nd assignment to error_handler returns old sub';
	is $doc-> error_handler, $coderef2,
		'2nd assignment did assign the new sub';
	is $doc-> error_handler, $coderef2,
	    'simply getting the error_handler doesn\'t change it';
	$doc-> error_handler(undef);
	is $doc-> error_handler, undef,
		'error handlers can be deleted';
}

# -------------------------#
# Test 105: use of HTML::DOM::error_handler

{
	my $e;
	my $coderef = sub { $e = $@ };
	$doc->error_handler($coderef);
	$doc->write('');
	$doc->close;
	for($doc->documentElement){
		$_->addEventListener(foo => sub { die "67\n" });
		$_->trigger_event('foo');
	}
	is $e, "67\n", 'error_handler gets called';
}

# -------------------------#
# Test 106: modification of Attr objects for event attributes
#         (bug in 0.012 and earlier)

{
	my $accum;
	my $h = new HTML::DOM;
	$h->event_attr_handler( sub { my $n = $_[2]; sub{$accum .= $n}});
	my $b = $h->body;
	$b->setAttribute("onclick","foo");
	$b->trigger_event("click");
	$b->getAttributeNode("onclick")->value("bar");
	$b->trigger_event("click");
	is $accum, 'foobar',
	  'modification of Attr objects corresponding to event attributes';
}

