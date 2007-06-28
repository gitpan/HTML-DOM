package HTML::DOM::Exception;

use constant {
	INDEX_SIZE_ERR              => 1,
	DOMSTRING_SIZE_ERR          => 2,
	HIERARCHY_REQUEST_ERR       => 3,
	WRONG_DOCUMENT_ERR          => 4,
	INVALID_CHARACTER_ERR       => 5,
	NO_DATA_ALLOWED_ERR         => 6,
	NO_MODIFICATION_ALLOWED_ERR => 7,
	NOT_FOUND_ERR               => 8,
	NOT_SUPPORTED_ERR           => 9,
	INUSE_ATTRIBUTE_ERR         => 10,
};

use Exporter 'import';

our $VERSION = '0.001';
our @EXPORT_OK = qw'
	INDEX_SIZE_ERR             
	DOMSTRING_SIZE_ERR         
	HIERARCHY_REQUEST_ERR      
	WRONG_DOCUMENT_ERR         
	INVALID_CHARACTER_ERR      
	NO_DATA_ALLOWED_ERR        
	NO_MODIFICATION_ALLOWED_ERR
	NOT_FOUND_ERR              
	NOT_SUPPORTED_ERR          
	INUSE_ATTRIBUTE_ERR
';
our %EXPORT_TAGS = (all => [@EXPORT_OK]);


use overload
	fallback => 1,
	'0+' => sub { $_[0][0] },
	'""' => sub { $_[0][1] =~ /^(.*?)\n?\z/s; "$1\n" },
;

sub new {
	bless [@_[1,2]], $_[0];
}

'true'
__END__

=head1 NAME

HTML::DOM::Exception - The Exception interface for HTML::DOM

=head1 SYNOPSIS

  use HTML::DOM::Exception 'INVALID_CHARACTER_ERR';

  eval {
          die new HTML::DOM::Exception
                  INVALID_CHARACTER_ERR,
                  'Only ASCII characters allowed!'
  };

  $@ == INVALID_CHARACTER_ERR; # true

  print $@;    # prints "Only ASCII characters allowed!\n";

=head1 DESCRIPTION

This module implementations the W3C's DOMException interface.
HTML::DOM::Exception objects
stringify to the message passed to the constructer and numify to the 
error
number (see below, under L<'EXPORTS'>).

=head1 METHODS

=over 4

=item new HTML::DOM::Exception $type, $message

This class method creates a new exception object. C<$type> is expected to
be an integer (you can use the constants listed under L<'EXPORTS'>).
C<$message> is the error message.

=cut

sub new {
	bless [@_[1,2]], shift;
}


=head1 EXPORTS

The following constants are optionally exported. The descriptions are 
copied from the DOM spec.

=over 4

=item INDEX_SIZE_ERR (1)

If index or size is negative, or greater than the allowed value

=item DOMSTRING_SIZE_ERR (2)

If the specified range of text does not fit into a DOMString

=item HIERARCHY_REQUEST_ERR (3)

If any node is inserted somewhere it doesn't belong

=item WRONG_DOCUMENT_ERR (4)

If a node is used in a different document than the one that created it (that doesn't support it)

=item INVALID_CHARACTER_ERR (5)

If an invalid character is specified, such as in a name.

=item NO_DATA_ALLOWED_ERR (6)

If data is specified for a node which does not support data

=item NO_MODIFICATION_ALLOWED_ERR (7)

If an attempt is made to modify an object where modifications are not allowed

=item NOT_FOUND_ERR (8)

If an attempt was made to reference a node in a context where it does not exist

=item NOT_SUPPORTED_ERR (9)

If the implementation does not support the type of object requested

=item INUSE_ATTRIBUTE_ERR (10)

If an attempt is made to add an attribute that is already inuse elsewhere

=back

=head1 SEE ALSO

L<HTML::DOM>
