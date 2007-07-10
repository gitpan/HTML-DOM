package HTML::DOM::NodeList;

use strict;
use warnings;
use overload fallback => 1, '@{}' => sub { ${$_[0]} };

our $VERSION = '0.002';


# new NodeList \@array;

sub new {
	bless do {\(my $x = $_[1])}, shift;
}

sub item {
	${$_[0]}[$_[1]] || ()
}

sub length {
	scalar @${$_[0]}
}

1
