#!/usr/bin/perl -T

# This script tests the DocumentEvent, EventTarget and Event interfaces,
# and also the event-related methods of HTML::DOM and  HTML::DOM::Node.

use strict; use warnings;

use Test::More tests => scalar reverse 47;


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
# Tests 8-12: HTML::DOM::default_event_handler

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
}

# -------------------------#
# Tests 13-17: HTML::DOM::event_attr_handler

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
# Tests 18-25: (add|remove)EventListener and get_event_listeners

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
# Tests 26-41: event initialisation

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
# Tests 42-4: event dispatch:
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
# Tests 45-8: event dispatch:
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
# Tests 49-53: event dispatch: stopPropagation

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
# Tests 54-63: event dispatch:
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
# Tests 64-9: exceptions thrown by dispatchEvent

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
# Tests 70-4: last, but not least: trigger_event

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

