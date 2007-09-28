#!/usr/bin/perl -T

# This script tests the Document interface of HTML::DOM. For the other fea-
# tures, see html-dom.t.

use strict; use warnings;

use Test::More tests => 33;


# -------------------------#
# Test 1: load the module

BEGIN { use_ok 'HTML::DOM'; }

# -------------------------#
# Tests 2: constructor

my $doc = new HTML::DOM;
isa_ok $doc, 'HTML::DOM';

# -------------------------#
# Tests 3-6: node methods

is $doc ->nodeName, '#document', 'nodeName';;
is $doc->nodeType, 9, 'nodeType';
is_deeply [$doc->nodeValue], [], 'nodeValue';
is_deeply [attributes $doc], [], 'attributes';

# -------------------------#
# Tests 7-10: attributes

# set them first, to make sure they're read-only

doctype $doc 42; implementation $doc 43; documentElement $doc 44;

is_deeply [doctype $doc], [], 'doctype';
{no warnings 'once';
 is implementation $doc, $HTML::DOM::Implementation::it, 'implementation'}
isa_ok documentElement $doc, 'HTML::DOM::Element', 'doc elem';
is documentElement $doc ->tagName, 'HTML', 'tag name of documentElement';

# -------------------------#
# Tests 11-27: constructor methods

{
	isa_ok+(my $elem = createElement $doc eteiGG=>), 
		'HTML::DOM::Element', 'new elem';
	is tagName $elem, ETEIGG=> 'tag name of new elem';
}

{
	isa_ok+(my $frag = createDocumentFragment $doc), 
		'HTML::DOM::DocumentFragment', 'new frag';
	is_deeply [childNodes $frag], [], 'child nodes of new doc frag';
}

{
	isa_ok+(my $text = createTextNode $doc 'eodu'), 
		'HTML::DOM::Text', 'new text node';
	is data $text, 'eodu', 'text of new text node';
}

{
	isa_ok+(my $com = createComment $doc 'eodu'), 
		'HTML::DOM::Comment', 'new comment';
	is data $com, 'eodu', 'text of new comment';
}

eval { createCDATASection $doc };
isa_ok $@, 'HTML::DOM::Exception', '$@ after createCDATASection';
cmp_ok $@, '==', HTML::DOM::Exception::NOT_SUPPORTED_ERR,
	'createCDATASection throws a NOT_SUPPORTED_ERR';

eval { createProcessingInstruction $doc };
isa_ok $@, 'HTML::DOM::Exception', '$@ after createProcessingInstruction';
cmp_ok $@, '==', HTML::DOM::Exception::NOT_SUPPORTED_ERR,
	'createProcessingInstruction throws a NOT_SUPPORTED_ERR';

{
	isa_ok+(my $attr = createAttribute $doc 'eodu'), 
		'HTML::DOM::Attr', 'new attr';
	is nodeName $attr, 'eodu', 'name of new attr';
	is value    $attr, '',     'new attr has no value';
}

eval { createEntityReference $doc };
isa_ok $@, 'HTML::DOM::Exception', '$@ after createEntityReference';
cmp_ok $@, '==', HTML::DOM::Exception::NOT_SUPPORTED_ERR,
	'createEntityReference throws a NOT_SUPPORTED_ERR';

# -------------------------#
# Tests 28-33: getElementsByTagName

{
	$doc->write('
		<div id=one>
			<div id=two>
				<div id=three>
					<b id=bi>aoeu></b>teotn
				</div>
			</div>
			<div id=four>
			</div>
		</div>
	');
	$doc ->close;

	my($div_list, $node_list);

	my @ids = qw[ one two three four ];

	is_deeply [map id $_, getElementsByTagName $doc 'div'], \@ids,
		'getElementsByTagName(div) in list context';

	is_deeply [map id $_, @{
			$div_list = getElementsByTagName $doc 'div'
		}], \@ids,
		'getElementsByTagName(div) in scalar context';

	@ids = qw[ html head body one two three bi four ];

	is_deeply [map $_->id || tag $_, getElementsByTagName $doc '*'],
		\@ids, 'getElementsByTagName(*) in list context';

	is_deeply [map $_->id || tag $_, @{
			$node_list = getElementsByTagName $doc '*'
		}],
		\@ids, 'getElementsByTagName(*) in scalar context';

	# Now let's transmogrify it and make sure the node lists 
	# update properly.

	my($div1,$div2) = $doc->getElementsByTagName('div');
	$div1->removeChild($div2)->delete;

	is_deeply [map id $_, @$div_list], [qw[ one four ]],
		'div node list is updated';

	is_deeply [map $_->id || tag $_, @$node_list],
		[qw[ html head body one four ]], '* node list is updated';
}


diag 'TO DO: Add tests for invalid wrong document errors';
# During development, I ended up making the insertBefore, replaceChild and
# appendChild methods check to see whether $self->ownerDocument ==
# $new_node->ownerDocument. This fails if $self is the document. I need to
# write tests so this doesn't happen again.

# I probably ought to test all the node methods that are meant to call
# ->_modified on the doc. Maybe that should go in node.t.

