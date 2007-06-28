package HTML::DOM::NodeList::Magic;

use strict;
use warnings;
use overload fallback => 1, '@{}' => \&_get_tie;

use Scalar::Util 'weaken';

our $VERSION = '0.001';

# Innards: {
#	get => sub { ... }, # sub that gets the list
#	list => [ ... ], # the list, or undef
#	tie => \@tied_array, # or undef, if the array has not been
#	                     # accessed yet
# }


# new NodeList sub { ... }
# The sub needs to return the list of nodes.

sub new {
	bless {get => $_[1]}, shift;
}

sub item {
	my $self = shift;
	# Oh boy! Look at these brackets!
	${$$self{list} ||= [&{$$self{get}}]}[$_[0]];
}

sub length {
	my $self = shift;
	# Oh no, here we go again.
	scalar @{$$self{list} ||= [&{$$self{get}}]};
}

sub _you_are_stale {
	delete $_[0]{list};
}

sub DOES {
	return !0 if $_[1] eq 'HTML::DOM::NodeList';
	eval { shift->SUPER::DOES(@_) } || !1
}

# ---------- TIES --------- # 

sub _get_tie {
	my $self = shift;
	$$self{tie} or
		weaken(tie @{ $$self{tie} }, __PACKAGE__, $self),
		$$self{tie};
}

sub TIEARRAY  { $_[1] }
sub FETCH     { $_[0]->item($_[1]) }
sub FETCHSIZE { $_[0]->length }
sub EXISTS    { $_[0]->item($_[1]) } # nodes are true, undef is false
sub DDS_freeze { my $self = shift; delete $$self{tie}; $self }

1;

__END__


The reference behind a tied variable can be weakened with 'weaken tie'. But
a subsequent 'weaken tied' won't work, so it has to be weakened as the tie
is created.

#!/usr/bin/perl -l

# works with 5.8.8 and 5.9.5 patch level #31224

use Scalar::Util qw'weaken isweak';

sub TIEHASH { $_[1] }
sub DESTROY { print "Bye bye!" }
$obj = bless[];


weaken tie %{$obj->[0]}, __PACKAGE__, $obj;
# This does not work:
#weaken tied %{$obj->[0]};

print 'before undef';
undef $obj;
print 'after undef';

__END__

