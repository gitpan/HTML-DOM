package HTML::DOM::Element;

use strict;
use warnings;

use HTML::DOM::Exception qw 'INVALID_CHARACTER_ERR WRONG_DOCUMENT_ERR
                             INUSE_ATTRIBUTE_ERR NOT_FOUND_ERR';
use HTML::DOM::Node 'ELEMENT_NODE';
use Scalar::Util qw'refaddr blessed';

require HTML::DOM::Attr;
require HTML::DOM::Element::Form;
require HTML::DOM::NamedNodeMap;
require HTML::DOM::Node;
require HTML::DOM::NodeList::Magic;

our @ISA = qw'HTML::DOM::Node';
our $VERSION = '0.007';


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
		 form   => 'HTML::DOM::Element::Form',
		 select => 'HTML::DOM::Element::Select',
		 optgroup=> 'HTML::DOM::Element::OptGroup',
		 option  => 'HTML::DOM::Element::Option',
		 input   => 'HTML::DOM::Element::Input',
		 textarea=> 'HTML::DOM::Element::TextArea',
		 button  => 'HTML::DOM::Element::Button',
		 label   => 'HTML::DOM::Element::Label',
		 fieldset=> 'HTML::DOM::Element::FieldSet',
		 legend  => 'HTML::DOM::Element::Legend',
		 ul      => 'HTML::DOM::Element::UL',
		 ol      => 'HTML::DOM::Element::OL',
		 dl      => 'HTML::DOM::Element::DL',
		 dir     => 'HTML::DOM::Element::Dir',
		 menu    => 'HTML::DOM::Element::Menu',
		 li      => 'HTML::DOM::Element::LI',
		 div     => 'HTML::DOM::Element::Div',
		 p       => 'HTML::DOM::Element::P',
		 heading => 'HTML::DOM::Element::Heading',
		 q       => 'HTML::DOM::Element::Quote',
		 blockquote=> 'HTML::DOM::Element::Quote',
		 pre       => 'HTML::DOM::Element::Pre',
		 br        => 'HTML::DOM::Element::Br',
		 basefont  => 'HTML::DOM::Element::BaseFont',
		 font      => 'HTML::DOM::Element::Font',
		 hr        => 'HTML::DOM::Element::HR',
		 ins       => 'HTML::DOM::Element::Mod',
		 del       => 'HTML::DOM::Element::Mod',
		 a         => 'HTML::DOM::Element::A',
		 img       => 'HTML::DOM::Element::Img',
		 object    => 'HTML::DOM::Element::Object',
		 param     => 'HTML::DOM::Element::Param',
		 applet    => 'HTML::DOM::Element::Applet',
		 map       => 'HTML::DOM::Element::Map',
		 area      => 'HTML::DOM::Element::Area',
		 script    => 'HTML::DOM::Element::Script',
#		 table   => 'HTML::DOM::Element::Table',
#		 caption => 'HTML::DOM::Element::Caption',
#		 col     => 'HTML::DOM::Element::TableColumn',
#		 colgroup=> 'HTML::DOM::Element::TableColumn',
#		 thead   => 'HTML::DOM::Element::TableSection',
#		 tfoot   => 'HTML::DOM::Element::TableSection',
#		 tbody   => 'HTML::DOM::Element::TableSection',
#		 tr      => 'HTML::DOM::Element::TR',
#		 th      => 'HTML::DOM::Element::TableCell',
#		 td      => 'HTML::DOM::Element::TableCell',
#		 frameset=> 'HTML::DOM::Element::FrameSet',
#		 frame   => 'HTML::DOM::Element::Frame',
#		 iframe  => 'HTML::DOM::Element::IFrame',
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

sub title { shift->attr(title => @_) }
sub lang  { shift->attr(lang  => @_) }
sub dir   { shift->attr(dir   => @_) }
sub className { shift->attr(class => @_) }

=head2 Other Methods

See the DOM spec. for descriptions.

=over 4

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

All the HTML::Element subclasses listed under
L<HTML::DOM/CLASSES AND DOM INTERFACES>

=cut


# ------- HTMLHtmlElement interface ---------- #

package HTML::DOM::Element::HTML;
our $VERSION = '0.007';
our @ISA = 'HTML::DOM::Element';
sub version { shift->attr('version' => @_) }

# ------- HTMLHeadElement interface ---------- #

package HTML::DOM::Element::Head;
our $VERSION = '0.007';
our @ISA = 'HTML::DOM::Element';
sub profile { shift->attr('profile' => @_) }

# ------- HTMLLinkElement interface ---------- #

package HTML::DOM::Element::Link;
our $VERSION = '0.007';
our @ISA = 'HTML::DOM::Element';
sub disabled {
	if(@_ > 1) {
		my $old = $_[0]->{_HTML_DOM_disabled};
		$_[0]->{_HTML_DOM_disabled} = $_[1];
		return $old;
	}
	else { $_[0]->{_HTML_DOM_disabled};}
}
sub charset  { shift->attr('charset' => @_) }
sub href     { shift->attr('href'    => @_) }
sub hreflang { shift->attr( hreflang => @_) }
sub media    { shift->attr('media'   => @_) }
sub rel      { shift->attr('rel'     => @_) }
sub rev      { shift->attr('rev'     => @_) }
sub target   { shift->attr('target'  => @_) }
sub type     { shift->attr('type'    => @_) }

# ------- HTMLTitleElement interface ---------- #

package HTML::DOM::Element::Title;
our $VERSION = '0.007';
our @ISA = 'HTML::DOM::Element';
# This is what I call FWP (no lexical vars):
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
our $VERSION = '0.007';
our @ISA = 'HTML::DOM::Element';
sub content   { shift->attr('content'    => @_) }
sub httpEquiv { shift->attr('http-equiv' => @_) }
sub name      { shift->attr('name'       => @_) }
sub scheme    { shift->attr('scheme'     => @_) }

# ------- HTMLBaseElement interface ---------- #

package HTML::DOM::Element::Base;
our $VERSION = '0.007';
our @ISA = 'HTML::DOM::Element';
*href =\& HTML::DOM::Element::Link::href;
*target =\& HTML::DOM::Element::Link::target;

# ------- HTMLIsIndexElement interface ---------- #

package HTML::DOM::Element::IsIndex;
our $VERSION = '0.007';
our @ISA = 'HTML::DOM::Element';
sub form     { (shift->look_up(_tag => 'form'))[0] || () }
sub prompt   { shift->attr('prompt'  => @_) }

# ------- HTMLStyleElement interface ---------- #

package HTML::DOM::Element::Style;
our $VERSION = '0.007';
our @ISA = 'HTML::DOM::Element';
*disabled = \&HTML::DOM::Element::Link::disabled;
*media =\& HTML::DOM::Element::Link::media;
*type =\& HTML::DOM::Element::Link::type;

# ------- HTMLBodyElement interface ---------- #

package HTML::DOM::Element::Body;
our $VERSION = '0.007';
our @ISA = 'HTML::DOM::Element';
sub aLink      { shift->attr( aLink      => @_) }
sub background { shift->attr( background => @_) }
sub bgColor    { shift->attr('bgcolor'   => @_) }
sub link       { shift->attr('link'      => @_) }
sub text       { shift->attr('text'      => @_) }
sub vLink      { shift->attr('vlink'     => @_) }

# ------- HTMLFormElement interface ---------- #

# See Element/Form.pm

# ~~~ list other form things here for reference

# ------- HTMLUListElement interface ---------- #

package HTML::DOM::Element::UL;
our $VERSION = '0.007';
our @ISA = 'HTML::DOM::Element';
sub compact { shift->attr( compact => @_) }
*type =\& HTML::DOM::Element::Link::type;

# ------- HTMLOListElement interface ---------- #

package HTML::DOM::Element::OL;
our $VERSION = '0.007';
our @ISA = 'HTML::DOM::Element';
sub start { shift->attr( start => @_) }
*compact=\&HTML::DOM::Element::UL::compact;
* type = \ & HTML::DOM::Element::Link::type ;

# ------- HTMLDListElement interface ---------- #

package HTML::DOM::Element::DL;
our $VERSION = '0.007';
our @ISA = 'HTML::DOM::Element';
*compact=\&HTML::DOM::Element::UL::compact;

# ------- HTMLDirectoryElement interface ---------- #

package HTML::DOM::Element::Dir;
our $VERSION = '0.007';
our @ISA = 'HTML::DOM::Element';
*compact=\&HTML::DOM::Element::UL::compact;

# ------- HTMLMenuElement interface ---------- #

package HTML::DOM::Element::Menu;
our $VERSION = '0.007';
our @ISA = 'HTML::DOM::Element';
*compact=\&HTML::DOM::Element::UL::compact;

# ------- HTMLLIElement interface ---------- #

package HTML::DOM::Element::LI;
our $VERSION = '0.007';
our @ISA = 'HTML::DOM::Element';
*type =\& HTML::DOM::Element::Link::type;
sub value { shift->attr( value => @_) }

# ------- HTMLDivElement interface ---------- #

package HTML::DOM::Element::Div;
our $VERSION = '0.007';
our @ISA = 'HTML::DOM::Element';
sub align { shift->attr( align => @_) }

# ------- HTMLParagraphElement interface ---------- #

package HTML::DOM::Element::P;
our $VERSION = '0.007';
our @ISA = 'HTML::DOM::Element';
*align =\& HTML::DOM::Element::Div::align;

# ------- HTMLHeadingElement interface ---------- #

package HTML::DOM::Element::Heading;
our $VERSION = '0.007';
our @ISA = 'HTML::DOM::Element';
*align =\& HTML::DOM::Element::Div::align;

# ------- HTMLQuoteElement interface ---------- #

package HTML::DOM::Element::Quote;
our $VERSION = '0.007';
our @ISA = 'HTML::DOM::Element';
sub cite { shift->attr( cite => @_) }

# ------- HTMLPreElement interface ---------- #

package HTML::DOM::Element::Pre;
our $VERSION = '0.007';
our @ISA = 'HTML::DOM::Element';
sub width { shift->attr( width => @_) }

# ------- HTMLBRElement interface ---------- #

package HTML::DOM::Element::Br;
our $VERSION = '0.007';
our @ISA = 'HTML::DOM::Element';
sub clear { shift->attr( clear => @_) }

# ------- HTMLBaseFontElement interface ---------- #

package HTML::DOM::Element::BaseFont;
our $VERSION = '0.007';
our @ISA = 'HTML::DOM::Element';
sub color { shift->attr( color => @_) }
sub face  { shift->attr( face  => @_) }
sub size  { shift->attr( size  => @_) }

# ------- HTMLBaseFontElement interface ---------- #

package HTML::DOM::Element::Font;
our $VERSION = '0.007';
our @ISA = 'HTML::DOM::Element';
*color =\& HTML::DOM::Element::BaseFont::color;
*face =\& HTML::DOM::Element::BaseFont::face;
*size =\& HTML::DOM::Element::BaseFont::size;

# ------- HTMLHRElement interface ---------- #

package HTML::DOM::Element::HR;
our $VERSION = '0.007';
our @ISA = 'HTML::DOM::Element';
*align =\& HTML::DOM::Element::Div::align;
sub noShade  { shift->attr( noshade  => @_) }
*size =\& HTML::DOM::Element::BaseFont::size;
*width =\& HTML::DOM::Element::Pre::width;

# ------- HTMLModElement interface ---------- #

package HTML::DOM::Element::Mod;
our $VERSION = '0.007';
our @ISA = 'HTML::DOM::Element';
*cite =\& HTML::DOM::Element::Quote::cite;
sub dateTime  { shift->attr( datetime  => @_) }

# ------- HTMLAnchorElement interface ---------- #

package HTML::DOM::Element::A;
our $VERSION = '0.007';
our @ISA = 'HTML::DOM::Element';
sub accessKey  { shift->attr(               accesskey  => @_) }
*   href       =\&HTML::DOM::Element::Link::href              ;
*   hreflang   =\&HTML::DOM::Element::Link::hreflang          ;
*   name       =\&HTML::DOM::Element::Meta::name              ;
*   rel        =\&HTML::DOM::Element::Link::rel               ;
*   rev        =\&HTML::DOM::Element::Link::rev               ;
sub shape      { shift->attr(               shape      => @_) }
*   target     =\&HTML::DOM::Element::Link::target            ;
*   type       =\&HTML::DOM::Element::Link::type              ;

sub blur  { shift->trigger_event('blur') }
sub focus { shift->trigger_event('focus') }

# ------- HTMLImageElement interface ---------- #

package HTML::DOM::Element::Img;
our $VERSION = '0.007';
our @ISA = 'HTML::DOM::Element';
sub lowSrc  { shift->attr(               lowsrc  => @_) }
*   name  = \&HTML::DOM::Element::Meta::name            ;
*   align = \&HTML::DOM::Element::Div::align            ;
sub alt     { shift->attr(               alt     => @_) }
sub border  { shift->attr(               border  => @_) }
sub height  { shift->attr(               height  => @_) }
sub hspace  { shift->attr(               hspace  => @_) }
sub isMap   { shift->attr(               ismap   => @_) }
sub longDesc { shift->attr(              longdesc => @_) }
sub src      { shift->attr(              src      => @_) }
sub useMap   { shift->attr(              usemap   => @_) }
sub vspace   { shift->attr(              vspace   => @_) }
*   width = \&HTML::DOM::Element::Pre::width             ;

# ------- HTMLObjectElement interface ---------- #

package HTML::DOM::Element::Object;
our $VERSION = '0.007';
our @ISA = 'HTML::DOM::Element';
*form=\&HTML::DOM::Element::IsIndex::form;
sub code  { shift->attr(               code  => @_) }
*   align = \&HTML::DOM::Element::Div::align            ;
sub archive  { shift->attr(               archive  => @_) }
sub border  { shift->attr(               border  => @_) }
sub codeBase     { shift->attr(               codebase     => @_) }
sub codeType     { shift->attr(               codetype     => @_) }
sub data  { shift->attr(               data  => @_) }
sub declare  { shift->attr(               declare  => @_) }
*   height = \&HTML::DOM::Element::Img::height             ;
*   hspace = \&HTML::DOM::Element::Img::hspace             ;
*   name  = \&HTML::DOM::Element::Meta::name            ;
sub standby { shift->attr(              standby => @_) }
sub tabIndex      { shift->attr(              tabindex      => @_) }
*type =\& HTML::DOM::Element::Link::type;
*useMap =\& HTML::DOM::Element::Img::usemap;
*vspace =\& HTML::DOM::Element::Img::vspace;
*   width = \&HTML::DOM::Element::Pre::width             ;

# ------- HTMLParamElement interface ---------- #

package HTML::DOM::Element::Param;
our $VERSION = '0.007';
our @ISA = 'HTML::DOM::Element';
*name=\&HTML::DOM::Element::Meta::name;
*type=\&HTML::DOM::Element::Link::type;
*value=\&HTML::DOM::Element::LI::value;
sub valueType{shift->attr(valuetype=>@_)}

# ------- HTMLAppletElement interface ---------- #

package HTML::DOM::Element::Applet;
our $VERSION = '0.007';
our @ISA = 'HTML::DOM::Element';
* align    = \ & HTML::DOM::Element::Div::align       ;
* alt      = \ & HTML::DOM::Element::Img::alt         ;
* archive  = \ & HTML::DOM::Element::Object::archive  ;
* code     = \ & HTML::DOM::Element::Object::code     ;
* codeBase = \ & HTML::DOM::Element::Object::codebase ;
* height   = \ & HTML::DOM::Element::Img::height      ;
* hspace   = \ & HTML::DOM::Element::Img::hspace      ;
* name     = \ & HTML::DOM::Element::Meta::name       ;
sub object { shift -> attr ( object => @_ ) }
* vspace   = \ & HTML::DOM::Element::Img::vspace      ;
* width    = \ & HTML::DOM::Element::Pre::width       ;

# ------- HTMLMapElement interface ---------- #

package HTML::DOM::Element::Map;
our $VERSION = '0.007';
our @ISA = 'HTML::DOM::Element';
sub areas { # ~~~ I need to make this cache the resulting collection obj
	# ~~~ Since client-side image maps may use either <a> or <area>
	#     elems, should this list <a> elements in the former case?
	my $self = shift;
	if (wantarray) {
		return grep tag $_ eq 'area', $self->descendants;
	}
	else {
		my $collection = HTML::DOM::Collection->new(
		my $list = HTML::DOM::NodeList::Magic->new(
		    sub { grep tag $_ eq 'area', $self->descendants }
		));
		$self->ownerDocument-> _register_magic_node_list($list);
		$collection;
	}
}
* name     = \ & HTML::DOM::Element::Meta::name       ;

# ------- HTMLAreaElement interface ---------- #

package HTML::DOM::Element::Area;
our $VERSION = '0.007';
our @ISA = 'HTML::DOM::Element';
* accessKey = \ & HTML::DOM::Element::A::accessKey     ;
* alt       = \ & HTML::DOM::Element::Img::alt         ;
sub coords { shift -> attr ( coords => @_ ) }
* href      = \ & HTML::DOM::Element::Link::href       ;
sub noHref { shift -> attr ( nohref => @_ ) }
* shape     = \ & HTML::DOM::Element::A::shape         ;
* tabIndex  = \ & HTML::DOM::Element::Object::tabIndex ;
* target    = \ & HTML::DOM::Element::Link::target     ;

# ------- HTMLScriptElement interface ---------- #

package HTML::DOM::Element::Script;
our $VERSION = '0.007';
our @ISA = 'HTML::DOM::Element';
* text    = \ &HTML::DOM::Element::Title::text   ;
sub htmlFor { shift -> attr ( for   => @_ )      }
sub event   { shift -> attr ( event => @_ )      }
* charset = \ &HTML::DOM::Element::Link::charset ;
sub defer   { shift -> attr ( defer => @_ )      }
* src     = \ &HTML::DOM::Element::Img::src      ;
* type    = \ &HTML::DOM::Element::Link::type    ;

1




