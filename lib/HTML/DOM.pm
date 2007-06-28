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

our $VERSION = '0.001';
our @ISA = 'HTML::DOM::Node';

require         HTML::DOM::Comment;
require HTML::DOM::DocumentFragment;
require   HTML::DOM::Implementation;
require         HTML::DOM::Element;
require HTML::DOM::NodeList::Magic;
require             HTML::DOM::Text;
require             HTML::TreeBuilder;


=head1 NAME

HTML::DOM - A Perl implementation of the HTML Document Object Model

=head1 VERSION

Version 0.001 (alpha)

B<WARNING:> This module is still at an experimental stage. Only a few
features have been implemented so far. The API is subject to change without
notice.

=head1 SYNOPSIS

  use HTML::DOM;

  my $dom_tree = new HTML::DOM; # empty tree
  $dom_tree->parse_file($filename);

  $dom_tree->getElementsByTagName('body')->[0]->appendChild(
           $dom_tree->createElement('input')
  )

  # print $dom_tree->documentElement->outerHTML, "\n";
  # (doesn't work yet)

=head1 DESCRIPTION

This module implements the HTML Document Object Model by extending the
HTML::Tree modules. The HTML::DOM class serves both as an HTML parser and
as the document class.

=head1 METHODS

=over 4

=item $tree = new HTML::DOM

This class method constructs and returns a new HTML::DOM object.

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
			$parent->splice_content(-1,1,$parent->
				ownerDocument->createTextNode($text));
		 },
	 )
	   ->ignore_ignorable_whitespace(0); # stop eof()'s cleanup
	                                       # from changing the
	$tb->unbroken_text(1); # necessary, con-  # script handler's view 
	                     # sidering what        # of the tree
	                   # _tweak_~text does
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
  # as_text doesn't work yet

=cut

sub elem_handler {
	my ($self,$elem_name,$sub) = @_;
	my $doc_elem = ($self->content_list)[0];
	weaken $doc_elem;
	$doc_elem->{"_tweak_$elem_name"} = sub {
		&$sub($self, $_[0]);
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
		$p->parse($$self{_HTML_DOM_write_buffer});
		$p->eof;
		delete $$self{_HTML_DOM_write_buffer};
	}
}



=item $tree->parse_file($file)

=item $tree->parse(...)

=item $tree->eof()

These three methods simply
call HTML::TreeBuilder's methods with the same name (q.v., and see also
HTML::Element), but note that
C<parse_file> and C<eof> may only be called once for each HTML::DOM object
(since it deletes its parser when it no longer needs it). Similarly,
C<parse> may not be called after C<eof>.

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
	(my $a = (shift->content_list)[0])
		->eof(@_);
	 $a	->elementify;
}

=back

=cut



#-------------- DOM STUFF (CORE) ---------------- #

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

sub write { # ~~~ this currently only works properly when the tree is
            #     still growing
	no warnings 'uninitialized';
	$_[0]{_HTML_DOM_write_buffer} .= $_[1];
	return # ~~~ check what this is supposed to return
}

sub body { # ~~~ this needs to return the outermost frameset element if
            #     there is one (if the frameset is always the second child
            #     of <html>, then it already does).
	($_[0]->documentElement->content_list)[1];
}

# ---------- OVERRIDDEN NODE METHODS -------------- #

sub ownerDocument {} # empty list
sub nodeName { '#document' }
{ no warnings 'once'; *nodeType = \& DOCUMENT_NODE; }


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
DOM interfaces those classes implement:

  HTML::DOM::Exception                 DOMException
  HTML::DOM::Implementation            DOMImplementation
  HTML::Element
      HTML::DOM::Node                  Node
          HTML::DOM::DocumentFragment  DocumentFragment
          HTML::DOM                    Document
          HTML::DOM::CharacterData     CharacterData
              HTML::DOM::Text          Text
              HTML::DOM::Comment       Comment
          HTML::DOM::Element           Element
  HTML::DOM::NodeList                  NodeList
  HTML::DOM::NodeList::Magic           NodeList
  HTML::DOM::NamedNodeMap              NamedNodeMap
  HTML::DOM::Attr                      Node, Attr

Later, HTML::DOM::Element will have subclasses for the various different
element types.

Although HTML::DOM::Node inherits from HTML::Element, methods of
HTML::Element that make a distinction between text and elements either will
not work or will work slightly differently.

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

Definitely perl 5.6.0 or later (only tested with 5.8.8)

HTML::TreeBuilder and HTML::Element (both part of the HTML::Tree
distribution) (tested with 3.23)

=head1 BUGS

The C<write> method currently only works when the tree is in the process 
of being
built.

I really don't know what will happen if a element handler goes and deletes
parent elements of the element for which the handler is called.

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

=over 4

L<HTML::DOM::Exception>

L<HTML::DOM::Node>

L<HTML::Tree>, L<HTML::TreeBuilder>, L<HTML::Element>, L<HTML::Parser>

The DOM Level 1 specification at L<http://www.w3.org/TR/REC-DOM-Level-1>

The other DOM specs, the links for which I still need to get.
