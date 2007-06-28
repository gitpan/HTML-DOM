#!/usr/bin/perl -T

# This script tests the Node interface. Since objects are never blessed
# into the HTML::DOM::Node class (it does have a 'new' method,  but you
# won't tell anyone, will you?), I am using a document fragment to test
# most of the interface.  The DocumentFragment interface  (supposedly)
# doesn't have any methods of its own,  but only those  in  inherits
# from Node.

use strict; use warnings;

use Test::More tests => scalar reverse 87;


# -------------------------#
# Tests 1-2: load the modules

BEGIN { use_ok 'HTML::DOM'; }
BEGIN { &use_ok(qw'HTML::DOM::Node :all'); } # & so I can use qw

# -------------------------#
# Tests 3-14: constants

{
	my $x;

	for (qw/ ELEMENT_NODE ATTRIBUTE_NODE TEXT_NODE CDATA_SECTION_NODE
	        ENTITY_REFERENCE_NODE ENTITY_NODE
	      PROCESSING_INSTRUCTION_NODE COMMENT_NODE DOCUMENT_NODE
	   DOCUMENT_TYPE_NODE DOCUMENT_FRAGMENT_NODE NOTATION_NODE /) {
		eval "is $_, " . ++$x . ", '$_'";
	}
}



# -------------------------#
# Tests 15-17: constructor

my $doc = new HTML::DOM;
isa_ok $doc, 'HTML::DOM';
my $frag = $doc->createDocumentFragment;
isa_ok $frag, 'HTML::DOM::DocumentFragment';
isa_ok $frag, 'HTML::DOM::Node'; # make sure it's node we're testing

my $another_doc = new HTML::DOM; # we need this in various places

# -------------------------#
# Tests 18-35: attributes

# wq/nodeName nodeValue nodeType/ are implemented by subclasses

{
	isa_ok my $root_elem = $doc->documentElement, 'HTML::DOM::Node';
		# just to make sure we're testing the node interface
	cmp_ok $root_elem->parentNode, '==', $doc, 'parentNode';
}

is_deeply [  childNodes $frag ], [], 'no childNodes in list context';
is_deeply [@{childNodes $frag}], [], 'no childNodes in scalar context';
is_deeply [  firstChild $frag ], [], 'firstChild is null';
is_deeply [   lastChild $frag ], [], 'lastChild is null';

# Next we'll give our doc frag a few child nodes to play withal (and we'll
# need to do this later, too, so it's in a subroutine).
sub fill_frag($) {
	my $frag = shift;
	(my $child = createElement $doc 'div')->id('wunne');
	appendChild $frag $child;
	(   $child = createElement $doc 'div')->id('tioux');
	appendChild $frag $child;
	(   $child = createElement $doc 'div')->id('three');
	appendChild $frag $child;
}
fill_frag $frag;

is_deeply [map id $_, childNodes $frag], [qw/ wunne tioux three /],
	'childNodes in list context';
is_deeply [map id $_, @{childNodes $frag}], [qw/ wunne tioux three /],
	'childNodes in scalar context';

is id{firstChild $frag}, 'wunne', 'firstChild';
is id{ lastChild $frag}, 'three',  'lastChild';

is_deeply [previousSibling $frag], [], 'null previousSibling';
is_deeply [nextSibling $frag], [], 'null nextSibling';

# make sure we're testing node methods
cmp_ok firstChild $frag ->can('nextSibling'), '==',
	HTML::DOM::Node->can('nextSibling'),
	'we\'re testing the right nextSibling';
cmp_ok childNodes $frag ->[1]->can('previousSibling'), '==',
	HTML::DOM::Node->can('previousSibling'),
	'we\'re testing the right previousSibling';

is id{nextSibling{(childNodes $frag)[0]}}, 'tioux', 'nextSibling';
is id{previousSibling{(childNodes $frag)[1]}}, 'wunne', 'previousSibling';

is_deeply [attributes $frag], [], 'attributes';

cmp_ok ownerDocument $frag, '==', $doc, 'ownerDocument';


# -------------------------#
# Tests 36-46: insertBefore

{
	$frag->insertBefore(my $elem = $doc->createElement('div'));
	$elem ->id('phour');
	is_deeply [map id $_, childNodes $frag],
		[qw/wunne tioux three phour/],
		'insertBefore with a null 2nd arg';

	$frag->insertBefore((childNodes $frag)[-1,0]);
	is_deeply [map id $_, childNodes $frag],
		[qw/phour wunne tioux three/],
		'insertBefore removes from the tree first';

	$elem = createElement $doc 'p';
	$elem->insertBefore($frag);
	is_deeply [map id $_, childNodes $elem],
		[qw/phour wunne tioux three/],
		'insertBefore(frag) inserts the frag\'s children';

	SKIP :{
		skip 'not implemented yet', 2;
		eval {
			$frag->insertBefore(
				createAttribute $doc 'ddk'
			);
		};
		isa_ok $@, 'HTML::DOM::Exception',
			'$@ (after insertBefore with wrong node type)';
		cmp_ok $@, '==', 
			HTML::DOM::Exception::HIERARCHY_REQUEST_ERR,
			'insertBefore with wrong node type throws a ' .
			'hierarchy error';
	}
	
	eval {
		($elem->childNodes)[0]->insertBefore(
			$elem
		);
	};
	isa_ok $@, 'HTML::DOM::Exception',
		'$@ (after insertBefore with an ancestor node)';
	cmp_ok $@, '==', HTML::DOM::Exception::HIERARCHY_REQUEST_ERR,
	    'insertBefore with an ancestor node throws a hierarchy error';

	eval {
		$frag->insertBefore(
			createElement $another_doc 'ddk'
		);
	};
	isa_ok $@, 'HTML::DOM::Exception',
		'$@ (after insertBefore with wrong doc)';
	cmp_ok $@, '==', HTML::DOM::Exception::WRONG_DOCUMENT_ERR,
	    'insertBefore with wrong doc throws the appropriate error';

	eval {
		$frag->insertBefore(
			$doc->createElement('ddk'), $elem
		);
	};
	isa_ok $@, 'HTML::DOM::Exception',
		'$@ (after insertBefore with a bad refChild)';
	cmp_ok $@, '==', HTML::DOM::Exception::NOT_FOUND_ERR,
		'insertBefore with a 2nd arg that\'s not a child of ' .
		'this node throws a "not found" error';
}

# -------------------------#
# Tests 47-57: replaceChild

# insertBefore messed up our frag, so let's make a new one.
fill_frag($frag = createDocumentFragment $doc);

{
	is id{$frag->replaceChild((childNodes $frag)[0,2])}, 'three',
		'replaceChild returns the replaced node';
	is_deeply [map id $_, childNodes $frag],
		[qw/tioux wunne/],
		'replaceChild removes from the tree first';

	(my $elem = createElement $doc 'p')->appendChild(
		my $node = createTextNode $doc 'lalala');
	$elem->replaceChild($frag, $node);
	is_deeply [map id $_, childNodes $elem],
		[qw/tioux wunne/],
		'replaceChild(frag,node) inserts the frag\'s children';

	SKIP :{
		skip 'not implemented yet', 2;
		eval {
			$frag->appendChild(
				my $node = createTextNode $doc 'ooo');
			$frag->replaceChild(
				(createAttribute $doc 'ddk'), $node
			);
		};
		isa_ok $@, 'HTML::DOM::Exception',
			'$@ (after replaceChild with wrong node type)';
		cmp_ok $@, '==',
			HTML::DOM::Exception::HIERARCHY_REQUEST_ERR,
			'replaceChild with wrong node type throws a ' .
			'hierarchy error';
	}
	
	eval {
		(my $node = ($elem->childNodes)[0])->appendChild(
			my $text_node = createTextNode $doc 'oetot');
		$node->replaceChild(
			$elem, $text_node
		);
	};
	isa_ok $@, 'HTML::DOM::Exception',
		'$@ (after replaceChild with an ancestor node)';
	cmp_ok $@, '==', HTML::DOM::Exception::HIERARCHY_REQUEST_ERR,
	    'replaceChild with an ancestor node throws a hierarchy error';

	eval {
		$elem->replaceChild(
			(createElement $another_doc 'ddk'),
			(childNodes $elem)[0],
		);
	};
	isa_ok $@, 'HTML::DOM::Exception',
		'$@ (after replaceChild with wrong doc)';
	cmp_ok $@, '==', HTML::DOM::Exception::WRONG_DOCUMENT_ERR,
	    'replaceChild with wrong doc throws the appropriate error';

	eval {
		$frag-> replaceChild(
			$doc->createElement('ddk'), $elem
		);
	};
	isa_ok $@, 'HTML::DOM::Exception',
		'$@ (after replaceChild with a bad refChild)';
	cmp_ok $@, '==', HTML::DOM::Exception::NOT_FOUND_ERR,
		'replaceChild with a 2nd arg that\'s not a child of ' .
		'this node throws a "not found" error';
}

# -------------------------#
# Tests 58-61: removeChild

# replaceChild messed up our frag, so let's make a new one.
fill_frag($frag = createDocumentFragment $doc);

{
	is id{$frag->removeChild((childNodes $frag)[0])}, 'wunne',
		'removeChild returns the removed node';
	is_deeply [map id $_, childNodes $frag],
		[qw/tioux three/],
		'removeChild removes the node';

	eval {
		$frag-> removeChild(
			$doc->createElement('br')
		);
	};
	isa_ok $@, 'HTML::DOM::Exception',
		'$@ (after removeChild with a bad arg)';
	cmp_ok $@, '==', HTML::DOM::Exception::NOT_FOUND_ERR,
		'removeChild with an arg that\'s not a child of ' .
		'this node throws a "not found" error';
}

# -------------------------#
# Tests 62-70: appendChild

# removeChild messed up our frag, so let's make a new one.
fill_frag($frag = createDocumentFragment $doc);

{
	is id{$frag-> appendChild((childNodes $frag)[0])}, 'wunne',
		'appendChild returns the added node';
	is_deeply [map id $_, childNodes $frag],
		[qw/tioux three wunne/],
		'appendChild removes from the tree first';

	(my $elem = createElement $doc 'p')->appendChild($frag);
	is_deeply [map id $_, childNodes $elem],
		[qw/tioux three wunne/],
		'appendChild(frag) inserts the frag\'s children';

	SKIP :{
		skip 'not implemented yet', 2;
		eval {
			$frag-> appendChild(
				(createAttribute $doc 'ddk')
			);
		};
		isa_ok $@, 'HTML::DOM::Exception',
			'$@ (after appendChild with wrong node type)';
		cmp_ok $@, '==',
			HTML::DOM::Exception::HIERARCHY_REQUEST_ERR,
			'appendChild with wrong node type throws a ' .
			'hierarchy error';
	}
	
	eval {
		appendChild{($elem->childNodes)[0]}$elem
	};
	isa_ok $@, 'HTML::DOM::Exception',
		'$@ (after appendChild with an ancestor node)';
	cmp_ok $@, '==', HTML::DOM::Exception::HIERARCHY_REQUEST_ERR,
	    'appendChild with an ancestor node throws a hierarchy error';

	eval {
		$elem-> appendChild(
			(createElement $another_doc 'ddk'),
		);
	};
	isa_ok $@, 'HTML::DOM::Exception',
		'$@ (after appendChild with wrong doc)';
	cmp_ok $@, '==', HTML::DOM::Exception::WRONG_DOCUMENT_ERR,
	    'appendChild with wrong doc throws the appropriate error';

}

# -------------------------#
# Tests 71-2: hasChildNodes

$frag = createDocumentFragment $doc;

ok !hasChildNodes $frag, '!hasChildNodes';
$frag->appendChild(createTextNode $doc 'eoteuht');
ok  hasChildNodes $frag, 'hasChildNodes';

# -------------------------#
# Tests 73-8: cloneNode

my $clone = cloneNode $frag; # shallow

cmp_ok $frag, '!=', $clone, 'cloneNode makes a new object';
cmp_ok +(childNodes $frag)[0], '==', (childNodes $clone)[0],
	'shallow clone works';
is_deeply [parentNode $clone], [], 'clones are orphans';

$clone = cloneNode $frag 1; # deep

cmp_ok $frag, '!=', $clone, 'deep cloneNode makes a new object';
cmp_ok +(childNodes $frag)[0], '!=', (childNodes $clone)[0],
	'deep clone works';
is_deeply [parentNode $clone], [], 'deep clones are parentless';


