BEGIN {
	require 5.008002; # for sub{} to mean sub{()}
	$] == 5.009005 and require 5.01;
	# I’m getting tired of failure reports that are due to the buggi-
	# ness of 5.9.5.
}
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'HTML::DOM',
    AUTHOR              => 'Father Chrysostomos <sprout & cpan . org>',
    VERSION_FROM        => 'lib/HTML/DOM.pm',
    ABSTRACT_FROM       => 'lib/HTML/DOM.pm',
    PL_FILES            => {},
    PREREQ_PM => {
         Carp                      => 0,
         constant                  => 1.03, # multiple at once
         constant::lexical         => 0,
        'CSS::DOM'                 => 0,
        'CSS::DOM::StyleDecl'      => 0,
        'CSS::DOM::StyleSheetList' => 0,
         Exporter                  => 5.57, # for use Exporter 'import'
        'HTML::TreeBuilder'        => 0,
        'HTML::Element'            => 0,
	'HTML::Encoding'           => 0,
        'HTML::Form'               => 1.054,
         HTML::Parser              => 3,
         HTTP::Message             => eval('require HTTP::Message;
                                            VERSION HTTP::Message') == 5.81
                                            ? 5.811 : 0,
         HTTP::Request             => 0,
         HTTP::Request::Common     => 0,
        'HTTP::Headers::Util'      => 0,
         overload                  => 0,
#        'Scalar::Util'             => 1.08, # refaddr
         strict                    => 0,
         URI                       => 0,
         warnings                  => 0,
# used only in the tests:
         Scalar::Util              => 1.14, # refaddr with ties
        'Test::More'               => 0,
	 utf8                      => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz',
                             TAR => 'COPYFILE_DISABLE=1 tar' },
    clean               => { FILES => 'HTML-DOM-*' },
);
