package HTML::DOM::Attr;

# ~~~ Eventually I need to add event-handling methods to Attr.

use warnings;
use strict;

# attribute constants (array elems)
sub _doc () { 0 }
sub _elem() { 1 }
sub _name() { 2 }
sub _val () { 3 } # _val actually contains an array with one element, so
sub _list() { 4 } # that nodelists can work efficiently

use overload fallback => 1,
	'""' => sub { my $val = ${+shift}[_val][0];
	              ref $val ? $val->data : $val; },
	'bool' => \&_elem;

use HTML::DOM::Exception qw'NOT_FOUND_ERR NO_MODIFICATION_ALLOWED_ERR
                            HIERARCHY_REQUEST_ERR WRONG_DOCUMENT_ERR';
use HTML::DOM::Node 'ATTRIBUTE_NODE';
use Scalar::Util qw'weaken blessed';

require HTML::DOM::NodeList;

our $VERSION = '0.012';

# -------- NON-DOM AND PRIVATE METHODS -------- #

sub new { # $_[1] contains the nayme
# ~~~ INVALID_CHARACTER_ERR is meant to be raised if the specified name contains an invalid character.
	my @self;
	@self[_name,_val] = ($_[1],['']); # value should be an empty
	                                # string, not undef
	bless \@self, shift;	
}



sub _set_ownerDocument {
	weaken ($_[0][_doc] = $_[1]);
}

sub _element { # This is like ownerElement, except that it lets you set it.
	if(@_ > 1) {
		my $old = $_[0][_elem];
		weaken ($_[0][_elem] = $_[1]);
		return $old
	}
	$_[0][_elem];
}

sub DOES {
	return !0 if $_[1] eq 'HTML::DOM::Node';
	eval { shift->SUPER::DOES(@_) } || !1
}

sub _value { # returns the value as it is, whether it is a node or scalar
	$_[0][_val][0];
}

sub _val_as_node { # turns the attribute's value into a text node if it is
                   # not one already and returns it
	my $val = $_[0][_val][0];
	defined blessed $val && $val->isa('HTML::DOM::Text')
	    ? $val
	    : ($_[0][_val][0] = $_[0]->ownerDocument->createTextNode($val))
}

# ----------- ATTR-ONLY METHODS ---------- #

sub name {
	$_[0][_name];
}

sub value {
	if(@_ > 1){
		my $old = $_[0][_val][0];
		$_[0][_val][0] = "$_[1]" ;
		return ref $old ? $old->data : $old;
	}
	my $val = $_[0][_val][0];
	ref $val ? $val->data : $val;
}

sub specified {
	my $attr=shift;
	($$attr[_elem]||return 1)->_attr_specified($$attr[_name]);
}

sub ownerElement { # ~~~ If the attr is detached, is _element currently
                   #     erased as it should be?
	shift->_element || ()
}

# ------------------ NODE METHODS ------------ #

*nodeName = \&name;
*nodeValue = \&value;
*nodeType =\&ATTRIBUTE_NODE;

# These all return null
*previousSibling = *nextSibling = *attributes = *parentNode = *prefix =
*namespaceURI = *localName = *normalize
 = sub {};

sub childNodes {
	wantarray ? $_[0]->_val_as_node :(
		$_[0]->_val_as_node,
		$_[0][_list] ||= HTML::DOM::NodeList->new($_[0][_val])
	);
}

*firstChild = *lastChild = \&_val_as_node;

sub ownerDocument { $_[0][_doc] }

sub insertBefore {
	die HTML::DOM::Exception->new(NO_MODIFICATION_ALLOWED_ERR,
	    'The list of child nodes of an attribute cannot be modified');
}

sub replaceChild {
	my($self,$new_node,$old_node) = @_;
	my $val = $self->_value;
	die HTML::DOM::Exception->new(NOT_FOUND_ERR,
	'The node passed to replaceChild is not a child of this attribute')
		if !ref $val || $old_node != $val;
	if(defined blessed $new_node and
	   isa $new_node 'HTML::DOM::DocumentFragment') {
		(($new_node) = $new_node->childNodes) != 1 and
		die HTML::DOM::Exception->new(HIERARCHY_REQUEST_ERR,
			'The document fragment to replaceChild does not ' .
			'have exactly one child node');
	}
	die HTML::DOM::Exception->new(HIERARCHY_REQUEST_ERR,
		'The node passed to replaceChild is not a text node')
		if !defined blessed $new_node ||
			!$new_node->isa('HTML::DOM::Text');
	$self->ownerDocument == $new_node->ownerDocument or
		die new HTML::DOM::Exception WRONG_DOCUMENT_ERR,
		'The node to be inserted belongs to another document';
	($_[0][_val][0] = $new_node)->detach;
	$old_node;
}


*removeChild = *appendChild = \&insertBefore;

sub hasChildNodes { 1 }

sub cloneNode {
	# ~~~ The spec.  is not clear as to what should be done with  an
	#     Attr’s child node when it is cloned shallowly. I’m here fol-
	#     lowing the behaviour of Safari and Firefox, which both ignore
	#     the ‘deep’ option.
	my($self,$deep) = @_;
	my $clone = bless [@$self], ref $self;
	# ~~~ When I start supporting ‘specified,’ I need to set it to true
	#     here.
	weaken $$clone[_doc];
	delete $$clone[$_] for _elem, _list;
	$$clone[_val] = ["$$clone[_val][0]"]; # copy the single-elem array
	                                     # that ->[_val] contains,
	                                   # flattening it in order effec-
	                                # tively to clone it.
	$clone;
}

sub hasAttributes { !1 }

sub isSupported {
	my $self = shift;
	return !1 if lc $_[0] eq 'events';
	$HTML::DOM::Implementation::it->hasFeature(@_)
}

1

__END__

=head1 NAME

HTML::DOM::Attr - A Perl class for representing attribute nodes in an HTML DOM tree

=head1 SYNOPSIS

  use HTML::DOM;
  $doc = HTML::DOM->new;
  $attr = $doc->createAttribute('href');
  $attr->nodeValue('http://localhost/');
  $elem = $doc->createElement('a');
  $elem->setAttributeNode($attr);
  
  $attr->nodeName;  # href
  $attr->nodeValue; # http://...
  
  $attr->firstChild; # a text node
  
  $attr->ownerElement; # returns $elem

=head1 DESCRIPTION

This class is used for attribute nodes in an HTML::DOM tree. It implements 
the Node and 
Attr DOM interfaces. An attribute node stringifies to its value. As a
boolean it is true, even if its value is false.

=head1 METHODS

=head2 Attributes

The following DOM attributes are supported:

=over 4

=item nodeName

=item name

These both return the name of the attribute.

=item nodeType

Returns the constant C<HTML::DOM::Node::ATTRIBUTE_NODE>.

=item nodeValue

=item value

These both return the attribute's value.

=item specified

Returns true if the attribute was specified explicitly in
the source code or was explicitly added to the tree.

=item parentNode

=item previousSibling

=item nextSibling

=item attributes

=item namespaceURI

=item prefix

=item localName

All of these simply return an empty list.

=item childNodes

In scalar context, this returns a node list object with one text node in
it. In list context it returns a list containing just that text node.

=item firstChild

=item lastChild

These both return the attribute's text node.

=item ownerDocument

Returns the document to which the attribute node belongs.

=item ownerElement

Returns the element to which the attribute belongs.

=back

=head2 Other Methods

=over 4

=item insertBefore

=item removeChild

=item appendChild

These three just throw exceptions.

=item replaceChild

If the first argument is a text node and the second is the attribute node's
own text node, then the latter is replaced with the former. This throws an
exception otherwise.

=item hasChildNodes

Returns true.

=item cloneNode

Returns a clone of the attribute.

=item normalize

Does nothing.

=item hasAttributes

Returns false.

=item isSupported

Does the same thing as L<HTML::DOM::Implementation>'s
L<hasFeature|HTML::DOM::Implementation/hasFeature> method.

=back

=head1 SEE ALSO

L<HTML::DOM>

L<HTML::DOM::Node>

L<HTML::DOM::Element>
