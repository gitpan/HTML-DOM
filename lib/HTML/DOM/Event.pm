package HTML::DOM::Event;

our $VERSION = '0.015';


use strict;
use warnings;

# Look, TMTOWTDI:
sub	CAPTURING_PHASE  (){             1,}
sub	AT_TARGET             (){ 2,}
	sub BUBBLING_PHASE             (){       3,}	

use Exporter 5.57 'import';

our @EXPORT_OK = qw'
	CAPTURING_PHASE            
	AT_TARGET        
	BUBBLING_PHASE              
';
our %EXPORT_TAGS = (all => \@EXPORT_OK);

sub new {
	bless {time => time}, $_[0];
}

# ----------- ATTRIBUTE METHODS ------------- #
# (all read-only)

sub type          { $_[0]{name      } }
sub target        { $_[0]{target    } }
sub currentTarget { $_[0]{cur_target} }
sub eventPhase    { $_[0]{phase     } }
sub bubbles       { $_[0]{froth     } }
sub cancelable    { $_[0]{cancelable} }
sub timeStamp     { $_[0]{time      } }
sub cancelled     { $_[0]{cancelled } } # non-DOM
sub propagation_stopped { $_[0]{stopped} } # same hear


# ----------- METHOD METHODS ------------- #

sub stopPropagation { $_[0]{stopped  } = !0; return }
sub preventDefault  { $_[0]{cancelled} = !0 if $_[0]->cancelable; return }
#  similar:
sub _set_eventPhase    { $_[0]{phase     } = $_[1] }
sub _set_target        { $_[0]{target    } = $_[1] }
sub _set_currentTarget { $_[0]{cur_target} = $_[1] }

sub initEvent {
	my $event = shift;
	return if defined $event->eventPhase;
	@$event{qw/name froth cancelable/} = @_;
	return
}

# ----------- OTHER STUFF ------------- #

# ~~~ Should I document class_for?

my %class_for = (
	'' => __PACKAGE__,
	#UIEvents => 'HTML::DOM::Event::UIEvent', # not yetimplemnedeteted
	# etc.
);

sub class_for {
	$class_for{$_[0]}
}

1;
__END__


=head1 NAME

HTML::DOM::Event - A Perl class for HTML DOM Event objects

=head1 SYNOPSIS

  use HTML::DOM::Event ':all'; # get constants

  use HTML::DOM;
  $doc=new HTML::DOM;

  $event = $doc->createEvent;
  $event->initEvent(
      'click', # type
       1,      # whether it propagates up the hierarchy
       0,      # whether it can be cancelled
  );

  $doc->body->dispatchEvent($event);

=head1 DESCRIPTION

This class provides event objects for L<HTML::DOM>, which objects are
passed to event handlers when they are triggered. It implements the W3C 
DOM's Event interface and serves as a base class for more specific event
classes (or at least it will, when those are implemented).

=head1 METHODS

=head2 DOM Attributes

These are all read-only and ignore their arguments.

=over

=item type

The type, or name, of the event, without the 'on' prefix that HTML
attributes have; e.g., 'click'.

=item target

This returns the node on which the event occurred. It only works during
event propagation.

=item currentTarget

The returns the node whose handler is currently being called. (The event
might have been triggered on one of its child nodes.) This also works
only during event propagation.

=item eventPhase

Returns one of the constants listed below. This only makes sense during
event propagation.

=item bubbles

This attribute returns a list of C<Bubble> objects, each of which has a
C<diameter> and a C<wobbliness>, which can be retrieved by the
corresponding get_* method. :-)

Actually, this strangely-named method returns true if the event propagates 
up the 
hierarchy after triggering
event handlers on the target.

=item cancelable

Returns true or false.

=item timeStamp

Returns the time at which the event object was created as returned by
Perl's built-in C<time> function.

=back

=head2 Other DOM Methods

=over

=item initEvent ( $name, $propagates_up, $cancelable )

This initialises the event object. C<$propagates_up> is whether the event
should trigger handlers of parent nodes after the target node's handlers
have been triggered. C<$cancelable> determines whether C<preventDefault>
has any effect.

=item stopPropagation

If this is called, no more event handlers will be triggered.

=item preventDefault

If this is called and the event object is cancelable, L<HTML::DOM::Node's 
C<dispatchEvent>
method|HTML::DOM::Node/dispatchEvent> will return false, indicating that
the default action is not to be taken.

=back

=head2 Non-DOM Methods

=over

=item cancelled

Returns true if C<preventDefault> has been called.

=item propagation_stopped

Returns true if C<stopPropagation> has been called.

=back

=head1 EXPORTS

The following node type constants are exportable, individually or with
':all':

=over 4

=item CAPTURING_PHASE (1)

=item AT_TARGET (2)

=item BUBBLING_PHASE (3)

=back

=head1 SEE ALSO

=over 4

L<HTML::DOM>

L<HTML::DOM::Node>
