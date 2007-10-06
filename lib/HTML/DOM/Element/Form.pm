# suppress some nasty @INC warnings:
eval 'pack' . 'age HTML::Form; pack' . 'age HTML::Form::Input';

package HTML::DOM::Element::Form;

use strict;
use warnings;

no Carp();
use URI;

require HTML::DOM::Element;
require HTML::DOM::NodeList::Magic;
#require HTML::DOM::Collection::Elements;

our $VERSION = '0.008';
our @ISA = qw'HTML::DOM::Element HTML::Form';

use overload fallback => 1,
'@{}' => sub { shift->elements },
'%{}' => sub {
	my $self = shift;
	$self->isa(scalar caller) || caller->isa('HTML::TreeBuilder')
		and return $self;
	$self->elements;
};

my %elem_elems = (
	input    => 1,
	button   => 1,
	select   => 1,
	textarea => 1,
);
sub elements { # ~~~ I need to make this cache the resulting collection obj
	my $self = shift;
	if (wantarray) {
		return grep $elem_elems{tag $_}, $self->descendants;
	}
	else {
		my $collection = HTML::DOM::Collection::Elements->new(
		my $list = HTML::DOM::NodeList::Magic->new(
		    sub { grep $elem_elems{tag $_}, $self->descendants }
		));
		$self->ownerDocument-> _register_magic_node_list($list);
		$collection;
	}
}

sub length        { shift->elements              -> length }
sub name          { no warnings; shift->attr( name           => @_) . ''  }
sub acceptCharset { shift->attr('accept-charset' => @_)    }
sub action        {
	my $self = shift;
	(new_abs URI
		$self->attr('action' => @_),
		$self->ownerDocument->base)
	 ->as_string
}
sub enctype       {
	my $ret = shift->attr('enctype'        => @_);
	defined $ret ? $ret : 'application/x-www-form-urlencoded'
}
sub method        {
	my $ret = shift->attr('method'         => @_);
	defined $ret ? $ret : 'GET'
}
sub target        { shift->attr('target'         => @_)    }

sub submit { shift->trigger_event('submit') }

sub reset { $_->reset for shift->elements }

# ------ HTML::Form compatibility methods ------ #

sub AUTOLOAD { # so we don't have to load it unnecessarily
	require HTML::Form;
	VERSION HTML::Form 1.054; # ~~~ to be increased when my patch is
                                  #     applied and a newer version
	                          #     is released
	my $meth = 'HTML::Form::' . (our $AUTOLOAD =~ /([^:]+)\z/)[0];

	shift->$meth(@_);
}
sub DESTROY {}

sub inputs {
	my @ret;
	my %pos;
	for(shift->elements) {
	  next if (my $tag = tag $_) eq 'button'; # HTML::Form doesn't deal
	                                          # with <button>s.
	  if(lc $_->attr('type') eq 'radio') {
	    my $name = name $_;
	    exists $pos{$name} ? push @{$ret[$pos{$name}]}, $_
	      :( push(@ret, [$_]),
	          $pos{$name} = $#ret );
	    next
	  }
	  push @ret, $tag eq 'select'
	    ? $_->attr('multiple')
	      ? $_->find('option')
	      : scalar $_->options
	    : $_
	}
	map ref $_ eq 'ARRAY' ? new HTML::DOM::NodeList::Radio $_ : $_,
		@ret
}

sub click  # 22/Sep/7: stolen from HTML::Form and modified (particularly
{          # the last line) so I don't have to mess with Hook::LexWrap
    my $self = shift;
    my $name;
    $name = shift if (@_ % 2) == 1;  # odd number of arguments

    # try to find first submit button to activate
    for ($self->inputs) {
        next unless $_->type =~ /^(?:submit|image)\z/;
        next if $name && $_->name ne $name;
	next if $_->disabled;
	$_->click($self, @_);return
    }
    Carp::croak("No clickable input with name $name") if $name;
    $self->trigger_event('submit');
}

# ~~~ These few can be deleted when/if my patch for HTML::Form is applied:

sub find_input
{
    package
	HTML::Form; # so caller tricks work
    my($self, $name, $type, $no) = @_;
    if (wantarray) {
	my @res;
	my $c;
	for ($self->inputs) {
	    if (defined $name) {
		next unless defined(my $n = $_->name);
		next if $name ne $n;
	    }
	    next if $type && $type ne $_->type;
	    $c++;
	    next if $no && $no != $c;
	    push(@res, $_);
	}
	return @res;
	
    }
    else {
	$no ||= 1;
	for ($self->inputs) {
	    if (defined $name) {
		next unless defined(my $n = $_->name);
		next if $name ne $n;
	    }
	    next if $type && $type ne $_->type;
	    next if --$no;
	    return $_;
	}
	return undef;
    }
}

sub make_request
{
    package
	HTML::Form; # so caller tricks work
    my $self = shift;
    my $method  = uc $self->method;
    my $uri     = $self->action;
    my $enctype = lc $self->enctype;
    my @form    = $self->form;

    if ($method eq "GET") {
	require HTTP::Request;
	$uri = URI->new($uri, "http");
	$uri->query_form(@form);
	return HTTP::Request->new(GET => $uri);
    }
    elsif ($method eq "POST") {
	require HTTP::Request::Common;
	return HTTP::Request::Common::POST($uri, \@form,
					   Content_Type => $enctype);
    }
    else {
	Carp::croak("Unknown method '$method'");
    }
}

sub form
{
    package
	HTML::Form; # so caller tricks work
    my $self = shift;
    map { $_->form_name_value($self) } $self->inputs;
}




package HTML::DOM::NodeList::Radio; # solely for HTML::Form compatibility
                                    # Usually ::Input is used, but ::Radio
                                    # is for a set of radio buttons.
use Carp 'croak';
require HTML::DOM::NodeList;

our $VERSION = '0.008';
our @ISA = qw'HTML::DOM::NodeList HTML::Form::Input';

sub type { 'radio' }

sub name { 
	my $ret = (my $self = shift)->item(0)->attr('name');
	if (@_) {
		$self->item($_)->attr(name=>@_) for 0..$self->length-1;
	}
	$ret
}

sub value { # ~~~ do case-folding and what-not, as in HTML::Form::ListInput
	my $self = shift;

	my $checked_elem;
	for (0..$self->length-1) {
		my $btn = $self->item($_);
		$btn->checked and
			$checked_elem = $btn, last;
	}

	if (@_) { for (0..$self->length-1) {
		my $btn = $self->item($_);
		$_[0] eq $btn->attr('value') and
		  $btn->disabled && croak(
		    "The value '$_[0]' has been disabled for field '${\
		     $self->name}'"
		  ),
		  $btn->checked(1),
		  last;
	}}

	$checked_elem && $checked_elem->attr('value')
}

sub possible_values {
	my $self = shift;
	map $self->item($_)->attr('value'), 0..$self->length-1
}

sub disabled {
	my $self = shift;
	for(@$self) {
		$_->disabled or return 0
	}
	return 1
}

sub AUTOLOAD { # so we don't have to load it unnecessarily
	require HTML::Form;
	VERSION HTML::Form 1.054; # ~~~ to be increased when my patch is
                                  #     applied and a newer version
	                          #     is released
	my $meth = 'HTML::Form::Input::'.(our $AUTOLOAD =~ /([^:]+)\z/)[0];
#Test::More::diag Carp::longmess('aaaaa') , ' ',ref $_[0] if $1 eq 'item';
	shift->$meth(@_);
}
*DESTROY = \&HTML::DOM::Element::Form::DESTROY;

sub form_name_value
# ~~~ to be deleted when my patch to HTML::Form is applied
{
    package
	HTML::Form::Input;
    my $self = shift;
    my $name = $self->name;
    return unless defined $name && length $name;
    return if $self->disabled;
    my $value = $self->value;
    return unless defined $value;
    return ($name => $value);
}


package HTML::DOM::Collection::Elements;

use strict;
use warnings;

use Scalar::Util 'weaken';

our $VERSION = '0.008';

require HTML::DOM::Collection;
our @ISA = 'HTML::DOM::Collection';

# Internals: \[$nodelist, $tie]

# Field constants:
sub nodelist(){0}
sub tye(){1}
sub seen(){2}     # whether this key has been seen
sub position(){3} # current (array) position used by NEXTKEY
sub ids(){4}      # whether we are iterating through ids
{ no warnings 'misc';
  undef &nodelist; undef &tye; undef &seen; undef &position;
}

sub namedItem {
	my($self, $name) = @_;
	my $list = $$self->[nodelist];
	my $elem;
	my @list;
	for(0..$list->length - 1) {
		no warnings 'uninitialized';
		push @list, $elem if 
			($elem = $list->item($_))->id eq $name
			  or
			$elem->attr('name') eq $name;
		if(@list > 1) {
			no strict 'subs'; # it's buggy
			require(HTML::DOM::NodeList),
			weaken $list,
			# ~~~ Perhaps this should cache the new nodelist
			#     and return the same one each item. (Incident-
			#     ally, Firefox returns the same one but Safari
			#     makes a new one each time.)
			my $ret = HTML::DOM::NodeList->new(sub {
				grep $_->id eq $name ||
				     $_->attr('name') eq $name, @$list;
			});
			$ret->[0]->type eq 'radio' and
#				require('HTML::DOM::Element::Form'),
				bless $ret, 'HTML::DOM::NodeList::Radio';
			return $ret;
		}
	}
	@list ? $list[0] :()
}



# ----------------- Docs ----------------- #

=head1 NAME

HTML::DOM::Element::Form - A Perl class for representing 'form' elements in an HTML DOM tree

=head1 SYNOPSIS

  use HTML::DOM;
  $doc = HTML::DOM->new;
  $elem = $doc->createElement('form');

  $elem->method('GET') # set attribute
  $elem->method;       # get attribute
  $elem->enctype;
  $elem->tagName;
  # etc

=head1 DESCRIPTION

This class implements 'form' elements in an HTML::DOM tree. It 
implements the HTMLFormElement DOM interface and inherits from 
L<HTML::DOM::Element> (q.v.).

A form object can be used as a hash or an array, to access its input 
fields, so S<<< C<< $form->[0] >> >>> and S<<< C<< $form->{name} >> >>>
are shorthand for
S<<< C<< $form->elements->[0] >> >>> and
S<< C<<< $form->elements->{name} >>> >>, respectively.

This class also inherits from L<HTML::Form>, but is not entirely compatible
with its interface. See L</HTML::Form COMPATIBILITY>, below.

=head1 DOM METHODS

In addition to those inherited from HTML::DOM::Element and 
HTML::DOM::Node, this class implements the following DOM methods:

=over 4

=item elements

Returns a collection (L<HTML::DOM::Collection::Elements> object) in scalar 
context,
or a list in list context, of all the input
fields this form contains. This differs slightly from the C<inputs> method
(part of the HTML::Form interface) in that it includes 'button' elements,
whereas C<inputs> does not (though it does include 'input' elements with
'button' for the type).

=item length

Same as C<< $form->elements->length >>.

=item name

=item acceptCharset

=item action

=item enctype

=item method

=item target

Each of these returns the corresponding HTML attribute (C<acceptCharset>
corresponds to the 'accept-charset' attribute). If you pass an
argument, it will become the new value of the attribute, and the old value
will be returned.

=item submit

This triggers the form's 'submit' event, calling the default event handler
(see L<HTML::DOM/EVENT HANDLING>). It is up to the default event handler to
take any further action. The form's C<make_request> method (inherited from
L<HTML::Form>) may come in handy.

This method is actually just short for $form->trigger_event('submit'). (See
L<HTML::DOM::Node/Other Methods>.)

=item reset

(Not yet implemented)

=back

=head1 WWW::Mechanize COMPATIBILITY

In order to work with L<WWW::Mechanize>, this module inherits from, and is 
partly compatible with the
interface of, L<HTML::Form>.

HTML::Form's class methods B<do not> work with this module. If you call
C<< HTML::DOM::Element::Form->parse >>, for instance, you will wreak havoc.

The C<dump> and C<try_others> methods do not currently work.

The C<click> method behaves differently from HTML::Form's, in that it does
not call C<make_request>, but triggers a 'click' event if there is a
button to click, or a 'submit' event otherwise.

The C<method>, C<action>, C<enctype>, C<attr>, C<inputs>, C<find_input>,
C<value>, C<param>, C<make_request> and C<form>
methods should
work as expected.

=head1 SEE ALSO

L<HTML::DOM>

L<HTML::DOM::Element>

L<HTML::DOM::Collection::Elements>

L<HTML::Form>

=cut


# ------- HTMLSelectElement interface ---------- #

package HTML::DOM::Element::Select;
our $VERSION = '0.008';
our @ISA = 'HTML::DOM::Element';

sub type      { shift->attr('type') }
sub selectedIndex   {
	my $self = shift;
	my $ret;
	if(!defined $self->{_HTML_DOM_sel_index}) {
		my $x=0;
		# ~~~ I can optimise this by using $self->traverse since
		#     I don't need the rest of the list once I've found
		#     a selceted item.
		for($self->options) {
			$_->selected and
				@_ || ($self->{_HTML_DOM_sel_index} = $x),
				$ret = $x,
				last;
			$x++;
		}
		defined $ret or
			$ret = -1,
			@_ || ($self->{_HTML_DOM_sel_index} = -1);
	}
	else {
		$ret = $self->{_HTML_DOM_sel_index}
	}
	@_ and $self->{_HTML_DOM_sel_index} = $_[0],
	       ($self->options)[$_[0]]->selected(1);
	return $ret;
}
sub _reset_sel_index { delete shift->{_HTML_DOM_sel_index} }
sub value   { shift->options->value(@_) }
sub length { scalar(()= shift->options ) }
sub form           { (shift->look_up(_tag => 'form'))[0] || () }
sub options { # ~~~ I need to make this cache the resulting collection obj
	my $self = shift;
	if (wantarray) {
		return grep tag $_ eq 'option', $self->descendants;
	}
	else {
		my $collection = HTML::DOM::Collection::Options->new(
		my $list = HTML::DOM::NodeList::Magic->new(
		    sub { grep tag $_ eq 'option', $self->descendants }
		));
		$self->ownerDocument-> _register_magic_node_list($list);
		$collection;
	}
}
sub disabled  { shift->attr( disabled => @_) }
sub multiple  { shift->attr( multiple => @_) }
*name = \&HTML::DOM::Element::Form::name;
sub size      { shift->attr( size => @_) }
sub tabIndex  { shift->attr( tabindex => @_) }

# ~~~sub add {
# ~~~sub remove {

sub blur { shift->trigger_event('blur') }
sub focus { shift->trigger_event('focus') }


package HTML::DOM::Collection::Options;

use strict;
use warnings;

our $VERSION = '0.008';

use Carp 'croak';

require HTML::DOM::Collection;
our @ISA = qw'HTML::DOM::Collection HTML::Form::Input';

sub type { 'option' }
sub possible_values {
	map $_->value, @{+shift};
}

sub value { # ~~~ do case-folding and what-not, as in HTML::Form::ListInput
	my $self = shift;

	my $sel_elem;
	for (0..$self->length-1) {
		my $opt = $self->item($_);
		$opt->selected and
			$sel_elem = $opt, last;
	}

	if (@_) { for (0..$self->length-1) {
		my $opt = $self->item($_);
		my $v = $opt->value;
		$_[0] eq $v and
		  $opt->disabled && croak(
		    "The value '$_[0]' has been disabled for field '${\
		     $self->name}'"
		  ),
		  $opt->selected(1),
		  last;
	}}

	!defined $sel_elem # Shouldn't happen in well-formed documents, but
	    and $sel_elem  # how many documents are well-formed?
	     = $self->item(0);

	$sel_elem->value;
}

sub name {
	shift->item(0)->look_up(_tag => 'select')->name
}

sub disabled {
	(my $self = shift)->item(0)->look_up(_tag => 'select')->disabled 
		and return 1;
	for (@$self) {
		$_->disabled || return 0;
	}
	return 1
}

*AUTOLOAD = \& HTML::DOM::NodeList::Radio::AUTOLOAD;
*DESTROY = \&HTML::DOM::Element::Form::DESTROY;

sub form_name_value
# ~~~ to be deleted when my patch to HTML::Form is applied
{
    package
	HTML::Form::Input;
    my $self = shift;
    my $name = $self->name;
    return unless defined $name && length $name;
    return if $self->disabled;
    my $value = $self->value;
    return unless defined $value;
    return ($name => $value);
}


# ------- HTMLOptGroupElement interface ---------- #

package HTML::DOM::Element::OptGroup;
our $VERSION = '0.008';
our @ISA = 'HTML::DOM::Element';

sub label  { shift->attr( label => @_) }
*disabled = \&HTML::DOM::Element::Select::disabled;


# ------- HTMLOptionElement interface ---------- #

package HTML::DOM::Element::Option;
our $VERSION = '0.008';
our @ISA = qw'HTML::DOM::Element HTML::Form::Input';

use Carp 'croak';

*form = \&HTML::DOM::Element::Select::form;
sub defaultSelected   { shift->attr( selected => @_) }

sub text { 
	(shift->firstChild or return '')->data
}

sub index {
	my $self = shift;
	my $indx = 0;
	my @options = (my $sel = $self->look_up(_tag => 'select'))
		->options;
	for(@options){
		last  if $self == $_;
		$indx++;
	}
	# This should not happen, unless the tree is horribly mangled:
	defined $indx or die new HTML::DOM::Exception 
	HTML::DOM::Exception::HIERARCHY_REQUEST_ERR,
	"It seems this option element is not a descendant of its ancestor."
	;
	if ( @_ ) {{
		my $new_indx= shift;
		last if $new_indx == $indx;
		if ($new_indx == 0) {
			$sel->insertBefore($self, $options[0]);
			last;
		}
		$options[$new_indx-1]->parentNode->insertBefore(
			$self, $options[$new_indx-1]->nextSibling
		);
	}}
	$indx;
}

*disabled = \&HTML::DOM::Element::Select::disabled;
*label = \&HTML::DOM::Element::OptGroup::label;

sub selected {
	my $self = shift;
	my $ret;

	if(!defined $self->{_HTML_DOM_sel}) {
		$ret = $self->attr('selected')||0;
	}
	else {
		$ret = $self->{_HTML_DOM_sel}
	}
	if(@_ && !$ret != !$_[0]) {
		(my $sel = $self->look_up(_tag => 'select'))
			->_reset_sel_index;
		if($sel->multiple) {
			$self->{_HTML_DOM_sel} = shift;
		}
		elsif($_[0]) { # You can't deselect the only selected
		               # option if exactly one option must be 
		               # selected at any given time.
			$self->{_HTML_DOM_sel} = shift;
			$_ != $self and $_->selected(0) for $sel->options;
		}
	}
	$ret
}

sub value { # ~~~ do case-folding and what-not, as in HTML::Form::ListInput

	my $self = shift;
	my $ret;

	if(caller =~ /^(?:HTML::Form(?:::Input)?|WWW::Mechanize)\z/) {
		# ~~~ I can optimise this to call ->value once.
		$ret = $self->selected ? $self->value : undef;
		@_ and defined $_[0]
			? $_[0] eq $self->value
				? $self->selected(1)
				: croak "Invalid value '$_[0]' for option "
					. $self->name
			: $self->selected(0);
		return $ret;
	}

	defined($ret = $self->attr(value => @_)) or
		$ret = $self->text;

	return $ret;
}

sub type() { 'option' }

sub possible_values {
	(undef, shift->value)
}

sub name {
	shift->look_up(_tag => 'select')->name
}

*AUTOLOAD = \& HTML::DOM::NodeList::Radio::AUTOLOAD;
*DESTROY = \&HTML::DOM::Element::Form::DESTROY;

sub form_name_value
# ~~~ to be deleted when my patch to HTML::Form is applied
{
    package
	HTML::Form::Input;
    my $self = shift;
    my $name = $self->name;
    return unless defined $name && length $name;
    return if $self->disabled;
    my $value = $self->value;
    return unless defined $value;
    return ($name => $value);
}


# ------- HTMLInputElement interface ---------- #

package HTML::DOM::Element::Input;
our $VERSION = '0.008';
our @ISA = qw'HTML::DOM::Element';

use Carp 'croak';

sub defaultValue   { shift->attr( value => @_) }
sub defaultChecked { shift->attr( checked => @_) }
*form = \&HTML::DOM::Element::Select::form;
sub accept         { shift->attr( accept => @_) }
sub accessKey      { shift->attr( accesskey => @_) }
sub align          { shift->attr( align => @_) }
sub alt            { shift->attr( alt => @_) }
sub checked        {
	my $self = shift;
	my $ret;
	if(!defined $self->{_HTML_DOM_checked}) {
		$ret = $self->defaultChecked
	}
	else {
		$ret = $self->{_HTML_DOM_checked}
	}
	@_ and $self->{_HTML_DOM_checked} = shift;
	return $ret;
}
*disabled = \&HTML::DOM::Element::Select::disabled;
sub maxLength { shift->attr( maxlength => @_) }
*name = \&HTML::DOM::Element::Form::name;
sub readOnly  { shift->attr( readonly => @_) }
*size = \&HTML::DOM::Element::Select::size;
sub src       { shift->attr( src => @_) }
*tabIndex = \&HTML::DOM::Element::Select::tabIndex;
sub type      {
	my $ret = shift->attr('type');
	return defined $ret ? lc $ret : 'text'
}
sub useMap    { shift->attr( usemap => @_) }
sub value        {
	my $self = shift;
	my($ret,$type);

	if(caller =~ /^(?:HTML::Form(?:::Input)?|WWW::Mechanize)\z/ and
	    ($type = $self->type) =~ /^(?:button|reset)\z/ && return ||
	     $type eq 'checkbox') {
		# ~~~ Do case-folding as in HTML::Input::ListInput
		my $value = $self->value;
		length $value or $value = 'on';
		$ret = $self->checked
			? $value
			: undef;
		@_ and defined $_[0]
			? $_[0] eq $value
				? $self->checked(1)
				: croak
				   "Invalid value '$_[0]' for checkbox "
				   . $self->name
			: $self->checked(0);
		return $ret;
	}

# ~~~ shouldn't I make sure that modifying the value attribute 
#     (=defaultValue) leaves the value alone, even if the value has not
#     yet been accessed?
	if(!defined $self->{_HTML_DOM_value}) {
		$ret = $self->defaultValue
	}
	else {
		$ret = $self->{_HTML_DOM_value}
	}
	@_ and $self->{_HTML_DOM_value} = shift;
	no warnings;
	return "$ret";
}

*blur = \&HTML::DOM::Element::Select::blur;
*focus = \&HTML::DOM::Element::Select::focus;
sub select { shift->trigger_event('select') }
sub click { for(shift){
	my(undef,$x,$y) = @_;
	defined or $_ = 1  for $x, $y;
	local($$_{_HTML_DOM_clicked}) = [$x,$y];
	$_->trigger_event('click');
}}

sub possible_values {
	$_[0]->type eq 'checkbox' ? wantarray ? (undef, shift->value) : 2
	: ()
}
sub form_name_value
{
    my $self = shift;
    my $type = $self->type;
    if ($type =~ /^(image|submit)\z/) {
        return unless $self->{_HTML_DOM_clicked};
        if($1 eq 'image') {
            my $name = $self->name;
            $name = length $name ? "$name." : '';
            return "${name}x" => $self->{_HTML_DOM_clicked}[0],
                   "${name}y" => $self->{_HTML_DOM_clicked}[1]
        }
    }
    require HTML::Form;
    return $type eq 'file'
#        ? $self->HTML::Form::FileInput::form_name_value(@_)
#        : $self->HTML::Form::Input::form_name_value(@_);
        ? $self->HTML_Form_FileInput_form_name_value(@_)
        : $self->HTML_Form_Input_form_name_value(@_);
}

sub HTML_Form_Input_form_name_value
# ~~~ to be deleted when my patch to HTML::Form is applied
{
    package
	HTML::Form::Input;
    my $self = shift;
    my $name = $self->name;
    return unless defined $name && length $name;
    return if $self->disabled;
    my $value = $self->value;
    return unless defined $value;
    return ($name => $value);
}

sub HTML_Form_FileInput_form_name_value {
# ~~~ hame sere
    package
	HTML::Form::ListInput;
    my($self, $form) = @_;
    return $self-> HTML_Form_Input_form_name_value($form)
	if uc $form->method ne "POST" ||
	   lc $form->enctype ne "multipart/form-data";

    my $name = $self->name;
    return unless defined $name;
    return if $self->{disabled};

    my $file = $self->file;
    my $filename = $self->filename;
    my @headers = $self->headers;
    my $content = $self->content;
    if (defined $content) {
	$filename = $file unless defined $filename;
	$file = undef;
	unshift(@headers, "Content" => $content);
    }
    elsif (!defined($file) || length($file) == 0) {
	return;
    }

    # legacy (this used to be the way to do it)
    if (ref($file) eq "ARRAY") {
	my $f = shift @$file;
	my $fn = shift @$file;
	push(@headers, @$file);
	$file = $f;
	$filename = $fn unless defined $filename;
    }

    return ($name => [$file, $filename, @headers]);
}



*file = \&value;

sub filename {
    my $self = shift;
    my $old = $self->{_HTML_DOM_filename};
    $self->{_HTML_DOM_filename} = shift if @_;
    $old = $self->file unless defined $old;
    $old;
}

sub headers { } # ~~~ Do I want to complete this?

sub content {
    my $self = shift;
    my $old = $self->{_HTML_DOM_content};
    $self->{_HTML_DOM_content} = shift if @_;
    $old;
}



# ------- HTMLTextAreaElement interface ---------- #

package HTML::DOM::Element::TextArea;
our $VERSION = '0.008';
our @ISA = qw'HTML::DOM::Element HTML::Form::Input';

sub defaultValue { # same as HTML::DOM::Element::Title::text
	($_[0]->firstChild or
		@_ > 1 && $_[0]->appendChild(
			shift->ownerDocument->createTextNode(shift)
		),
		return '',
	)->data(@_[1..$#_]);
}
*form = \&HTML::DOM::Element::Select::form;
*accessKey = \&HTML::DOM::Element::Input::accessKey;
sub cols      { shift->attr( cols       => @_) }
*disabled = \&HTML::DOM::Element::Select::disabled;
*name = \&HTML::DOM::Element::Select::name;
*readOnly = \&HTML::DOM::Element::Input::readOnly;
sub rows {shift->attr( rows      => @_) }
*tabIndex = \&HTML::DOM::Element::Select::tabIndex;
sub type { 'textarea' }
sub value        {
	my $self = shift;
	my $ret;

	if(!defined $self->{_HTML_DOM_value}) {
		$ret = $self->defaultValue
	}
	else {
		$ret = $self->{_HTML_DOM_value}
	}
	@_ and $self->{_HTML_DOM_value} = shift;
	return $ret;
}
*blur = \&HTML::DOM::Element::Select::blur;
*focus = \&HTML::DOM::Element::Select::focus;
*select = \&HTML::DOM::Element::Input::select;

sub form_name_value
# ~~~ to be deleted when my patch to HTML::Form is applied
{
    package
	HTML::Form::Input;
    my $self = shift;
    my $name = $self->name;
    return unless defined $name && length $name;
    return if $self->disabled;
    my $value = $self->value;
    return unless defined $value;
    return ($name => $value);
}


# ------- HTMLButtonElement interface ---------- #

package HTML::DOM::Element::Button;
our $VERSION = '0.008';
our @ISA = qw'HTML::DOM::Element';

*form = \&HTML::DOM::Element::Select::form;
*accessKey = \&HTML::DOM::Element::Input::accessKey;
*disabled = \&HTML::DOM::Element::Select::disabled;
*name = \&HTML::DOM::Element::Form::name;
*tabIndex = \&HTML::DOM::Element::Select::tabIndex;
*type = \&HTML::DOM::Element::Select::type;
sub value      { shift->attr( value       => @_) }


# ------- HTMLLabelElement interface ---------- #

package HTML::DOM::Element::Label;
our $VERSION = '0.008';
our @ISA = qw'HTML::DOM::Element';

*form = \&HTML::DOM::Element::Select::form;
*accessKey = \&HTML::DOM::Element::Input::accessKey;
sub htmlFor { shift->attr( htmlFor       => @_) }

# ------- HTMLFieldSetElement interface ---------- #

package HTML::DOM::Element::FieldSet;
our $VERSION = '0.008';
our @ISA = qw'HTML::DOM::Element';

*form = \&HTML::DOM::Element::Select::form;

# ------- HTMLLegendElement interface ---------- #

package HTML::DOM::Element::Legend;
our $VERSION = '0.008';
our @ISA = qw'HTML::DOM::Element';

*form = \&HTML::DOM::Element::Select::form;
*accessKey = \&HTML::DOM::Element::Input::accessKey;
*align = \*HTML::DOM::Element::Input::align;


no warnings;
!+~()#%$-*
