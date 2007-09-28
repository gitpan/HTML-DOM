#!/usr/bin/perl -T

use strict; use warnings;

use Scalar::Util 'refaddr';
use Test::More tests => 45;


# -------------------------#
# Test 1: load the module

BEGIN { use_ok 'HTML::DOM'; }

# -------------------------#
# Tests 2-3: constructors

my $doc = new HTML::DOM;
isa_ok $doc, 'HTML::DOM';

my $elem = $doc->createElement('a');
isa_ok $elem, 'HTML::DOM::Element';

$elem->attr('href' => 'about:blank');

# -------------------------#
# Tests 4-7: Node interface attributes

is nodeName $elem, 'A','nodeName';
cmp_ok $elem->nodeType, '==', HTML::DOM::Node::ELEMENT_NODE, 'nodeType';
is scalar(()=$elem->nodeValue), 0, 'nodeValue';
isa_ok +attributes $elem, 'HTML::DOM::NamedNodeMap';

# -------------------------#
# Test 8: tagName

is tagName $elem, 'A', 'tagName';

# -------------------------#
# Test 9: getAttribute

is $elem->getAttribute('href'), 'about:blank', 'getAttribute';

# -------------------------#
# Tests 10-11: setAttribute

is scalar(()=setAttribute $elem href=>'http://www.synodinresistance.org/'),
	0, 'setAttribute';
is $elem->getAttribute('href'),'http://www.synodinresistance.org/',
	'result of setAttribute';

# -------------------------#
# Tests 12-13: removeAttribute

is scalar(()=removeAttribute $elem 'href'),
	0, 'removeAttribute';
is $elem->getAttribute('href'),'',
	'result of removeAttribute';

$elem->attr('href' => 'about:blank'); # still need an attr with which to
                                      # experiment

# -------------------------#
# Tests 14-17: getAttributeNode


is scalar(()= getAttributeNode $elem 'aoeu'),
	0,'getAttributeNode returns null';
isa_ok+( my $attr = getAttributeNode $elem 'href'),
	'HTML::DOM::Attr';
is $attr->nodeName, 'href',
	'name of attr returned by getAttributeNode';
is $attr->nodeValue, 'about:blank',
	'value of attr returned by getAttributeNode';

# -------------------------#
# Tests 18-26: setAttributeNode

(my $new_attr = $doc->createAttribute('href'))
	->value('1.2.3.4');
is refaddr $elem->setAttributeNode($new_attr), refaddr $attr,
	'setAttributeNode returns the old node';
is $elem->getAttribute('href'), '1.2.3.4', 'result of setAttributeNode';

(my $another_attr = $doc->createAttribute('name'))->value('link');
is scalar(()=$elem->setAttributeNode($another_attr)), 0,
	'setAttributeNode can return null';
is $elem->getAttribute('name'), 'link', 'result of setAttributeNode (2)';

eval {
	$elem-> setAttributeNode(
		createAttribute {new HTML::DOM} 'ddk'
	);
};
isa_ok $@, 'HTML::DOM::Exception',
	'$@ (after setAttributeNode with wrong doc)';
cmp_ok $@, '==', HTML::DOM::Exception::WRONG_DOCUMENT_ERR,
    'setAttributeNode with wrong doc throws the appropriate error';

my $elem2 = $doc->createElement('a');
$elem2->setAttributeNode($attr);
is $elem2->getAttribute('href'), 'about:blank',
	'orphaned attribute nodes can be reused';

eval {
	$elem2-> setAttributeNode(
		$new_attr
	);
};
isa_ok $@, 'HTML::DOM::Exception',
	'$@ (after setAttributeNode with an attribute that is in use)';
cmp_ok $@, '==', HTML::DOM::Exception::INUSE_ATTRIBUTE_ERR,
    'setAttributeNode with an attribute that is in use throws the ' .
    'appropriate error';

# -------------------------#
# Tests 27-8: removeAttributeNode

is refaddr $elem->removeAttributeNode($new_attr), refaddr $new_attr,
	'return value of removeAttributeNode';
is $elem->getAttribute('href'), '', 'result of removeAttributeNode';

# -------------------------#
# Tests 29-34: getElementsByTagName

{
	$doc->write('
		<div><!--sontoeutntont-->oentoeutn</div>
		<form>
			<div id=one>
				<div id=two>
					<div id=three>
						<b id=bi>aoeu></b>teotn
					</div>
				</div>
				<div id=four><i id=i></i>
				</div>
			</div>
		</form>
	');
	$doc ->close;

	my($elem) = $doc->getElementsByTagName('form');
	my($div_list, $node_list);

	my @ids = qw[ one two three four ];

	is_deeply [map id $_, getElementsByTagName $elem 'div'], \@ids,
		'getElementsByTagName(div) in list context';

	is_deeply [map id $_, @{
			$div_list = getElementsByTagName $elem 'div'
		}], \@ids,
		'getElementsByTagName(div) in scalar context';

	@ids = qw[ one two three bi four i ];

	is_deeply [map $_->id, getElementsByTagName $elem '*'],
		\@ids, 'getElementsByTagName(*) in list context';

	is_deeply [map $_->id, @{
			$node_list = getElementsByTagName$elem '*'
		}],
		\@ids, 'getElementsByTagName(*) in scalar context';

	# Now let's transmogrify it and make sure everything
	# updates properly.

	my($div1,$div2) = $elem->getElementsByTagName('div');
	$div1->removeChild($div2)->delete;

	is_deeply [map id $_, @$div_list], [qw[ one four ]],
		'div node list is updated';

	is_deeply [map $_->id || tag $_, @$node_list],
		[qw[ one four i ]], '* node list is updated';
}

# -------------------------#
# Test 35: normalize

SKIP :{
	skip 'unimplemented', 1;
	# I'm using an extra element to make sure normalisation is
	# recursive.
	$elem->appendChild(my $elem2 = createElement $doc 'b');
	$elem2->appendChild(
		$doc->createTextNode('Mary had a little lamb'));
	$elem2->appendChild(
		$doc->createTextNode(' and then she had some more.'));
	normalize $elem;
	is data{firstChild $elem2},
		'Mary had a little lamb and then she had some more.',
		'normalize';
};

# -------------------------#
# Tests 36-45: cloneNode

$elem->appendChild($doc->createElement('span'));

my $clone = cloneNode $elem; # shallow

cmp_ok $elem, '!=', $clone, 'cloneNode makes a new object';
cmp_ok +(childNodes $elem)[0], '==', (childNodes $clone)[0],
	'shallow clone works';
is_deeply [parentNode $clone], [], 'clones are orphans';

SKIP :{
	skip unimplemented => 2;
	cmp_ok attributes $clone, '!=', attributes $elem,
		'the attributes map is cloned during a shallow clone';
	cmp_ok refaddr $clone->getAttributeNode('name'), '!=',
	       refaddr $elem->getAttributeNode('name'),
		'the attributes are cloned during a shallow clone';
};

$clone = cloneNode $elem 1; # deep

cmp_ok $elem, '!=', $clone, 'deep cloneNode makes a new object';
cmp_ok +(childNodes $elem)[0], '!=', (childNodes $clone)[0],
	'deep clone works';
is_deeply [parentNode $clone], [], 'deep clones are parentless';

SKIP :{
	skip unimplemented => 2;
	cmp_ok attributes $clone, '!=', attributes $elem,
		'the attributes map is cloned during a deep clone';
	cmp_ok refaddr $clone->getAttributeNode('name'), '!=',
	       refaddr $elem->getAttributeNode('name'),
		'the attributes are cloned during a deep clone';
};


