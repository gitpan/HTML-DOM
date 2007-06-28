package HTML::DOM::Element;

use strict;
use warnings;

use HTML::DOM::Exception qw 'INVALID_CHARACTER_ERR WRONG_DOCUMENT_ERR
                             INUSE_ATTRIBUTE_ERR NOT_FOUND_ERR';
use HTML::DOM::Node 'ELEMENT_NODE';
use Scalar::Util qw'refaddr blessed';

require HTML::DOM::Attr;
require HTML::DOM::NamedNodeMap;
require HTML::DOM::Node;
require HTML::DOM::NodeList::Magic;

our @ISA = qw'HTML::DOM::Node';
our $VERSION = '0.001';


{
	my %class_for = (
		'~text' => 'HTML::DOM::Text',
	);
	sub class_for {
		$class_for{$_[0]} || __PACKAGE__
	}
}


sub new {
	my $tagname = $_[1];
	die INVALID_CHARACTER_ERR if $tagname =~ /^_/;
	# ~~~ The DOM spec does not specify which characters are invaleid.
	#     I think I need to check the HTML spec. For now, I'm just
	#     rejecting those that conflict with HTML::Element's internals
	bless shift->SUPER::new(@_), class_for $tagname;
}

sub tagName {
	uc $_[0]->tag;
}

sub getAttribute {
	''.($_[0]->attr($_[1])||'')
}

sub setAttribute {
# ~~~ INVALID_CHARACTER_ERR

	# If the current value is an Attr object, we have to modify that
	# instead of just assigning to the attribute.
	my $attr = $_[0]->attr($_[1]);
	if(defined blessed $attr && $attr->isa('HTML::DOM::Attr')){
		$attr->value($_[2]);
	}else{
		$_[0]->attr(@_[1..2]);
	}
	return # nothing;
}

sub removeAttribute {
	# So the attr node can be reused:
	my $attr_node = $_[0]->attr($_[1]);
	defined blessed $attr_node and $attr_node->_element(undef);

	$_[0]->attr($_[1] => undef);
	return # nothing;
}

sub getAttributeNode {
	my $elem = shift;
	defined(my $attr = $elem->attr(my $name = shift)) or return;
	if(!ref $attr) {
		$elem->attr($name, my $new_attr =
			HTML::DOM::Attr->new($name));
		$new_attr->_set_ownerDocument($elem->ownerDocument);
		$new_attr->_element($elem);
		$new_attr->value($attr);
		return $new_attr;
	}
	$attr;
}

sub setAttributeNode {
	my $doc = $_[0]->ownerDocument;

	die HTML::DOM::Exception->new( WRONG_DOCUMENT_ERR,
		'The attribute passed to setAttributeNode belongs to ' .
		'another document')
		if $_[1]->ownerDocument != $doc;

	my $e;
	die HTML::DOM::Exception->new(INUSE_ATTRIBUTE_ERR,
		'The attribute passed to setAttributeNode is in use')
		if defined($e = $_[1]->_element) && $e != $_[0];

	my $old = $_[0]->attr(my $name = $_[1]->nodeName, $_[1]);
	$_[1]->_element($_[0]);

	if(defined $old) {
		if(ref $old) {
			$old->_element(undef);
			return $old;
		} else {
			my $ret =
				HTML::DOM::Attr->new($name);
			$ret->_set_ownerDocument($doc);
			$ret->_element($_[0]);
			$ret->value($old);
			return $ret;
		}			
	}
	return # nothing;
}

sub removeAttributeNode {
	my($elem,$attr) = @_;

	refaddr $attr == refaddr $elem->attr(my $name = $attr->nodeName)
		or die HTML::DOM::Exception->new(NOT_FOUND_ERR,
		"The node passed to removeAttributeNode is not an " .
		"attribute of this element.");

	$elem->attr($name, undef);
	$attr->_element(undef);
	return $attr
}


sub getElementsByTagName { # very similar to the one in HTML::DOM
	my($self,$tagname) = @_;
	if (wantarray) {
		return $tagname eq '*'
			? grep tag $_ !~ /^~/, $self->descendants
			: $self->find($tagname);
	}
	else {
		my $list = HTML::DOM::NodeList::Magic->new(
			$tagname eq '*'
			  ? sub { grep tag $_ !~ /^~/, $self->descendants }
			  : sub { $self->find($tagname) }
		);
		$self->ownerDocument-> _register_magic_node_list($list);
		$list;
	}
}

sub normalize {
	# ~~~ this needs to flatten text nodes
	#     into scalars first (or do something similar)
	shift->normalize_content
}

# ------- OVERRIDDEN NODE METHDOS ---------- #

*nodeName = \&tagName;
*nodeType = \& ELEMENT_NODE;

sub attributes {
	my $self = shift;
	$self->{_HTML_DOM_Element_map} ||=
		HTML::DOM::NamedNodeMap->new($self);
}

# ~~~ Need to implement a cloneNode method that clones attributes whether
#     or not $deep is set.
# It can call SUPER:: first and then clone its return value's attributes.
# But I need to see how HTML::Element::clone works, to see if I need to
# override that too (or instead).
# Actually, I should probably just stringify the attributes since no one
# else could have a reference to the new attrs anyway.


1


# ~~~ I need to document the class_for function.




