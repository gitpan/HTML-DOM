package HTML::DOM::Implementation;

use strict;
use warnings;

our $VERSION = '0.004';

our $it = bless do{\my$x};

my %features = (
	html => { '1.0' => 1 },
#	core => { '2.0' => 1 },
#	events => { '2.0' => 1 },
);

sub hasFeature {
	my($feature,$v) = (lc $_[1], $_[2]);
	exists $features{$feature} and
		!defined $v || exists $features{$feature}{$v};
}

# ~~~ documentation, please!
# ~~~ not until I actually decide this should be here.
sub add_feature { # feature, version
	$features{$_[1]}{$_[2]}++;
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
