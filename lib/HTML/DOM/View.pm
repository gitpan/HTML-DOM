package HTML::DOM::View;

use warnings;
use strict;

use Scalar::Util qw'weaken';
use Hash::Util::FieldHash::Compat 'fieldhash';

fieldhash my %doc;

our $VERSION = '0.021';

# -------- DOM ATTRIBUTES -------- #

sub document {
	my $old = $doc{my $self = shift};
	$doc{$self} = shift if @_;
	defined $old ? $old :();
}



1

__END__

=head1 NAME

HTML::DOM::View - A Perl class for representing an HTML Document's 'defaultView'

=head1 SYNOPSIS

  use HTML::DOM;
  $doc = HTML::DOM->new;
  
  $view = $doc->defaultView;
  $view->document; # returns $doc
  
  
  package MyView;
  @ISA = 'HTML::DOM::View';
  use HTML::DOM::View;

  sub new {
      my $self = bless {}, shift; # doesn't have to be a hash
      my $doc = shift;
      $self->document($doc);
      return $self
  }

  # ...

=head1 DESCRIPTION

This class is used for an HTML::DOM object's 'default view.' It implements 
the AbstractView DOM interface.

It is an inside-out class, so you can subclass it without being constrained
to any particular object structure.

=head1 METHODS

=head2 $view->document

Returns the document associated with the view.

You may pass an argument to set it, in which case the old value is 
returned. This attribute holds a weak reference to the object.

=head1 SEE ALSO

L<HTML::DOM>

