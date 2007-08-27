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
our $VERSION = '0.005';


{
	 # ~~~ Perhaps I should make class_for into a class method, rather
	 # than a function, so Element.pm can be subclassed. Maybe I'll
	 # wait until someone tries to subclass it. (Applies to Event.pm
	 # as well.)

	my %class_for = (
		'~text' => 'HTML::DOM::Text',
		 html   => 'HTML::DOM::Element::HTML',
		 head   => 'HTML::DOM::Element::Head',
		 link   => 'HTML::DOM::Element::Link',
		 title  => 'HTML::DOM::Element::Title',
		 meta   => 'HTML::DOM::Element::Meta',
		 base   => 'HTML::DOM::Element::Base',
		 isindex=> 'HTML::DOM::Element::IsIndex',
		 style  => 'HTML::DOM::Element::Style',
		 body   => 'HTML::DOM::Element::Body',
#		 form   => 'HTML::DOM::Element::Form',
	);
	sub class_for {
		$class_for{lc$_[0]} || __PACKAGE__
	}
}


=head1 NAME

HTML::DOM::Element - A Perl class for representing elements in an HTML DOM tree

=head1 SYNOPSIS

  use HTML::DOM;
  $doc = HTML::DOM->new;
  $elem = $doc->createElement('a');

  $elem->setAttribute('href', 'http://www.perl.org/');
  $elem->getAttribute('href');
  $elem->tagName;
  # etc

=head1 DESCRIPTION

This class represents elements in an HTML::DOM tree. It is the base class
for other element classes (see
L<HTML::DOM/CLASSES AND DOM INTERFACES>.) It implements the Element and
HTMLElement DOM interfaces.

=head1 METHODS

=head2 Constructor

You should normally use HTML::DOM's C<createElement> method. This is listed
here only for completeness:

  $elem = new HTML::DOM::Element $tag_name;

C<$elem> will automatically be blessed into the appropriate class for
C<$tag_name>.

=cut 

sub new {
	my $tagname = $_[1];
	die INVALID_CHARACTER_ERR if $tagname =~ /^_/;
	# ~~~ The DOM spec does not specify which characters are invaleid.
	#     I think I need to check the HTML spec. For now, I'm just
	#     rejecting those that conflict with HTML::Element's internals
	bless shift->SUPER::new(@_), class_for $tagname;
}


=head2 Attributes

The following DOM attributes are supported:

=item tagName

Returns the tag name.

=item id

=item title

=item lang

=item dir

=item className

These five get (optionally set) the corresponding HTML attributes. Note
that C<className> corresponds to the C<class> attribute.

=back

=cut

sub tagName {
	uc $_[0]->tag;
}

sub id { # unfivetuninely, SUPER::id($something) doesn't return the old val
	if (@_ > 1) {
		my $old = $_[0]->SUPER::id;
		shift->SUPER::id(shift);
		return $old;
	} else {
		SUPER::id{shift}
	}
}

sub title { shift->attr(title => shift) }
sub lang  { shift->attr(lang  => shift) }
sub dir   { shift->attr(dir   => shift) }
sub className { shift->attr(class => shift) }

=head2 Other Methods

See the DOM spec. for descriptions.

=item getAttribute

=item setAttribute

=item removeAttribute

=item getAttributeNode

=item setAttributeNode

=item removeAttributeNode

=item getElementsByTagName

=item normalize

C<normalize> does not currently work properly.

=back

=cut

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

	# possible event handler
	if ($_[1] =~ /^on(.*)/is and my $listener_maker = $_[0]->
	     ownerDocument->event_attr_handler) {
		my $eavesdropper = &$listener_maker(
			$_[0], my $name = lc $1, $_[2]
		);
		defined $eavesdropper and $_[0]-> _add_attr_event(
			$name, $eavesdropper
		);
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

	# possible event handler
	if ($name =~ /^on(.*)/is and my $listener_maker = $_[0]->
	     ownerDocument->event_attr_handler) {
		# ~~~ Is there a possibility that the listener-maker
		#     will have a reference to the old attr node, and
		#     that calling it when that attr still has an
		#    'owner' element when it shouldn't will cause any
		#     problems? Yet I don't want to intertwine this
		#     section of code with the one below.
		my $eavesdropper = &$listener_maker(
			$_[0], $name = lc $1, $_[1]->nodeValue
		);
		defined $eavesdropper and $_[0]-> _add_attr_event(
			$name, $eavesdropper
		);
	}

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

=head1 SEE ALSO

L<HTML::DOM>

L<HTML::DOM::Node>

L<HTML::Element>

=cut


# ------- HTMLHtmlElement interface ---------- #

package HTML::DOM::Element::HTML;
our $VERSION = '0.005';
our @ISA = 'HTML::DOM::Element';
sub version { shift->attr('version' => shift) }

# ------- HTMLHeadElement interface ---------- #

package HTML::DOM::Element::Head;
our $VERSION = '0.005';
our @ISA = 'HTML::DOM::Element';
sub profile { shift->attr('profile' => shift) }

# ------- HTMLLinkElement interface ---------- #

package HTML::DOM::Element::Link;
our $VERSION = '0.005';
our @ISA = 'HTML::DOM::Element';
sub disabled {
	if(@_ > 1) {
		my $old = $_[0]->{_HTML_DOM_disabled};
		$_[0]->{_HTML_DOM_disabled} = $_[1];
		return $old;
	}
	else { $_[0]->{_HTML_DOM_disabled};}
}
sub charset  { shift->attr('charset' => shift) }
sub href     { shift->attr('href'    => shift) }
sub hreflang { shift->attr( hreflang => shift) }
sub media    { shift->attr('media'   => shift) }
sub rel      { shift->attr('rel'     => shift) }
sub rev      { shift->attr('rev'     => shift) }
sub target   { shift->attr('target'  => shift) }
sub type     { shift->attr('type'    => shift) }

# ------- HTMLTitleElement interface ---------- #

package HTML::DOM::Element::Title;
our $VERSION = '0.005';
our @ISA = 'HTML::DOM::Element';
# This is what I call FWP:
sub text {
	($_[0]->firstChild or
		@_ > 1 && $_[0]->appendChild(
			shift->ownerDocument->createTextNode(shift)
		),
		return '',
	)->data(@_[1..$#_]);
}

# ------- HTMLMetaElement interface ---------- #

package HTML::DOM::Element::Meta;
our $VERSION = '0.005';
our @ISA = 'HTML::DOM::Element';
sub content   { shift->attr('content'    => shift) }
sub httpEquiv { shift->attr('http-equiv' => shift) }
sub name      { shift->attr('name'       => shift) }
sub scheme    { shift->attr('scheme'     => shift) }

# ------- HTMLBaseElement interface ---------- #

package HTML::DOM::Element::Base;
our $VERSION = '0.005';
our @ISA = 'HTML::DOM::Element';
*href =\& HTML::DOM::Element::Link::href;
*target =\& HTML::DOM::Element::Link::target;

# ------- HTMLIsIndexElement interface ---------- #

package HTML::DOM::Element::IsIndex;
our $VERSION = '0.005';
our @ISA = 'HTML::DOM::Element';
sub form     { (shift->look_up(_tag => 'form'))[0] || () }
sub prompt   { shift->attr('prompt'  => shift) }

# ------- HTMLStyleElement interface ---------- #

package HTML::DOM::Element::Style;
our $VERSION = '0.005';
our @ISA = 'HTML::DOM::Element';
*disabled = \&HTML::DOM::Element::Link::disabled;
*media =\& HTML::DOM::Element::Link::media;
*type =\& HTML::DOM::Element::Link::type;

# ------- HTMLBodyElement interface ---------- #

package HTML::DOM::Element::Body;
our $VERSION = '0.005';
our @ISA = 'HTML::DOM::Element';
sub aLink      { shift->attr( aLink      => shift) }
sub background { shift->attr( background => shift) }
sub bgColor    { shift->attr('bgcolor'   => shift) }
sub link       { shift->attr('link'      => shift) }
sub text       { shift->attr('text'      => shift) }
sub vLink      { shift->attr('vlink'     => shift) }

1






