BEGIN { require 5.006; }
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'HTML::DOM',
    AUTHOR              => 'Father Chrysostomos <sprout & cpan . org>',
    VERSION_FROM        => 'lib/HTML/DOM.pm',
    ABSTRACT_FROM       => 'lib/HTML/DOM.pm',
    PL_FILES            => {},
    PREREQ_PM => {
         Carp                 => 0,
         constant             => 0,
# not used explicitly yet
#        'CSS::DOM'           => 0,
        'CSS::DOM::StyleDecl' => 0,
         Exporter             => 5.57, # for use Exporter 'import'
        'HTML::TreeBuilder'   => 0,
        'HTML::Element'       => 0,
        'HTML::Form'          => 1.054,
        'HTTP::Headers::Util' => 0,
         overload             => 0,
        'Scalar::Util'        => 1.08,
         strict               => 0,
        'Test::More'          => 0,
         URI                  => 0,
         warnings             => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz',
                             TAR => 'COPYFILE_DISABLE=1 tar' },
    clean               => { FILES => 'HTML-DOM-*' },
);
