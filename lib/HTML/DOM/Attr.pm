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
	              ref $val ? $val->data : $val; };

use HTML::DOM::Exception qw'NOT_FOUND_ERR NO_MODIFICATION_ALLOWED_ERR
                            HIERARCHY_REQUEST_ERR WRONG_DOCUMENT_ERR';
use HTML::DOM::Node 'ATTRIBUTE_NODE';
use Scalar::Util qw'weaken blessed';

require HTML::DOM::NodeList;

our $VERSION = '0.002';

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

sub _element {
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

sub specified { # ~~~ Do I need to deal with default attribute values
                #     for HTML?
	!0
}

# ------------------ NODE METHODS ------------ #

*nodeName = \&name;
*nodeValue = \&value;
*nodeType =\&ATTRIBUTE_NODE;

# These five return null
*previousSibling = *nextSibling = *attributes = *parentNode = *attributes
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
	my($self,$deep) = @_;
	my $clone = bless [@$self], ref $self;
	weaken $$clone[_doc];
	weaken $$clone[_elem];
	delete $$clone[_list];
	$$clone[_val] = [$$clone[_val][0]]; # copy the single-elem array
	                                    # that ->[_val] contains
	
	if($deep) {
		ref $$clone[_val][0] and $$clone[_val][0] = 
			$$clone[_val][0]->clone;
	}
	$clone;
}

1
