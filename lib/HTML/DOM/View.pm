package HTML::DOM::View;

use warnings;
use strict;

use Scalar::Util qw'weaken';

our $VERSION = '0.015';

# -------- NON-DOM METHODS -------- #

sub new {
	weaken(my $thing = pop);
	bless(\$thing, shift);
}

# -------- DOM ATTRIBUTES -------- #

sub document { ${+shift} }



1

__END__

=head1 NAME

HTML::DOM::View - A Perl class for representing an HTML Document's 'defaultView'

=head1 SYNOPSIS

  use HTML::DOM;
  $doc = HTML::DOM->new;

  $view = $doc->defaultView;
  $view->document; # returns $doc

=head1 DESCRIPTION

This class is used for an HTML::DOM object's 'default view.' It implements 
the AbstractView DOM interface.

=head1 METHODS

=head2 $view = new HTML::DOM::View $doc;

Normally you don't need to call this constructor, but it's listed here for
completeness' sake.

=head2 $view->document

Returns the document associated with the view.

=head1 SEE ALSO

L<HTML::DOM>

