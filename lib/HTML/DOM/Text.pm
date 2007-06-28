package HTML::DOM::Text;

use warnings;
use strict;

use HTML::DOM::Node 'TEXT_NODE';

require HTML::DOM::CharacterData;

our @ISA = 'HTML::DOM::CharacterData';
our $VERSION = '0.001';

sub new { # $_[1] contains the text
	$_[0]->SUPER::new('~text', text => $_[1]);
}

sub splitText {
	my($self,$setoff) = @_;
	my $new_node = __PACKAGE__->new(
		# subtstringData takes care of throwing the right errors
		$self->substringData($setoff)
	);
	$self->deleteData($setoff);
	$self->postinsert($new_node);
	$new_node;
}

sub splitText16 { # UTF-16 version
	my($self,$setoff) = @_;
	my $new_node = __PACKAGE__->new(
		$self->substringData16($setoff)
	);
	$self->deleteData16(($setoff,));
	$self->postinsert($new_node);
	$new_node;
}

# ---------------- NODE METHODS ---------- #

sub nodeName { '#text' }
*nodeType = \&TEXT_NODE;

1
