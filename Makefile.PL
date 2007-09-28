use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'HTML::DOM',
    AUTHOR              => 'Father Chrysostomos <sprout & cpan . org>',
    VERSION_FROM        => 'lib/HTML/DOM.pm',
    ABSTRACT_FROM       => 'lib/HTML/DOM.pm',
    PL_FILES            => {},
    PREREQ_PM => {
         Exporter             => 5.57, # for use Exporter 'import'
        'HTML::TreeBuilder'   => 0,
        'HTML::Element'       => 0,
        'HTML::Form'          => 1.054,
        'HTTP::Headers::Util' => 0,
        'Scalar::Util'        => 1.08,
        'Test::More'          => 0,
         URI                  => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'HTML-DOM-*' },
);
