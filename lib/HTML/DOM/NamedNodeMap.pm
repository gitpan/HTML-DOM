package HTML::DOM::NamedNodeMap;

use strict;
use warnings;

# Maybe for later: (this would have to convert all attributes into Attr
# objects first, or return a tied object [which possibly could be cached])
#use overload fallback => 1,
#	'@{}' => sub {
#		
#	 },
#	'%{}' => sub {
#
#	 };

use HTML::DOM::Exception qw'NOT_FOUND_ERR';
use Scalar::Util 'weaken';

our $VERSION = '0.020';

# This object stores nothing more than the Element object whose attributes
# it purports to hold.
sub new { # [0] class  [1] element obj
	my $map = bless \(my $elem = $_[1]), shift;
	weaken $$map;
	$map;
}

sub getNamedItem {
	${+shift}->getAttributeNode(shift);
}

sub setNamedItem {
	${+shift}->setAttributeNode(shift);
}

sub removeNamedItem {
	# The spec contradicts itself slightly.  It says that null  is
	# returned if no node with such a name exists, but then it says
	# that a NOT_FOUND_ERR is thrown if no node  with  such  a name
	# exists. I can't do both.
	my($elem,$name) = (${+shift},shift);
	my $attr = $elem->attr($name);
	defined $attr or die HTML::DOM::Exception->new(NOT_FOUND_ERR,
		"No attribute named $name exists");
	if(ref $attr) {
		$elem->attr($name, undef);
		$attr->_element(undef);
		return $attr
	}
	else {
		my $new_attr = HTML::DOM::Attr->new($name);
		$new_attr->_set_ownerDocument($elem->ownerDocument);
		$new_attr->value($attr);
		return $new_attr;
	}
}

sub item {
	my $elem = ${+shift};
	my $name = (sort $elem->all_external_attr_names)[shift];
	defined $name or return;
	$elem->getAttributeNode($name);
}

sub length {
	scalar(() = ${$_[0]}-> all_external_attr_names);
}

1