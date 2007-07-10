package HTML::DOM::Node;

our $VERSION = '0.002';


use strict;
use warnings;

use constant {
	ELEMENT_NODE                => 1,
	ATTRIBUTE_NODE              => 2,
	TEXT_NODE                   => 3,
	CDATA_SECTION_NODE          => 4,
	ENTITY_REFERENCE_NODE       => 5,
	ENTITY_NODE                 => 6,
	PROCESSING_INSTRUCTION_NODE => 7,
	COMMENT_NODE                => 8,
	DOCUMENT_NODE               => 9,
	DOCUMENT_TYPE_NODE          => 10,
	DOCUMENT_FRAGMENT_NODE      => 11,
	NOTATION_NODE               => 12,
};

use Carp 'croak';
use Exporter 'import';
use HTML::DOM::Event;
use HTML::DOM::Exception qw'NO_MODIFICATION_ALLOWED_ERR NOT_FOUND_ERR
                               HIERARCHY_REQUEST_ERR WRONG_DOCUMENT_ERR
                                 UNSPECIFIED_EVENT_TYPE_ERR';
use Scalar::Util qw'refaddr weaken blessed';

require HTML::DOM::NodeList;
require HTML::Element;

our @ISA = 'HTML::Element'; # No, a node isn't an HTML element, but
                            # HTML::Element has some nice tree-handling
                            # methods (and, after all, TreeBuilder's
                            # pseudo-elements aren't elements either).

our @EXPORT_OK = qw'
	ELEMENT_NODE               
	ATTRIBUTE_NODE             
	TEXT_NODE                  
	CDATA_SECTION_NODE         
	ENTITY_REFERENCE_NODE      
	ENTITY_NODE                
	PROCESSING_INSTRUCTION_NODE
	COMMENT_NODE               
	DOCUMENT_NODE              
	DOCUMENT_TYPE_NODE         
	DOCUMENT_FRAGMENT_NODE     
	NOTATION_NODE              
';
our %EXPORT_TAGS = (all => \@EXPORT_OK);



=head1 NAME

HTML::DOM::Node - A Perl class for representing the nodes of an HTML DOM tree

=head1 SYNOPSIS

  use HTML::DOM::Node ':all'; # constants
  use HTML::DOM;
  $doc = HTML::DOM->new;
  $doc->isa('HTML::DOM::Node'); # true
  $doc->nodeType == DOCUMENT_NODE; # true

  $doc->firstChild;
  $doc->childNodes;
  # etc

=head1 DESCRIPTION

This is the base class for all nodes in an HTML::DOM tree. (See
L<HTML::DOM/CLASSES AND DOM INTERFACES>.) It implements the Node and 
EventTarget DOM interfaces.

=head1 METHODS

=head2 Attributes

The following DOM attributes are supported:

=over 4

=item nodeName

=item nodeType

These two are implemented not by HTML::DOM::Node itself, but by its
subclasses.

=item nodeValue

=item parentNode

=item childNodes

=item firstChild

=item lastChild

=item previousSibling

=item nextSibling

=item attributes

=item ownerDocument

=back

There is also a C<_set_ownerDocument> method, which you probably do not
need to know about.

=cut

# ----------- ATTRIBUTE METHODS ------------- #

# sub nodeName {} # every subclass overrides this
# sub nodeType {} # likewise

sub nodeValue {
	if(@_ > 1) {
		die new HTML::DOM::Exception
			NO_MODIFICATION_ALLOWED_ERR,
			'Read-only node';# ~~~ only when the node is
		                                 #     readonly
	}
	return; # empty list
}

sub parentNode {
	my $p = $_[0]->parent;
	defined $p ? $p :()
}

sub childNodes {
	wantarray ? $_[0]->content_list :
		new HTML::DOM::NodeList $_[0]->content_array_ref;
}

sub firstChild {
	($_[0]->content_list)[0];
}

sub lastChild {
	($_[0]->content_list)[-1];
}

sub previousSibling {
	my $sib = scalar $_[0]->left;
	defined $sib ? $sib : ();
}

sub nextSibling {
	my $sib = scalar $_[0]->right;
	defined $sib ? $sib : ();
}

sub attributes {} # null for most nodes; overridden by Element

sub ownerDocument {
	my $self = shift;
	# ~~~ this '||' thing is inefficient. It ought to cache the
	#     ownerDocument (and weaken it) whenever it is not set alreay.
	$$self{_HTML_DOM_Node_owner} || do {
		my $root = $self->root;
		$$root{_HTML_DOM_Node_owner} || $root
	};
}

sub _set_ownerDocument {
	$_[0]{_HTML_DOM_Node_owner} = $_[1];
	weaken $_[0]{_HTML_DOM_Node_owner};
}


=head2 Other Methods

See the DOM spec. for descriptions of most of these.

=over 4

=item insertBefore

=item replaceChild

=item removeChild

=item appendChild

=item hasChildNodes

=item cloneNode

=cut

# ----------- METHOD METHODS ------------- #

sub insertBefore {
	# ~~~ NO_MODIFICATION_ALLOWED_ERR is meant to be raised if the
	#     node is read-only.
	# ~~~ HIERARCHY_REQUEST_ERR is also supposed to be raised if the
	#     node type does not allow children of $new_node's type.

	my($self,$new_node,$before) = @_;

	$self->is_inside($new_node) and
		die new HTML::DOM::Exception HIERARCHY_REQUEST_ERR,
		'A node cannot be inserted into one of its descendants';

	my $doc = $new_node->ownerDocument; # not $self->... because $self
	                                    # might be the document, in
	                                    # which case its owner is null.
	$doc == $self || $doc == $self->ownerDocument or
		die new HTML::DOM::Exception WRONG_DOCUMENT_ERR,
		'The node to be inserted belongs to another document';

	my $index;
	my @kids = $self->content_list;
	if($before) { FIND_INDEX: {
		for (0..$#kids) {
			$kids[$_] == $before 
				and $index = $_, last FIND_INDEX;
		}
		die new HTML::DOM::Exception NOT_FOUND_ERR,
		'insertBefore\'s 2nd argument is not a child of this node';
	}}
	else {
		$index = @kids;
	}
	$self->splice_content($index, 0,
		$new_node->isa('HTML::DOM::DocumentFragment')
		? $new_node->childNodes
		: $new_node
	);

	$doc->_modified;

	$new_node;
}

sub replaceChild {
	# ~~~ NO_MODIFICATION_ALLOWED_ERR is meant to be raised if the
	#     node is read-only.
	# ~~~ HIERARCHY_REQUEST_ERR is also supposed to be raised if the
	#     node type does not allow children of $new_node's type.

	my($self,$new_node,$old_node) = @_;

	$self->is_inside($new_node) and
		die new HTML::DOM::Exception HIERARCHY_REQUEST_ERR,
		'A node cannot be inserted into one of its descendants';

	my $doc = $new_node->ownerDocument; # not $self->... because $self
	                                    # might be the document, in
	                                    # which case its owner is null.
	$doc == $self || $doc == $self->ownerDocument or
		die new HTML::DOM::Exception WRONG_DOCUMENT_ERR,
		'The node to be inserted belongs to another document';

	no warnings 'uninitialized';
	$self == $old_node->parent or
		die new HTML::DOM::Exception NOT_FOUND_ERR,
		'replaceChild\'s 2nd argument is not a child of this node';

	$doc->_modified;

	$old_node->replace_with(
		$new_node->isa('HTML::DOM::DocumentFragment')
		? $new_node->childNodes
		: $new_node
	);
}

sub removeChild {
	# ~~~ NO_MODIFICATION_ALLOWED_ERR is meant to be raised if the
	#     node is read-only.

	my($self,$child) = @_;

	no warnings 'uninitialized';
	$self == $child->parent or
		die new HTML::DOM::Exception NOT_FOUND_ERR,
		'removeChild\'s argument is not a child of this node';

	$child->detach;

	$self->ownerDocument->_modified;

	$child;
}

sub appendChild {
	# ~~~ NO_MODIFICATION_ALLOWED_ERR is meant to be raised if the
	#     node is read-only.
	# ~~~ HIERARCHY_REQUEST_ERR is also supposed to be raised if the
	#     node type does not allow children of $new_node's type.

	my($self,$new_node) = @_;

	$self->is_inside($new_node) and
		die new HTML::DOM::Exception HIERARCHY_REQUEST_ERR,
		'A node cannot be inserted into one of its descendants';

	my $doc = $new_node->ownerDocument; # not $self->... because $self
	                                    # might be the document, in
	                                    # which case its owner is null.
	$doc == $self || $doc == $self->ownerDocument or
		die new HTML::DOM::Exception WRONG_DOCUMENT_ERR,
		'The node to be inserted belongs to another document';

	$self->push_content($new_node->isa('HTML::DOM::DocumentFragment')
		? $new_node->childNodes
		: $new_node);

	$doc->_modified;

	$new_node;
}

sub hasChildNodes {
	!!$_[0]->content_list
}

sub cloneNode {
	my($self,$deep) = @_;
	if($deep) {
		$self->clone
	}
	else {
		# ~~~ Do I need to reweaken any attributes?
		bless +(my $clone = { %$self }), ref $self;
		$clone->_set_ownerDocument($self->ownerDocument);
		$clone
	}
}

# ----------- EventTarget INTERFACE ------------- #

=item addEventListener($event_name, $listener, $capture)

The C<$listener> should be either a coderef or an object with a
C<handleEvent> method. (HTML::DOM does not implement any such object since
it would just be a wrapper around a coderef anyway, but has support for
them.) An object with C<&{}> overloading will also do.

C<$capture> is a boolean indicating whether this is to be triggered during
the 'capture' phase.

=cut

sub addEventListener {
	my ($self,$name,$listener, $capture) = @_;
	$$self{'_HTML_DOM_' . ('capture_' x !!$capture) . 'events'}
		{lc $name}{refaddr $listener} = $listener;
	return;
}

# Though this only applies to elements, I'm putting it here, since only
# H:D:N is supposed to access _HTML_DOM_events.
sub _add_attr_event { # special secret method that keys the event listener
                      # by the string 'attr', rather than by its refaddr
	my ($self,$name,$listener) = @_;
	$$self{'_HTML_DOM_events'}{lc $name}{attr} = $listener;
	return;
}

=item removeEventListener($event_name, $listener, $capture)

The C<$listener> should be the same reference passed to 
C<addEventListener>.

=cut

sub removeEventListener {
	my ($self,$name,$listener, $capture) = @_;
	$name = lc $name;
	my $key = '_HTML_DOM_' . ('capture_' x !!$capture) . 'events';
	exists $$self{$key} && exists $$self{$key}{$name} &&
		delete $$self{$key}{$name}{refaddr $listener};
	return;
}

=item get_event_listeners($event_name, $capture)

This is not a DOM method (hence the underscores in the name). It returns a
list of all event listeners for the given event name. C<$capture> is a
boolean that indicates which list to return, either 'capture' listeners or
normal ones.

=cut

sub get_event_listeners { # uses underscores because it is not a DOM method
	my($self,$name,$capture) = @_;
	$name = lc $name;
	my $key = '_HTML_DOM_' . ('capture_' x !!$capture) . 'events';
	exists $$self{$key} && exists $$self{$key}{$name}
		? values %{$$self{$key}{$name}}
		: ()
}

=item dispatchEvent($event_object)

$event_object is an object returned by HTML::DOM's C<createEvent> method,
or any object that implements the interface document in 
L<HTML::DOM::Event>.

C<dispatchEvent> does not automatically call the handler passed to the
document's C<default_event_handler>. It is expected that the code that
calls this method will do that (see also L</trigger_event>).

The return value is a boolean indicating whether the default action
should be taken (i.e., whether preventDefault was I<not> called).

=cut

sub dispatchEvent { # This is where all the work is.
	my ($target, $event) = @_;
	my $name = $event->type;

	die HTML::DOM::Exception->new(UNSPECIFIED_EVENT_TYPE_ERR,
		'The type of event has not been specified')
		unless defined $name and length $name;
	
	# Basic event flow is as follows:
	# 1.  The  'capturing'  phase:  Go through the  node's  ancestors,
	#     starting from the top of the tree. For each one, trigger any
	#     capture events it might have.
	# 2.  Trigger events on the $target.
	# 3. 'Bubble-blowing' phase: Trigger events on the target's ances-
	#     tors in reverse order (top last).

	# ~~~ according to DOM2-Events section 1.2.1, exceptions thrown
	# inside an EventListener do not stop propagation of the event. It
	# simply continues processing additional EventListeners as usual.
	# I need some way of dealing with exceptions other than simply
	# ignoring them.

	$event->_set_target($target);

	my @lineage = lineage $target; # $lineage[-1] is the root

	$event->_set_eventPhase(HTML::DOM::Event::CAPTURING_PHASE);
	for (reverse @lineage) { # root first
		$event-> _set_currentTarget($_);
		eval {
			defined blessed $_ && $_->can('handleEvent') ?
				$_->handleEvent($event) : &$_($event)
		} for($_->get_event_listeners($name, 1));
		return !cancelled $event if $event->propagation_stopped;
	}

	$event->_set_eventPhase(HTML::DOM::Event::AT_TARGET);
	$event->_set_currentTarget($target);
	eval {
		defined blessed $_ && $_->can('handleEvent') ?
			$_->handleEvent($event) : &$_($event)
	} for($target->get_event_listeners($name));
	return !cancelled $event if $event->propagation_stopped
	                         or!$event->bubbles;

	$event->_set_eventPhase(HTML::DOM::Event::BUBBLING_PHASE);
	for (@lineage) { # root last
		$event-> _set_currentTarget($_);
		eval {
			defined blessed $_ && $_->can('handleEvent') ?
				$_->handleEvent($event) : &$_($event)
		} for($_->get_event_listeners($name));
		return !cancelled $event if $event->propagation_stopped;
	}
	return !cancelled $event;
}

=item trigger_event($event)

Here is another non-DOM method. C<$event> can be an event object or simply 
an event name. This method triggers an
event for real, first calling C<dispatchEvent> and then running the default
action for the event unless an event listener cancels it.

=cut

sub trigger_event { # non-DOM method
	my ($target, $event) = @_;
	my $doc;
	defined blessed $event and $event->isa('HTML::DOM::Event') or do {
		my $type = $event;
		$event = ($doc = $target->ownerDocument)
			->createEvent;
		$event->initEvent($type,1,1);
	};
	$target->dispatchEvent($event) and &{
		($doc || $target->ownerDocument)->default_event_handler
		|| return
	}($event);
}

=back

=cut

1;
__END__





=head1 EXPORTS

The following node type constants are exportable:

=over 4

=item ELEMENT_NODE (1)

=item ATTRIBUTE_NODE (2)

=item TEXT_NODE (3)

=item CDATA_SECTION_NODE (4)

=item ENTITY_REFERENCE_NODE (5)

=item ENTITY_NODE (6)

=item PROCESSING_INSTRUCTION_NODE (7)

=item COMMENT_NODE (8)

=item DOCUMENT_NODE (9)

=item DOCUMENT_TYPE_NODE (10)

=item DOCUMENT_FRAGMENT_NODE (11)

=item NOTATION_NODE (12)

=back

=head1 SEE ALSO

L<HTML::DOM>

