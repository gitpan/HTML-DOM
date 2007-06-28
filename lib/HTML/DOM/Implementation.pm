package HTML::DOM::Implementation;

use strict;
use warnings;

our $VERSION = '0.001';

our $it = bless do{\my$x};

sub hasFeature {
	# ~~~ what zigackly are the various features support by levels
	#     higher than 1?

	return(lc $_[1] eq 'html' and !defined $_[2] || $_[2] eq '1.0');
}

1
__END__

=begin notes

interface DOMImplementation {
  boolean                   hasFeature(in DOMString feature, 
                                       in DOMString version);
};

Methods
	hasFeature
		Test if the DOM implementation implements a specific 
		feature.

		Parameters

			feature    The package name of the feature to test.
			           In Level 1, the legal values are "HTML"
			           and "XML" (case-insensitive).

			version    This is the version number of the pack-
			           age name to test. In Level 1, this is 
			           the string "1.0". If the version is not 
			           specified, supporting any version of the 
			           feature will cause the method to 
			           return true.

		Return Value
			true if the feature is implemented in the specified 
			version, false otherwise.

	This method raises no exceptions.
