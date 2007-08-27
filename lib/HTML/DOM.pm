package HTML::DOM;

# If you are looking at the source code (which you are obviously doing
# if you are reading this),  note that  '# ~~~'  is my way of  marking
# something to be done still (except in this sentence).


require 5.006; # ~~~ What does it actually need?
use strict;
use warnings;

use HTML::DOM::Exception 'NOT_SUPPORTED_ERR';
use HTML::DOM::Node 'DOCUMENT_NODE';
use Scalar::Util 'weaken';
use URI;

our $VERSION = '0.005';
our @ISA = 'HTML::DOM::Node';

require    HTML::DOM::Collection;
require         HTML::DOM::Comment;
require HTML::DOM::DocumentFragment;
require            HTML::DOM::Event;
require  HTML::DOM::Implementation;
require         HTML::DOM::Element;
require HTML::DOM::NodeList::Magic;
require             HTML::DOM::Text;
require             HTML::TreeBuilder;


=head1 NAME

HTML::DOM - A Perl implementation of the HTML Document Object Model

=head1 VERSION

Version 0.005 (alpha)

B<WARNING:> This module is still at an experimental stage. Only a few
features have been implemented so far. The API is subject to change without
notice.

=head1 SYNOPSIS

  use HTML::DOM;
  
  my $dom_tree = new HTML::DOM; # empty tree
  $dom_tree->parse_file($filename);
  
  $dom_tree->getElementsByTagName('body')->[0]->appendChild(
           $dom_tree->createElement('input')
  );
  
  print $dom_tree->documentElement->as_HTML, "\n";
  # (inherited from HTML::Element)

  my $text = $dom_tree->createTextNode('text');
  $text->data;              # get attribute
  $text->data('new value'); # set attribute
  
=head1 DESCRIPTION

This module implements the HTML Document Object Model by extending the
HTML::Tree modules. The HTML::DOM class serves both as an HTML parser and
as the document class.

=head1 METHODS

=head2 Non-DOM Methods

=over 4

=item $tree = new HTML::DOM %options;

This class method constructs and returns a new HTML::DOM object. The
C<%options>, which are all optional, are as follows:

=over 4

=item url

The value that the C<URL> method will return. This value is also used by
the C<domain> method. 

=item referrer

The value that the C<referrer> method will return

=item response

An HTTP::Response object. This will be used for information needed for 
writing cookies. It is expected to have a reference to a request object
(accessible via its C<request> method--see L<HTTP::Response>). Passing a 
parameter to the 'cookie' method will be a no-op 
without this.

=item cookie_jar

An HTTP::Cookies object. As with C<response>, if you omit this, arguments 
passed to the 
C<cookie> method will be ignored.

=back

If C<referrer> and C<url> are omitted, they can be inferred from 
C<response>.

=cut

{	# The only purpose of this extra package is to make the TB inherit
	# from HTML::DOM::Element as well as HTML::Element
	# ~~~ If H:D:E has to override H:E methods, I'll have to change
	#     the order of @ISA, and make sure that 'new', below, calls
	#     HTML::DOM::TreeBuilder->HTML::TreeBuilder::new.
	package HTML::DOM::TreeBuilder;
	our @ISA = qw'HTML::TreeBuilder HTML::DOM::Element';

	# I have to override this so it doesn't delete _HTML_DOM_* attri-
	# butes and so that it blesses the object into the right  class.
	# Stolen from HTML::TreeBuilder and modified.
	# ~~~ Wait a minute! I *can* call SUPER:: if I record the hash
	#     elems first and put them back in afterwards. Yes, let's do
	#     that.
	sub elementify {
	  # Rebless this object down into the normal element class.
	  my $self = $_[0];
#	  my $to_class = ($self->{'_element_class'} || 'HTML::Element');
	  delete @{$self}{ grep {;
	    length $_ and substr($_,0,1) eq '_'
	   # The private attributes that we'll retain:
	    and $_ ne '_tag' and $_ ne '_parent' and $_ ne '_content'
	    and $_ ne '_implicit' and $_ ne '_pos'
	    and $_ ne '_element_class' and !/^_HTML_DOM_/
	  } keys %$self };
#	  bless $self, $to_class;   # Returns the same object we were fed
	  bless $self, HTML::DOM::Element::class_for(tag $self);
	}

} # end of special TreeBuilder package

sub new {
	my $self = shift->SUPER::new('~doc');
	(my $tb = new HTML::DOM::TreeBuilder
		element_class => 'HTML::DOM::Element',
		'tweak_~text' => sub {
			my ($text, $parent) = @_;
			# $parent->ownerDocument will be undef if $parent
			# is the doc.
			$parent->splice_content(  -1,1,
				($parent->ownerDocument || $parent)
				 ->createTextNode($text)  );
		 },
	 )
	   ->ignore_ignorable_whitespace(0); # stop eof()'s cleanup
	                                       # from changing the
	$tb->unbroken_text(1); # necessary, con-  # script handler's view 
	                     # sidering what        # of the tree
	                   # _tweak_~text does
	my %opts = @_;
	$self->{_HTML_DOM_url} = $opts{url}; # might be undef
	$self->{_HTML_DOM_referrer} = $opts{referrer}; # might be undef
	if($opts{response}) {
		$self->{_HTML_DOM_response} = $opts{response};
		if(!defined $self->{_HTML_DOM_url}) {{
			$self->{_HTML_DOM_url} =
				($opts{response}->request || last)
				 ->url;
		}}
		if(!defined $self->{_HTML_DOM_referrer}) {{
			$self->{_HTML_DOM_referrer} =
				($opts{response}->request || last)
				 ->header('Referer')
		}}
	}
	$self->{_HTML_DOM_jar} = $opts{cookie_jar}; # might be undef
	$self->push_content($tb);
}

=item $tree = new_from_file HTML::DOM

=item $tree = new_from_content HTML::DOM

B<Not yet implemented.>

=item $tree->elem_handler($elem_name => sub { ... })

This method has no effect unless you call it I<before> building the DOM
tree. If you call this method, then, when the DOM tree is in the 
process of
being built, the subroutine will be called after each C<$elem_name> element 
is
added to the tree. If you give '*' as the element name, the subroutine will
be called for each element that does not have a handler. The subroutine's 
two arguments will be the tree itself
and the element in question. The subroutine can call the DOM object's 
C<write>
method to insert HTML code into the source after the element.

Here is a lame example (which does not take Content-Script-Type headers
or security into account):

  $tree->elem_handler(script => sub {
      my($document,$elem) = @_;
      return unless $elem->attr('type') eq 'application/x-perl';
      eval($elem->firstChild->data);
  });

  $tree->parse(
      '<p>The time is
           <script type="application/x-perl">
                $document->write(scalar localtime)
           </script>
           precisely.
       </p>'
  );
  $tree->eof;

  print $tree->documentElement->as_text, "\n";

=cut

sub elem_handler {
	my ($self,$elem_name,$sub) = @_;
	my $doc_elem = ($self->content_list)[0];
	weaken $doc_elem;
	$doc_elem->{"_tweak_$elem_name"} = sub {
		{ local $$self{_HTML_DOM_buffered} = 1;
		  &$sub($self, $_[0]); }
		return unless exists $$self{_HTML_DOM_write_buffer};

		# These handlers delegate the handling to methods of
		# *another* HTML::Parser object.
		my $p = HTML::Parser->new(
			start_h => [ 
				sub { $doc_elem->start(@_) },
				'tagname, attr, attrseq, text'
			],
			end_h => [ 
				sub { $doc_elem->end(@_) },
				'tagname, text'
			],
			text_h => [ 
				sub { $doc_elem->text(@_) },
				'text, is_cdata'
			],
		);

		$p->unbroken_text(1); # push_content, which is called by
		                     # H:TB:text, won't concatenate two
		                   # text portions if the  first  one
		                  # is a node.

		# We have to clear the write buffalo before calling parse,
		# because if the  buffalo  contains  $elem_name  elements,
		# parse will (indirectly) call this very routine while the
		# buffalo is still full, so we will end up passing the same
		# value to parse yet again....  (This is  what  we  usually
		# call infinite recursion, I think. :-)
		$p->parse(delete $$self{_HTML_DOM_write_buffer});
		$p->eof;
	}
}



=item $tree->parse_file($file)

=item $tree->parse(...)

=item $tree->eof()

These three methods simply
call HTML::TreeBuilder's methods with the same name (q.v., and see also
HTML::Element), but note that
C<parse_file> may only be called once for each HTML::DOM object
(since it deletes its parser when it no longer needs it), unless you reset
the object by calling the C<open> method. Similarly,
C<parse> may not be called after C<eof> (again, unless you call C<open>
first, which is what C<write> does automatically, so I don't know why I
even bother keeping the C<parse> method at all; maybe I should do away
with it).

=cut

sub parse_file {
	(my $a = (shift->content_list)[0])
		->parse_file(@_);
	 $a	->elementify;
}
sub parse {
	(my $a = (shift->content_list)[0])
		->parse(@_);
}
sub eof {
	eval { # make it a no-op if there's no parser
	(my $a = (shift->content_list)[0])
		->eof(@_);
	 $a	->elementify;
	};
	return # nothing; # so that close (an alias to this) is stan-
	                  # dards-compliant
}


=item $tree->event_attr_handler

=item $tree->default_event_handler

See L</EVENT HANDLING>, below.

=back

=head2 DOM Methods

(This section needs to be written.)

=over 4

=cut


#-------------- DOM STUFF (CORE) ---------------- #

=item etc. etc. etc.

=cut

sub doctype {} # always null

sub implementation {
	no warnings 'once';
	return $HTML::DOM::Implementation::it;
}

sub documentElement {
	($_[0]->content_list)[0]
}

sub createElement {
	my $elem = HTML::DOM::Element->new($_[1]);
	$elem->_set_ownerDocument(shift);
	$elem;
}

sub createDocumentFragment {
	my $thing = HTML::DOM::DocumentFragment->new;
	$thing->_set_ownerDocument(shift);
	$thing;
}

sub createTextNode {
	my $thing = HTML::DOM::Text->new(@_[1..$#_]);
	$thing->_set_ownerDocument(shift);
	$thing;
}

sub createComment {
	my $thing = HTML::DOM::Comment->new(@_[1..$#_]);
	$thing->_set_ownerDocument(shift);
	$thing;
}

sub createCDATASection {
	die HTML::DOM::Exception->new( NOT_SUPPORTED_ERR,
		'The HTML DOM does not support CDATA sections' );
}

sub createProcessingInstruction {
	die HTML::DOM::Exception->new( NOT_SUPPORTED_ERR,
		'The HTML DOM does not support processing instructions' );
}

sub createAttribute {
	my $thing = HTML::DOM::Attr->new(@_[1..$#_]);
	$thing->_set_ownerDocument(shift);
	$thing;
}

sub createEntityReference {
	die HTML::DOM::Exception->new( NOT_SUPPORTED_ERR,
		'The HTML DOM does not support entity references' );
}

sub getElementsByTagName {
	my($self,$tagname) = @_;
	#warn "You didn't give me a tag name." if !defined $tagname;
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
		$self-> _register_magic_node_list($list);
		$list;
	}
}

#-------------- DOM STUFF (HTML) ---------------- #

=item alinkColor

=item background

=item bgColor

=item fgColor

=item linkColor

=item vlinkColor

These six methods return (optionally set) the corresponding attributes of 
the body element. Note that most of the names do not map directly to the 
names of
the attributes. C<fgColor> refers to the C<text> attribute. Those that end
with 'linkColor' refer to the attributes of the same name but without the
'Color' on the end.

B<These don't work yet, and won't work until HTML::DOM::Element::Body is
implemented.>

=cut

sub alinkColor { shift->body->aLink     (@_) }
sub background { shift->body->background(@_) }
sub    bgColor { shift->body->bgColor   (@_) }
sub    fgColor { shift->body->text      (@_) }
sub  linkColor { shift->body->link      (@_) }
sub vlinkColor { shift->body->vLink     (@_) }

=item title

Returns (or optionally sets) the title of the page.

=item referrer

Returns the page's referrer.

=item domain

Returns the domain name portion of the document's URL.

=item URL

Returns the document's URL.

=item body

Returns the body element, or the outermost frame set if the document has
frames. You can set the body by passing an element as an argument, in which
case the old body element is returned. In this case you should call
C<delete> on the return value to remove circular references, unless you
plan to use it still. E.g.,

  $doc->body($new_body)->delete;

=item images

=item applets

=item links

=item forms

=item anchors

These five methods return a list of the appropriate elements in list
context, or an L<HTML::DOM::Collection> object in scalar context. In this
latter case, the object will update automatically when the document is
modified.

B<TO DO:> I need to make these methods cache the HTML collection objects
that they create. Once I've done this, I can make list context use those
objects, as well as scalar context.

=item cookie

This returns a string containing the document's cookies (the format may
still change). If you pass an 
argument, it
will set a cookie as well. Both Netscape-style and RFC2965-style cookie
headers are supported.

=cut

sub title {
	my $doc = shift;
	return $doc->find('title')->firstChild->data(@_);
}

sub referrer {
	my $referrer = shift->{_HTML_DOM_referrer};
	defined $referrer ? $referrer : ();
}

sub domain { no strict;
	my $doc = shift;
	host {ref $doc->{_HTML_DOM_url} ? $doc->{_HTML_DOM_url}
	  : ($doc->{_HTML_DOM_url} = URI->new($doc->{_HTML_DOM_url}))};
}

sub URL {
	my $url = shift->{_HTML_DOM_url};
	"$url";
}

sub body { # ~~~ this needs to return the outermost frameset element if
            #     there is one (if the frameset is always the second child
            #     of <html>, then it already does).
	if(@_>1) {
		my $doc_elem = $_[0]->documentElement;
		# I'm using the replaceChild rather than replace_with,
		# despite the former's convoluted syntax, since the former
		# has the appropriate error-checking code (or will).
		$doc_elem->replaceChild($_[1],($doc_elem->content_list)[1])
	}
	else {
		($_[0]->documentElement->content_list)[1];
	}
}

sub images {
	my $self = shift;
	if (wantarray) {
		return grep tag $_ eq 'img', $self->descendants;
	}
	else {
		my $collection = HTML::DOM::Collection->new(
		my $list = HTML::DOM::NodeList::Magic->new(
		    sub { grep tag $_ eq 'img', $self->descendants }
		));
		$self-> _register_magic_node_list($list);
		$collection;
	}
}

sub applets {
	my $self = shift;
	if (wantarray) {
		return grep $_->tag =~ /^(?:objec|apple)t\z/,
			$self->descendants;
	}
	else {
		my $collection = HTML::DOM::Collection->new(
		my $list = HTML::DOM::NodeList::Magic->new(
		    sub { grep $_->tag =~ /^(?:objec|apple)t\z/,
		        $self->descendants }
		));
		$self-> _register_magic_node_list($list);
		$collection;
	}
}

sub links {
	my $self = shift;
	if (wantarray) {
		return grep {
			my $tag = tag $_;
			$tag eq 'area' || $tag eq 'a'
				&& defined $_->attr('href')
		} $self->descendants;
	}
	else {
		my $collection = HTML::DOM::Collection->new(
		my $list = HTML::DOM::NodeList::Magic->new(
		    sub { grep {
		        my $tag = tag $_;
		        $tag eq 'area' || $tag eq 'a'
		            && defined $_->attr('href')
		    } $self->descendants }
		));
		$self-> _register_magic_node_list($list);
		$collection;
	}
}

sub forms {
	my $self = shift;
	if (wantarray) {
		return grep tag $_ eq 'form', $self->descendants;
	}
	else {
		my $collection = HTML::DOM::Collection->new(
		my $list = HTML::DOM::NodeList::Magic->new(
		    sub { grep tag $_ eq 'form', $self->descendants }
		));
		$self-> _register_magic_node_list($list);
		$collection;
	}
}

sub anchors {
	my $self = shift;
	if (wantarray) {
		return grep tag $_ eq 'a' && defined $_->attr('name'),
			$self->descendants;
	}
	else {
		my $collection = HTML::DOM::Collection->new(
		my $list = HTML::DOM::NodeList::Magic->new(
		    sub { grep tag $_ eq 'a' && defined $_->attr('name'),
		        $self->descendants }
		));
		$self-> _register_magic_node_list($list);
		$collection;
	}
}


sub cookie {
  my $self = shift;
  return '' unless defined (my $jar = $self->{_HTML_DOM_jar});
  my $return;
  if (defined wantarray) {
    # Yes, this is nuts (getting HTTP::Cookies to join the cookies, and
    # splitting them, filtering them, and joining them again[!]),  but
    # &HTTP::Cookies::add_cookie_header is long and complicated, and I
    # don't want to replicate it here.
    no warnings 'uninitialized';
    $return = join ';', grep !/\$/, 
      $jar->add_cookie_header(
        $self->{_HTML_DOM_response}->request->clone
      )-> header ('Cookie')
      # Pieces of this regexp were stolen from HTTP::Headers::Util:
      =~ /\G\s* # initial whitespace
          (
            [^\s=;,]+ # name
            \s*=\s*   # =
            (?:
              \"(?:[^\"\\]*(?:\\.[^\"\\]*)*)\" # quoted value
                |
              [^;,\s]*  # unquoted value
            )
          )
          \s*;?
         /xg;
  }
  if (@_) {
    return unless defined $self->{_HTML_DOM_response};
    require HTTP::Headers::Util;
    (undef,undef, my%split) =
	@{(HTTP::Headers::Util::split_header_words($_[0]))[0]};
    my $rfc;
    for(keys %split){
      # I *hope* this always works! (NS cookies should have no version.)
      ++ $rfc, last if lc $_ eq 'version';
    }
    (my $clone = $self->{_HTML_DOM_response}->clone)
     ->remove_header(qw/ Set-Cookie Set-Cookie2 /);
    $clone->header('Set-Cookie' . 2 x!! $rfc => $_[0]);
    $jar->extract_cookies($clone);
  }
  $return||'';
}

=item open

Resets the document to the state it was in immediately after calling
C<new>. If you have a subclass that has its own attributes inside the
object, they will be wiped out.

=item close

An alias to C<eof> (flushes any HTML code that might be buffered after
calling C<write>/C<parse>, and makes the next C<write> call C<open>)

=item write

When this is called from an an element handler (see
C<elem_handler>, above), the value passed to it
will be inserted into the HTML code after the current element when the
element handler returns.

Otherwise it appends the HTML code to the current document (via C<parse>), 
unless C<eof>
has been called, in which case it calls C<open> before calling C<parse>.

=item writeln

Just like C<write> except that it appends "\n" to its argument. (Rather
pointless, if you ask me. :-)

=cut

sub open {
	(my $self = shift)->delete_content; # remove circular references
	%$self = (%{ref($self)->new},
		_HTML_DOM_url => $$self{_HTML_DOM_url},
		_HTML_DOM_referrer => $$self{_HTML_DOM_referrer},
		_HTML_DOM_response => $$self{_HTML_DOM_response},
		_HTML_DOM_jar => $$self{_HTML_DOM_jar}
	);
	return # nothing;
}

sub write {
	my $self = shift;
	if($$self{_HTML_DOM_buffered}) {
		$$self{_HTML_DOM_write_buffer} .= shift;
	}
	else {
		eval {($self->content_list)[0]->isa('HTML::TreeBuilder')}
			or $self->open;
		$self->parse(shift);
	}
	return # nothing;
}

sub writeln { $_[0]->write("$_[1]\n") }

*close = \&eof;

=item getElementById

=item getElementsByName

These two do what their names imply. The latter will return a list in list
context, or a node list object in scalar context. Calling it in list
context is probably more efficient.

=cut

sub getElementById {
	shift->look_down(id => shift) || ();
}

sub getElementsByName {
	my($self,$name) = @_;
	if (wantarray) {
		return $self->look_down(name => $name);
	}
	else {
		my $list = HTML::DOM::NodeList::Magic->new(
			  sub { $self->look_down(name => $name); }
		);
		$self-> _register_magic_node_list($list);
		$list;
	}
}


# ---------- DocumentEvent interface -------------- #

=item createEvent

This currently ignores its args. Later the arg passed to it will determine
into which class the newly-created event object is blessed.

=back

=cut

sub createEvent { HTML::DOM::Event::class_for($_[1] || '')->new }

# ---------- OVERRIDDEN NODE METHODS -------------- #

sub ownerDocument {} # empty list
sub nodeName { '#document' }
{ no warnings 'once'; *nodeType = \& DOCUMENT_NODE; }


=head1 EVENT HANDLING

HTML::DOM supports both the DOM Level 2 event model and the HTML 4 event
model (at least in part, so far [in particular, the Event base class is
implemented, but none of its subclasses; no events are triggered 
automatically yet]).

An event listener (aka handler) is a coderef, an object with a 
C<handleEvent>
method or an object with C<&{}> overloading. HTML::DOM does not implement
any classes that provide a C<handleEvent> method, but will support any
object that has one.

To specify the default actions associated with an event, provide a
subroutine via the C<default_event_handler> method. The first argument will
be the event object. For instance:

  $dom_tree->default_event_handler(sub {
         my($self, $event) = @_;
         my $type = $event->type;
         my $tag = (my $target = $event->target)->nodeName;
         if ($type eq 'click' && $tag eq 'A') {
                # ...
         }
         # etc.
  });

C<default_event_handler> without any arguments will return the currently 
assigned coderef. With an argument it will return the old one after
assigning the new one.

HTML::DOM::Node's C<dispatchEvent> method triggers the appropriate event 
listeners, but does B<not> call any default actions associated with it.
The return value is a boolean that indicates whether the default action
should be taken.

H:D:Node's C<trigger_event> method will trigger the event for real. It will
call C<dispatchEvent> and, provided it returns true, will call the default
event handler.

The C<event_attr_handler> can be used to assign a coderef that will turn
text assigned to an event attribute (e.g., C<onclick>) into a listener. The
arguments to the routine will be (0) the element, (1) the name (aka
type) of 
the event (without the initial 'on') and (2) the value of the attribute. As 
with C<default_event_handler>, you
can replace an existing handler with a new one, in which case the old
handler is returned. If you call this method without arguments, it returns
the current handler. Here is an example of its use, that assumes that
handlers are Perl code:

  $dom_tree->event_attr_handler(sub {
          my($elem, $name, $code) = @_;
          my $sub = eval "sub { $code }";
          return sub {
                  my($event) = @_;
                  local *_ = \$elem;
                  my $ret = &$sub;
                  defined $ret and !$ret and
                          $event->preventDefault;
          };
  });

The event attribute handler will be called whenever an element attribute 
whose name
begins with 'on' (case-tolerant) is modified.

=cut

# ---------- NON-DOM EVENT METHODS -------------- #

sub event_attr_handler {
	my $old = $_[0]->{_HTML_DOM_event_attr_handler};
	$_[0]->{_HTML_DOM_event_attr_handler} = $_[1]  if @_ > 1;
	$old;
}
sub default_event_handler {
	my $old = $_[0]->{_HTML_DOM_default_event_handler};
	$_[0]->{_HTML_DOM_default_event_handler} = $_[1] if @_ > 1;
	$old;
}




# ---------- NODE LIST HELPER METHODS -------------- #

sub _modified { # tells all it's magic nodelists that they're stale
	my $list = $_[0]{_HTML_DOM_node_lists};
	my $list_is_stale;
	for (@$list) {
		defined() ? $_->_you_are_stale : ++$list_is_stale
	}
	if($list_is_stale) {
		@$list = grep defined, @$list;
		weaken $_ for @$list;
	}
}

sub _register_magic_node_list { # adds the node list to the list of magic
                                # node lists that get notified  automatic-
                                # ally whenever the doc structure changes
	push @{$_[0]{_HTML_DOM_node_lists}}, $_[1];
	weaken $_[0]{_HTML_DOM_node_lists}[-1];
}



1;
__END__

=head1 CLASSES AND DOM INTERFACES

Here are the inheritance hierarchy of HTML::DOM's various classes and the
DOM interfaces those classes implement. The Classes in the left column all
begin with 'HTML::', which is omitted for brevity. Items in brackets have
not yet been implemented.

  Class Inheritance Hierarchy             Interfaces
  ---------------------------             ----------
  
  DOM::Exception                          DOMException, EventException
  DOM::Implementation                     DOMImplementation
  Element
      DOM::Node                           Node, EventTarget
          DOM::DocumentFragment           DocumentFragment
          DOM                             Document, HTMLDocument,
                                            DocumentEvent
          DOM::CharacterData              CharacterData
              DOM::Text                   Text
              DOM::Comment                Comment
          DOM::Element                    Element, HTMLElement
              DOM::Element::HTML          HTMLHtmlElement
              DOM::Element::Head          HTMLHeadElement
              DOM::Element::Link          HTMLLinkElement
              DOM::Element::Title         HTMLTitleElement
              DOM::Element::Meta          HTMLMetaElemen
              DOM::Element::Base          HTMLBaseElement
              DOM::Element::IsIndex       HTMLIsIndexElement
              DOM::Element::Style         HTMLStyleElement
              DOM::Element::Body          HTMLBodyElement
             [DOM::Element::Form          HTMLFormElement]
             [DOM::Element::Select        HTMLSelectElement]
             [DOM::Element::OptGroup      HTMLOptGroupElement]
             [DOM::Element::Option        HTMLOptionElement]
             [DOM::Element::Input         HTMLInputElement]
             [DOM::Element::TextArea      HTMLTextAreaElement]
             [DOM::Element::Button        HTMLButtonElement]
             [DOM::Element::Label         HTMLLabelElement]
             [DOM::Element::FieldSet      HTMLFieldSetElement]
             [DOM::Element::Legend        HTMLLegendElement]
             [DOM::Element::UL            HTMLUListElement]
             [DOM::Element::OL            HTMLOListElement]
             [DOM::Element::DL            HTMLDListElement]
             [DOM::Element::Dir           HTMLDirectoryElement]
             [DOM::Element::Menu          HTMLMenuElement]
             [DOM::Element::LI            HTMLLIElement]
             [DOM::Element::Div           HTMLDivElement]
             [DOM::Element::P             HTMLParagraphElement]
             [DOM::Element::Heading       HTMLHeadingElement]
             [DOM::Element::Quote         HTMLQuoteElement]
             [DOM::Element::Pre           HTMLPreElement]
             [DOM::Element::Br            HTMLBRElement]
             [DOM::Element::BaseFont      HTMLBaseFontElement]
             [DOM::Element::Font          HTMLFontElement]
             [DOM::Element::HR            HTMLHRElement]
             [DOM::Element::Mod           HTMLModElement]
             [DOM::Element::A             HTMLAnchorElement]
             [DOM::Element::Img           HTMLImageElement]
             [DOM::Element::Object        HTMLObjectElement]
             [DOM::Element::Param         HTMLParamElement]
             [DOM::Element::Applet        HTMLAppletElement]
             [DOM::Element::Map           HTMLMapElement]
             [DOM::Element::Area          HTMLAreaElement]
             [DOM::Element::Script        HTMLScriptElement]
             [DOM::Element::Table         HTMLTableElement]
             [DOM::Element::Caption       HTMLTableCaptionElement]
             [DOM::Element::TableColumn   HTMLTableColElement]
             [DOM::Element::TableSection  HTMLTableSectionElement]
             [DOM::Element::TR            HTMLTableRowElement]
             [DOM::Element::TableCell     HTMLTableCellElement]
             [DOM::Element::FrameSet      HTMLFrameSetElement]
             [DOM::Element::Frame         HTMLFrameElement]
             [DOM::Element::IFrame        HTMLIFrameElement]
  DOM::NodeList                           NodeList
  DOM::NodeList::Magic                    NodeList
  DOM::NamedNodeMap                       NamedNodeMap
  DOM::Attr                               Node, Attr
  DOM::Collection                         HTMLCollection
  DOM::Event                              Event

Although HTML::DOM::Node inherits from HTML::Element, the interface is not
entirely compatible, so don't rely on any HTML::Element methods.

The EventListener interface is not implemented by HTML::DOM, but is 
supported.
See L</EVENT HANDLING>, above.

=head1 IMPLEMENTATION NOTES

=over 4

=item *

Node attributes are accessed via methods of the same name. When the method
is invoked, the current value is returned. If an argument is supplied, the
attribute is set (unless it is read-only) and its old value returned.

=item *

Where the DOM spec. says to use null, undef or an empty list is used.

=item *

Instead of UTF-16 strings, HTML::DOM uses Perl's Unicode strings (which
happen to be stored as UTF-8 internally). The only significant difference
this makes is to C<length>, C<substringData> and other methods of Text and
Comment nodes. These methods behave in a Perlish way (i.e., the offsets and
lengths are specified in Unicode characters, not in UTF-16 bytes). The
alternate methods C<length16>, C<substringData16> I<et al.> use UTF-16 for 
offsets
and are standards-compliant in that regard (but the string returned by
C<substringData> is still a regular Perl string).

=begin for me

# ~~~ These need to be documented in the man pages for Comment and Text
C<length16>, C<substringData16>
C<insertData16>, C<deleteData16>, C<replaceData16> and C<splitText16>.

=end for me

=item *

Each method that returns a NodeList will return a NodeList
object in scalar context, or a simple list in list context. You can use
the object as an array ref in addition to calling its C<item> and 
C<length> methods.

=head1 PREREQUISITES

Definitely perl 5.6.0 or later (only tested with 5.8.7 and 5.8.8)

HTML::TreeBuilder and HTML::Element (both part of the HTML::Tree
distribution) (tested with 3.23)

URI.pm (tested with 1.35)

HTTP::Headers::Util is required if you pass an argument to the C<cookie>
method after passing an HTTP::Response and a cookie jar to the constructor 
(in which case you most certainly already have 
HTTP::Headers::Util :-). 
(tested with 1.13)

=head1 BUGS

I really don't know what will happen if a element handler goes and deletes
parent elements of the element for which the handler is called.

Exceptions thrown within event listeners (handlers) are currently ignored
altogether.

C<hasFeature> returns true for 'HTML' and '1.0', even though the Level-1
HTML interfaces are not fully implemented yet.

HTML::DOM::Element's C<normalize> method does not currently work properly.

HTML::DOM::Node's C<cloneNode> method does not currently work properly with
elements.

B<To report bugs,> please e-mail the author.

=head1 AUTHOR, COPYRIGHT & LICENSE

Copyright (C) 2007 Father Chrysostomos

  $text = new HTML::DOM ->createTextNode('sprout');
  $text->appendData('@');
  $text->appendData('cpan.org');
  print $text->data, "\n";

This program is free software; you may redistribute it and/or modify
it under the same terms as perl.

=head1 SEE ALSO

L<HTML::DOM::Exception>, L<HTML::DOM::Node>, L<HTML::DOM::Event>

L<HTML::Tree>, L<HTML::TreeBuilder>, L<HTML::Element>, L<HTML::Parser>,
L<LWP>, L<WWW::Mechanize>, L<HTTP::Cookies>

The DOM Level 1 specification at S<L<http://www.w3.org/TR/REC-DOM-Level-1>>

The DOM Level 2 Core specification at
S<L<http://www.w3.org/TR/DOM-Level-2-Core>>

The DOM Level 2 Events specification at
S<L<http://www.w3.org/TR/DOM-Level-2-Events>>

etc.
