BEGIN {
	require 5.008002; # for sub{} to mean sub{()}
	$] == 5.009005 and require 5.01;
	# I’m getting tired of failure reports that are due to the buggi-
	# ness of 5.9.5.
}
use ExtUtils::MakeMaker;

# This little piece of code is to solve (at least for this module) the oft-
# repeated problem of upgrades breaking code that relies on it. Releasing
# working versions of the other code is not a complete solution; the user
# has to be told as well.
# Unfortunately, previous versions of the JS plugin wouldn’t compile with-
# out WWW::Scripter loaded already. So this is a mess.
%broken_deps = (
 WWW'Scripter'Plugin'JavaScript => { breaks => 0.002, use => 0.003 }
);
while(my($mod,$vers) = each broken_deps) {
 if(eval{require WWW'Scripter}
    and eval"require $mod" and !eval{VERSION $mod $$vers{use}}) {
  print"
WARNING: This distribution breaks compatibility with
$mod $$vers{breaks} and earlier.\n\n";
 }
}

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
        'CSS::DOM'                 => 0.06, # compute_style
        'CSS::DOM::Style'          => 0.05, # modification_handler
                                            # and ::Style::parse’s
        'CSS::DOM::StyleSheetList' => 0,    # stringification
         Date'Format               => 0,
         Exporter                  => 5.57, # for use Exporter 'import'
         Hash'Util'FieldHash'Compat=> 0,
	'HTML::Tagset'             => 0,
        'HTML::TreeBuilder'        => 0,
        'HTML::Element'            => 0,
	'HTML::Encoding'           => 0,
         HTML::Parser              => 3,
         HTTP::Message             => eval('require HTTP::Message;
                                            VERSION HTTP::Message') == 5.81
                                            ? 5.811 : 0,
         HTTP::Request             => 0,
         HTTP::Request::Common     => 0,
        'HTTP::Headers::Util'      => 0,
         overload                  => 0,
        'Scalar::Util'             => 1.09, # refaddr
         strict                    => 0,
         URI                       => 0,
         warnings                  => 0,
# used only in the tests:
         CSS'DOM                   => 0.07, # !important ua rules
         Scalar::Util              => 1.14, # refaddr with ties
        'Test::More'               => 0,
	 utf8                      => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz',
                             TAR => 'COPYFILE_DISABLE=1 tar' },
    clean               => { FILES => 'HTML-DOM-*' },
    META_ADD            => { breaks => \%broken_deps }, # Hopefully this
);                       # will be recognised by the toolchain some day....
                     
