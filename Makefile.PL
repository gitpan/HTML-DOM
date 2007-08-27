use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'HTML::DOM',
    AUTHOR              => 'Father Chrysostomos <sprout & cpan . org>',
    VERSION_FROM        => 'lib/HTML/DOM.pm',
    ABSTRACT_FROM       => 'lib/HTML/DOM.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'HTML::TreeBuilder' => 0,
        'HTML::Element' => 0,
        'HTTP::Headers::Util' => 0,
        'Scalar::Util' => 0,
        'Test::More'   => 0,
         URI           => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'HTML-DOM-*' },
);
