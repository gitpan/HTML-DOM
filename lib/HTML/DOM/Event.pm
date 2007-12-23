package HTML::DOM::Event;

our $VERSION = '0.010';


use strict;
use warnings;

# Look, TMTOWTDI:
sub	CAPTURING_PHASE  (){             1,}
sub	AT_TARGET             (){ 2,}
	sub BUBBLING_PHASE             (){       3,}	

use Exporter 5.57 'import';

our @EXPORT_OK = qw'
	CAPTURING_PHASE            
	AT_TARGET        
	BUBBLING_PHASE              
';
our %EXPORT_TAGS = (all => \@EXPORT_OK);

sub new {
	bless {time => time}, $_[0];
}

# ----------- ATTRIBUTE METHODS ------------- #
# (all read-only)

# ~~~ I need to document that timeStamp returns the same value as time, not
# the number of milliseconds since the epoch.

sub type          { $_[0]{name      } }
sub target        { $_[0]{target    } }
sub currentTarget { $_[0]{cur_target} }
sub eventPhase    { $_[0]{phase     } }
sub bubbles       { $_[0]{froth     } }
sub cancelable    { $_[0]{cancelable} }
sub timeStamp     { $_[0]{time      } }
sub cancelled     { $_[0]{cancelled } } # non-DOM
sub propagation_stopped { $_[0]{stopped} } # same hear


# ----------- METHOD METHODS ------------- #

sub stopPropagation { $_[0]{stopped  } = !0; return }
sub preventDefault  { $_[0]{cancelled} = !0 if $_[0]->cancelable; return }
#  similar:
sub _set_eventPhase    { $_[0]{phase     } = $_[1] }
sub _set_target        { $_[0]{target    } = $_[1] }
sub _set_currentTarget { $_[0]{cur_target} = $_[1] }

sub initEvent {
	my $event = shift;
	return if defined $event->eventPhase;
	@$event{qw/name froth cancelable/} = @_;
	return
}

# ----------- OTHER STUFF ------------- #

# ~~~ Should I document class_for?

my %class_for = (
	#UIEvents => 'HTML::DOM::Event::UIEvent', # not yetimplemnedeteted
	# etc.
);

# This routine is identical to the one in Element.pm, but in a differnt
# lexical scope.
sub class_for {
	$class_for{$_[0]} || __PACKAGE__
}

1;
__END__


=head1 NAME

HTML::DOM::Event - A Perl class for HTML DOM Event objects

=head1 SYNOPSIS

  use HTML::DOM::Event ':all';

  ...
  

=head1 DESCRIPTION

blar blar blar

=head1 EXPORTS

The following node type constants are exportable:

=over 4

=item CAPTURING_PHASE (1)

=item AT_TARGET (2)

=item BUBBLING_PHASE (3)

=back

=head1 SEE ALSO

=over 4

L<HTML::DOM>

