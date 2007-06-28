package HTML::DOM::Node;

our $VERSION = '0.001';


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
use HTML::DOM::Exception qw'NO_MODIFICATION_ALLOWED_ERR NOT_FOUND_ERR
                               HIERARCHY_REQUEST_ERR WRONG_DOCUMENT_ERR';
use Scalar::Util 'weaken';

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

1;
__END__


=head1 NAME

HTML::DOM::Node - A Perl class for representing the nodes of an HTML DOM tree

=head1 SYNOPSIS

  use HTML::DOM::Node;

  ...
  

=head1 DESCRIPTION

blar blar blar

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

=over 4

L<HTML::DOM>

