package HTML::DOM::DocumentFragment;

use strict;

use HTML::DOM::Node 'DOCUMENT_FRAGMENT_NODE';

our @ISA = 'HTML::DOM::Node';
our $VERSION = '0.009';

sub new {
	SUPER::new{shift} '~frag';
}

sub nodeName {'#document-fragment'}
*nodeType = \& DOCUMENT_FRAGMENT_NODE;

1;
