package HTML::DOM::Implementation;

use strict;
use warnings;

our $VERSION = '0.014';

our $it = bless do{\my$x};

my %features = (
	html => { '1.0' => 1, '2.0' => 1 },
	core => { '1.0' => 1, '2.0' => 1 },
#	events => { '2.0' => 1 },
	views => { '2.0' => 1 },
#	stylesheets => { '2.0' => 1 },
#       css => { '2.0' => 1 },
);

sub hasFeature {
	my($feature,$v) = (lc $_[1], $_[2]);
	exists $features{$feature}
	?	!defined $v || exists $features{$feature}{$v}
	:	$feature =~ /^(?:stylesheets|css2?)\z/
		&& (require CSS::DOM, CSS::DOM->hasFeature(@_[1..$#_]));
}

# ~~~ documentation, please!
# ~~~ not until I actually decide this should be here.
sub add_feature { # feature, version
	$features{$_[1]}{$_[2]}++;
}

1
__END__

=head1 NAME

HTML::DOM::Implementation - HTML::DOM's 'DOMImplementation' object

=head1 SYNOPSIS

  $impl = $HTML::DOM::Implementation::it;
  $impl->hasFeature('HTML', '1.0'); # returns true
  $impl->hasFeature('XML' , '1.0'); # returns false

=head1 DESCRIPTION

This singleton class provides L<HTML::DOM>'s 'DOMImplementation' object.
There is no constructor. The object itself is accessible as
C<$HTML::DOM::Implementation::it> or C<< HTML::DOM->implementation >>.

=head1 THE ONLY METHOD

=head2 $implementation->hasFeature( $name, $version )

This returns true or false depending on whether the feature is supported.
C<$name> is case-tolerant. Currently, this only returns true for 'HTML' and
'1.0'.

=head1 SEE ALSO

L<HTML::DOM>

