package HTML::DOM::Comment;

use warnings;
use strict;

use HTML::DOM::Node 'COMMENT_NODE';

require HTML::DOM::CharacterData;

our @ISA = 'HTML::DOM::CharacterData';
our $VERSION = '0.001';

sub new { # $_[1] contains the text
	$_[0]->SUPER::new('~comment', text => $_[1]);
}

# ---------------- NODE METHODS ---------- #

sub nodeName { '#comment' }
*nodeType = \&COMMENT_NODE;
sub nodeValue { $_[0]->data(@_[1..$#_]); }

1
