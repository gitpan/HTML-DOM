#!/usr/bin/perl -T

# This script tests the HTMLElement interface and most of the interfaces
# that are derived from it (not forms or tables).

# Note: Some attributes are supposed to have their values normalised when
# accessed through the DOM 0 interface. For this reason, some attributes,
# particularly ‘align’, have weird capitalisations of their values when
# they are set. This is intentional.

# ~~~ I need to write tests for content_offset

use strict; use warnings;

use Test::More tests => 555;


sub test_attr {
	my ($obj, $attr, $val, $new_val) = @_;
	my $attr_name = (ref($obj) =~ /[^:]+\z/g)[0] . "'s $attr";

	# I get the attribute first before setting it, because at one point
	# I had it setting it to undef with no arg.
	is $obj->$attr,          $val,     "get $attr_name";
	is $obj->$attr($new_val),$val, "set/get $attr_name";
	is $obj->$attr,$new_val,     ,     "get $attr_name again";
}


# -------------------------#
# Test 1: load the module

BEGIN { use_ok 'HTML::DOM'; }

# -------------------------#
# Test 2: document constructor

my $doc = new HTML::DOM;
isa_ok $doc, 'HTML::DOM';

{
	my ($evt,$targ);
	$doc->default_event_handler(sub{
		($evt,$targ) = ($_[0]->type, shift->target);
	});
	
	sub test_event {
		my($obj, $event) = @_;
		($evt,$targ) = ();
		my $class = (ref($obj) =~ /[^:]+\z/g)[0];
		is_deeply [$obj->$event], [],
			"return value of $class\'s $event method";
		is $evt, $event, "$class\'s $event method";
		is refaddr $targ, refaddr $obj, 
			"$class\'s $event event is on target"
	}
}
	


# -------------------------#
# Tests 3-45: Element types that just use the HTMLElement interface

for (qw/ sub sup span bdo tt i b u s strike big small em strong dfn code
         samp kbd var cite acronym abbr dd dt noframes noscript
         address center /) {
	is ref $doc->createElement($_), 'HTML::DOM::Element',
		"class for $_";
}

{
	my $elem = $doc->createElement('sub');
	$elem->attr(id => 'di');
	$elem->attr(title => 'eltit');
	$elem->attr(lang => 'en');
	$elem->attr(dir => 'lefT');
	$elem->attr(class => 'ssalc');

	test_attr $elem, qw/ id        di    eyeD /;
	test_attr $elem, qw/ title     eltit titulus /;
	test_attr $elem, qw/ lang      en    el /;
	test_attr $elem, qw/ dir       left  right /;
	is $elem->className,'ssalc',               ,     'get className';
	is $elem->className('taxis'),       'ssalc', 'set/get className';
	is $elem->className,'taxis',               , 'get className again';
}

# -------------------------#
# Tests 46-9: HTMLHtmlElement

{
	is ref(
		my $elem = $doc->createElement('html'),
	), 'HTML::DOM::Element::HTML',
		"class for html";
	;
	$elem->attr(version => 'noisrev');

	test_attr $elem, qw/ version noisrev ekdosis /;
}

# -------------------------#
# Tests 50-3: HTMLHeadElement

{
	is ref(
		my $elem = $doc->createElement('head'),
	), 'HTML::DOM::Element::Head',
		"class for head";
	;
	$elem->attr(profile => 'eliforp');

	test_attr $elem, qw/ profile eliforp prolific /;
}

# -------------------------#
# Tests 54-81: HTMLLinkElement

{
	is ref(
		my $elem = $doc->createElement('link'),
	), 'HTML::DOM::Element::Link',
		"class for link";
	;
	$elem->attr(charset  => 'utf-8');
	$elem->attr(href     => '/styles.css');
	$elem->attr(hreflang => 'ru');
	$elem->attr(media    => 'radio');
	$elem->attr(rel      => 'ler');
	$elem->attr(rev      => 'ver');
	$elem->attr(target   => 'tegrat');
	$elem->attr(type     => 'application/pdf');

	ok!$elem->disabled                      ,     'get disabled';
	ok!$elem->disabled       (1),           , 'set/get disabled';
	ok $elem->disabled                      ,     'get disabled again';
	test_attr $elem, qw/ charset  utf-8           utf-32be        /;
	test_attr $elem, qw\ href     /styles.css     /stylesheet.css \;
	test_attr $elem, qw/ hreflang ru              fr              /;
	test_attr $elem, qw\ media    radio           avian-carrier   \;
	test_attr $elem, qw/ rel      ler             lure            /;
	test_attr $elem, qw\ rev      ver             ekd             \;
	test_attr $elem, qw/ target   tegrat          guitar          /;
	test_attr $elem, qw\ type     application/pdf text/richtext   \;
}

# -------------------------#
# Tests 82-5: HTMLTitleElement

{
	is ref(
		my $elem = $doc->createElement('title'),
	), 'HTML::DOM::Element::Title',
		"class for title";
	;

	test_attr $elem, 'text', '', 'tittle';
}

# -------------------------#
# Tests 86-98: HTMLMetaElement

{
	is ref(
		my $elem = $doc->createElement('meta'),
	), 'HTML::DOM::Element::Meta',
		"class for meta";
	;
	$elem->attr( content     => 'text/html; charset=utf-8');
	$elem->attr('http-equiv' => 'Content-Type');
	$elem->attr( name        => 'Fred');
	$elem->attr( scheme      => 'devious');

	test_attr $elem, 'content', 'text/html; charset=utf-8', 'no-cache';
	is $elem->httpEquiv,'Content-Type',          ,     'get httpEquiv';
	is $elem->httpEquiv('Pragma'), 'Content-Type', 'set/get httpEquiv';
	is $elem->httpEquiv,'Pragma',                'get httpEquiv again';
	test_attr $elem, qw` name    Fred             George             `;
	test_attr $elem, qw` scheme  devious          divisive           `;
}

# -------------------------#
# Tests 99-105: HTMLBaseElement

{
	is ref(
		my $elem = $doc->createElement('base'),
	), 'HTML::DOM::Element::Base',
		"class for base";
	;
	$elem->attr(href     => '/styles.css');
	$elem->attr(target   => 'tegrat');

	test_attr $elem, qw~ href   /styles.css /stylesheet.css  ~;
	test_attr $elem, qw~ target tegrat      guitar           ~;
}

# -------------------------#
# Tests 106-11: HTMLIsIndexElement

{
	is ref(
		my $elem = $doc->createElement('isindex'),
	), 'HTML::DOM::Element::IsIndex',
		"class for isindex";
	;
	$elem->attr(prompt     => 'Yayayyayayaayay');

	is $elem->form, undef, 'IsIndex undef form';
	(my $form = $doc->createElement('form'))->appendChild(
		$doc->createElement('div'));
	$form->firstChild->appendChild($elem);
	is $elem->form, $form, 'IsIndex form';

	test_attr $elem, qw @ prompt Yayayyayayaayay     01504           @;
}

# -------------------------#
# Tests 112-21: HTMLStyleElement

{
	is ref(
		my $elem = $doc->createElement('style'),
	), 'HTML::DOM::Element::Style',
		"class for style";
	;
	$elem->attr(media    => 'radio');
	$elem->attr(type     => 'application/pdf');

	ok!$elem->disabled                           ,      'get disabled';
	ok!$elem->disabled       (1),                ,  'set/get disabled';
	ok $elem->disabled                           ,'get disabled again';
	test_attr $elem, qw! media radio           avian-carrier         !;
	test_attr $elem, qw! type  application/pdf text/richtext         !;
}

# -------------------------#
# Tests 122-40: HTMLBodyElement

{
	is ref(
		my $elem = $doc->createElement('body'),
	), 'HTML::DOM::Element::Body',
		"class for body";
	;
	$elem->attr(aLink     => 'red');
	$elem->attr(background=> 'orange');
	$elem->attr(bgColor   => 'yellow');
	$elem->attr(link      => 'green');
	$elem->attr(text      => 'blue');
	$elem->attr(vLink     => 'dingo');

	test_attr $elem, qw 2 aLink      red     kokkino           2;
	test_attr $elem, qw 3 background orange  portokali         3;
	test_attr $elem, qw 4 bgColor    yellow  kitrino           4;
	test_attr $elem, qw 5 link       green   prasino           5;
	test_attr $elem, qw 6 text       blue    mple              6;
	test_attr $elem, qw 7 vLink      dingo   eidos_skylou      7;
}

# -------------------------#
# Tests 141-7: HTMLUListElement

{
	is ref(
		my $elem = $doc->createElement('ul'),
	), 'HTML::DOM::Element::UL',
		"class for ul";
	;
	$elem->attr(type     => 'dIsc');

	ok!$elem->compact                           ,      'get compact';
	ok!$elem->compact       (1),                ,  'set/get compact';
	ok $elem->compact                           ,'get compact again';
	test_attr $elem, qw 2 type      disc square           2;
}

# -------------------------#
# Tests 148-57: HTMLOListElement

{
	is ref(
		my $elem = $doc->createElement('ol'),
	), 'HTML::DOM::Element::OL',
		"class for ol";
	;
	$elem->attr(compact => '1');
	$elem->attr(type     => 'i');
	$elem->attr(start     => '4');

	ok $elem->compact                           ,      'get compact';
	ok $elem->compact       (0),                ,  'set/get compact';
	ok!$elem->compact                           ,'get compact again';
	test_attr $elem, qw 2 type      i a           2;
	test_attr $elem, qw 2 start     4 5           2;
}

# -------------------------#
# Tests 158-61: HTMLDListElement

{
	is ref(
		my $elem = $doc->createElement('dl'),
	), 'HTML::DOM::Element::DL',
		"class for dl";
	;
	$elem->attr(compact => '1');

	ok $elem->compact                           ,      'get compact';
	ok $elem->compact       (0),                ,  'set/get compact';
	ok!$elem->compact                           ,'get compact again';
}

# -------------------------#
# Tests 162-5: HTMLDirectoryElement

{
	is ref(
		my $elem = $doc->createElement('dir'),
	), 'HTML::DOM::Element::Dir',
		"class for dir";
	;
	$elem->attr(compact => '1');

	ok $elem->compact                           ,      'get compact';
	ok $elem->compact       (0),                ,  'set/get compact';
	ok!$elem->compact                           ,'get compact again';
}

# -------------------------#
# Tests 166-9: HTMLMenuElement

{
	is ref(
		my $elem = $doc->createElement('menu'),
	), 'HTML::DOM::Element::Menu',
		"class for menu";
	;
	$elem->attr(compact => '1');

	ok $elem->compact                           ,      'get compact';
	ok $elem->compact       (0),                ,  'set/get compact';
	ok!$elem->compact                           ,'get compact again';
}

# -------------------------#
# Tests 170-6: HTMLLIElement

{
	is ref(
		my $elem = $doc->createElement('li'),
	), 'HTML::DOM::Element::LI',
		"class for li";
	;
	$elem->attr(type     => 'disc');
	$elem->attr(value     => '30');

	test_attr $elem, qw 2 type      disc square       2;
	test_attr $elem, qw 2 value     30   40           2;
}

# -------------------------#
# Tests 177-80: HTMLDivElement

{
	is ref(
		my $elem = $doc->createElement('div'),
	), 'HTML::DOM::Element::Div',
		"class for div";
	;
	$elem->attr(align     => 'leFT');

	test_attr $elem, qw 2 align left right       2;
}

# -------------------------#
# Tests 181-9: HTMLHeadingElement

{
	my $elem;
	is ref(
		$elem = $doc->createElement("h$_"),
	), 'HTML::DOM::Element::Heading',
		"class for h$_"
	for 1..6;

	$elem->attr(align     => 'LEFt');

	test_attr $elem, qw 2 align left right       2;
}

# -------------------------#
# Tests 190-4: HTMLQuoteElement

{
	my $elem;
	is ref(
		$elem = $doc->createElement($_),
	), 'HTML::DOM::Element::Quote',
		"class for $_"
	for qw wq blockquotew;

	$elem->attr(cite     => 'me.html');

	test_attr $elem, qw 2 cite me.html you.html       2;
}

# -------------------------#
# Tests 195-8: HTMLPreElement

{
	my $elem;
	is ref(
		$elem = $doc->createElement('pre'),
	), 'HTML::DOM::Element::Pre',
		"class for pre";

	$elem->attr(width     => '7');

	test_attr $elem, qw 2 width 7 8       2;
}

# -------------------------#
# Tests 199-202: HTMLBRElement

{
	my $elem;
	is ref(
		$elem = $doc->createElement('br'),
	), 'HTML::DOM::Element::Br',
		"class for br";

	$elem->attr(clear     => 'leFt');

	test_attr $elem, qw 2 clear left all       2;
}

# -------------------------#
# Tests 203-12: HTMLBaseFontElement

{
	my $elem;
	is ref(
		$elem = $doc->createElement('basefont'),
	), 'HTML::DOM::Element::BaseFont',
		"class for basefont";

	$elem->attr(color     => 'red');
	$elem->attr(face     => 'visage');
	$elem->attr(size    => '3');

	no # stupid
	warnings # about
	'qw'; # !!!
	test_attr $elem, qw 2 color red    #000000     2;
	test_attr $elem, qw 2 face  visage mien      2;
	test_attr $elem, qw 2 size  3      4       2;
}

# -------------------------#
# Tests 213-22: HTMLFontElement

{
	my $elem;
	is ref(
		$elem = $doc->createElement('font'),
	), 'HTML::DOM::Element::Font',
		"class for font";

	$elem->attr(color     => 'red');
	$elem->attr(face     => 'visage');
	$elem->attr(size    => '3');

	no warnings qw e qw e ;
	test_attr $elem, qw 2 color red    #000000     2;
	test_attr $elem, qw 2 face  visage mien      2;
	test_attr $elem, qw 2 size  3      4       2;
}

# -------------------------#
# Tests 223-35: HTMLHRElement

{
	my $elem;
	is ref(
		$elem = $doc->createElement('hr'),
	), 'HTML::DOM::Element::HR',
		"class for hr";

	$elem->attr(align     => 'lEFt');
	$elem->attr(noshade     => '1');
	$elem->attr(size    => '3');
	$elem->attr(width    => '3');

	test_attr $elem, qw 2 align left center     2;
	ok $elem->noShade                  ,      'get HR’s noShade';
	ok $elem->noShade(0),              ,  'set/get HR’s noShade';
	ok!$elem->noShade                  ,      'get HR’s noShade again';
	test_attr $elem, qw 2 size  3      4       2;
	test_attr $elem, qw 2 width 3      4       2;
}

# -------------------------#
# Tests 236-43: HTMLModElement

{
	my $elem;
	is ref(
		$elem = $doc->createElement($_),
	), 'HTML::DOM::Element::Mod',
		"class for $_"
	for qw wins delw;

	$elem->attr(cite     => 'me.html');
	$elem->attr(datetime => 'today');

	test_attr $elem, qw 2 cite     me.html you.html     2;
	test_attr $elem, qw 2 dateTime today   yesterday    2;
}

# -------------------------#
# Tests 244-89: HTMLAnchorElement

{
	my $elem;
	is ref(
		$elem = $doc->createElement('a'),
	), 'HTML::DOM::Element::A',
		"class for a";

	$elem->attr(accesskey => 'F');
	$elem->attr(charset   => 'iso-8859-3');
	$elem->attr(coords    => '1,2,3,34');
	$elem->attr(href      => 'here');
	$elem->attr(hreflang  => 'en');
	$elem->attr(name      => 'Fred');
	$elem->attr(rel       => 'foo');
	$elem->attr(rev       => 'phu');
	$elem->attr(shape     => 'circle');
	$elem->attr(tabIndex  => '78');
	$elem->attr(target    => 'bull\'s-eye');
	$elem->attr(type      => 'application/pdf');

	no warnings qw: qw: ;
	test_attr $elem, qw 2 accessKey F               G           2;
	test_attr $elem, qw 2 charset   iso-8859-3      x-mac-roman 2;
	test_attr $elem, qw 5 coords    1,2,3,34        9,8,7,6     5;
	test_attr $elem, qw 2 href      here            there       2;
	test_attr $elem, qw 2 hreflang  en              el          2;
	test_attr $elem, qw 2 name      Fred            George      2;
	test_attr $elem, qw 2 rel       foo             bar         2;
	test_attr $elem, qw 2 rev       phu             bah         2;
	test_attr $elem, qw 2 shape     circle          ellipsoid   2;
	test_attr $elem, qw 2 tabIndex  78              81          2;
	test_attr $elem, qw 2 target    bull's-eye      whatever    2;
	test_attr $elem, qw 2 type      application/pdf text/html   2;

	test_event $elem => $_ for qw/blur focus click/;
}

# -------------------------#
# Tests 290-326: HTMLImageElement

{
	my $elem;
	is ref(
		$elem = $doc->createElement('img'),
	), 'HTML::DOM::Element::Img',
		"class for img";

	$elem->attr(name     => 'Fred');
	$elem->attr(align    => 'lefT');
	$elem->attr(alt      => 'blank');
	$elem->attr(border   => '7');
	$elem->attr(height   => '8');
	$elem->attr(hspace   => '9');
	$elem->attr(isMap    => '1');
	$elem->attr(longdesc => 'phu');
	$elem->attr(src      => 'circle');
	$elem->attr(usemap   => '1');
	$elem->attr(vspace   => '10');
	$elem->attr(width    => '11');

	no warnings qw: qw: ;
	test_attr $elem, qw 2 name     Fred    George    2;
	test_attr $elem, qw 2 align    left    right     2;
	test_attr $elem, qw 5 alt      blank   whinte    5;
	test_attr $elem, qw 2 border   7       8         2;
	test_attr $elem, qw 2 height   8       10        2;
	test_attr $elem, qw 2 hspace   9       56        2;
	ok $elem->isMap                  ,      'get Img’s isMap';
	ok $elem->isMap(0),              ,  'set/get Img’s isMap';
	ok!$elem->isMap                  ,      'get Img’s isMap again';
	test_attr $elem, qw 2 longDesc phu     bah       2;
	test_attr $elem, qw 2 src      circle  ellipsoid 2;
	test_attr $elem, qw 2 useMap   1       two       2;
	test_attr $elem, qw 3 vspace   10      12        3;
	test_attr $elem, qw 2 width    11      79        2;
}

# -------------------------#
# Tests 327-81: HTMLObjectElement

{
	my $elem;
	is ref(
		$elem = $doc->createElement('object'),
	), 'HTML::DOM::Element::Object',
		"class for object";

	is $elem->form, undef, 'Object’s undef form';
	(my $form = $doc->createElement('form'))->appendChild(
		$doc->createElement('div'));
	$form->firstChild->appendChild($elem);
	is $elem->form, $form, 'Object’s form';

	$elem->attr(code     => 'e-doc');
	$elem->attr(align    => 'Left');
	$elem->attr(archive  => 'left');
	$elem->attr(border   => '7');
	$elem->attr(codebase => '7');
	$elem->attr(codeType => 'text/tcl');
	$elem->attr(data     => 'text/tcl');
	$elem->attr(declare  => 'text/tcl');
	$elem->attr(height   => '8');
	$elem->attr(hspace   => '9');
	$elem->attr(name     => 'Fred');
	$elem->attr(standby  => 'Fred');
	$elem->attr(tabIndex => '90');
	$elem->attr(type     => 'image/gif');
	$elem->attr(usemap   => '1');
	$elem->attr(vspace   => '10');
	$elem->attr(width    => '11');

	no warnings qw: qw: ;
	test_attr $elem, qw 2 code     e-doc    f-doc         2;
	test_attr $elem, qw 2 align    left     right         2;
	test_attr $elem, qw 2 archive  left     leaving       2;
	test_attr $elem, qw 2 border   7        8             2;
	test_attr $elem, qw 2 codeBase 7        seen          2;
	test_attr $elem, qw 2 codeType text/tcl thnig/wierd   2;
	test_attr $elem, qw 2 data     text/tcl =1/(tcl/text) 2;
	ok $elem->declare              ,      'get Object’s declare';
	ok $elem->declare(0),          ,  'set/get Object’s declare';
	ok!$elem->declare              ,      'get Object’s declare again';
	test_attr $elem, qw 2 height   8         10      2;
	test_attr $elem, qw 2 hspace   9         56      2;
	test_attr $elem, qw 2 name     Fred      George  2;
	test_attr $elem, qw 2 standby  Fred      Will    2;
	test_attr $elem, qw 4 tabIndex 90        123     4;
	test_attr $elem, qw 2 type     image/gif foo/bar 2;
	test_attr $elem, qw 2 useMap   1         two     2;
	test_attr $elem, qw 3 vspace   10        12      3;
	test_attr $elem, qw 2 width    11        79      2;

	is +()=$elem->contentDocument, 0, 'object contentDocument';
}

# -------------------------#
# Tests 382-95: HTMLParamElement

{
	my $elem;
	is ref(
		$elem = $doc->createElement('param'),
	), 'HTML::DOM::Element::Param',
		"class for param";

	$elem->attr(name      => 'Fred');
	$elem->attr(type      => 'image/gif');
	$elem->attr(value     => '1');
	$elem->attr(valueType => 'dAtA');

	no warnings qw: qw: ;
	test_attr $elem, qw 2 name      Fred      George  2;
	test_attr $elem, qw 2 type      image/gif foo/bar 2;
	test_attr $elem, qw 2 value     1         two     2;
	test_attr $elem, qw 3 valueType data      ref     3;
}

# -------------------------#
# Tests 396-428: HTMLAppletElement

{
	my $elem;
	is ref(
		$elem = $doc->createElement('applet'),
	), 'HTML::DOM::Element::Applet',
		"class for applet";

	$elem->attr(align    => 'lEft');
	$elem->attr(alt      => 'left');
	$elem->attr(archive  => 'left');
	$elem->attr(code     => 'e-doc');
	$elem->attr(codebase => '7');
	$elem->attr(height   => '8');
	$elem->attr(hspace   => '9');
	$elem->attr(name     => 'Fred');
	$elem->attr(object   => 'Fred');
	$elem->attr(vspace   => '10');
	$elem->attr(width    => '11');

	test_attr $elem, qw 2 align    left     right   2;
	test_attr $elem, qw 2 alt      left     alto    2;
	test_attr $elem, qw 2 archive  left     leaving 2;
	test_attr $elem, qw 2 code     e-doc    f-doc   2;
	test_attr $elem, qw 2 codeBase 7        seen    2;
	test_attr $elem, qw 2 height   8        10      2;
	test_attr $elem, qw 2 hspace   9        56      2;
	test_attr $elem, qw 2 name     Fred     George  2;
	test_attr $elem, qw 2 object   Fred     George  2;
	test_attr $elem, qw 3 vspace   10       12      3;
	test_attr $elem, qw 2 width    11       79      2;
}

# -------------------------#
# Tests 429-34: HTMLMapElement

{
	my $elem;
	is ref(
		$elem = $doc->createElement('map'),
	), 'HTML::DOM::Element::Map',
		"class for map";

	$elem->attr(name     => 'Fred');
	test_attr $elem, qw 2 name     Fred     George  2;

	my $areas = $elem->areas;

	my $area1 = $doc->createElement('area');
	my $area2 = $doc->createElement('area');
	my $area3 = $doc->createElement('area');

	$elem->appendChild($_) for $area1, $area2, $area3;

	is $areas->length, 3, 'number of areas in map';
	use Scalar::Util 1.14 'refaddr';
	is_deeply [map refaddr $_, @$areas],
	          [map refaddr $_, $area1, $area2, $area3], 'Map’s areas';
}

# -------------------------#
# Tests 435-59: HTMLAreaElement

{
	my $elem;
	is ref(
		$elem = $doc->createElement('area'),
	), 'HTML::DOM::Element::Area',
		"class for area";

	$elem->attr(accesskey => 'L');
	$elem->attr(alt       => 'left');
	$elem->attr(coords    => '1,2,2,4,5,6');
	$elem->attr(href      => 'e-doc');
	$elem->attr(nohref    => '1');
	$elem->attr(shape     => 'rect');
	$elem->attr(tabindex  => '9');
	$elem->attr(target    => 'Fred');

	no # silly
	warnings # about
	'qw';
	test_attr $elem, qw 2 accessKey L           M           2;
	test_attr $elem, qw 2 alt       left        alto        2;
	test_attr $elem, qw 3 coords    1,2,2,4,5,6 9,8,7,6,5,4 3;
	test_attr $elem, qw 2 href      e-doc       f-doc       2;
	ok $elem->noHref              ,      'get Area’s noHref';
	ok $elem->noHref(0),          ,  'set/get Area’s noHref';
	ok!$elem->noHref              ,      'get Area’s noHref again';
	test_attr $elem, qw 2 shape    rect     poly    2;
	test_attr $elem, qw 2 tabIndex 9        56      2;
	test_attr $elem, qw 2 target   Fred     George  2;
}

# -------------------------#
# Tests 460-84: HTMLAreaElement

{
	my $elem;
	is ref(
		$elem = $doc->createElement('script'),
	), 'HTML::DOM::Element::Script',
		"class for script";

	is $elem->text, '', 'script->text when empty';
	$elem->appendChild($doc->createTextNode(''));
	is $elem->text, '', 'script->text when blank';
	$elem->firstChild->data('foo');
	test_attr $elem, qw/text foo bar/;
	is $elem->firstChild->data, 'bar',
		'setting script->text modifies its child node';

	$elem->attr(for     => 'L');
	$elem->attr(event   => 'left');
	$elem->attr(charset => 'utf-8');
	$elem->attr(defer   => '1');
	$elem->attr(src     => '1');
	$elem->attr(type    => 'application/x-ecmascript');

	no # silly
	warnings # about
	'qw';
	test_attr $elem, qw 2 htmlFor L     M          2;
	test_attr $elem, qw 2 event   left  alto       2;
	test_attr $elem, qw 3 charset utf-8 iso-8859-7 3;
	ok $elem->defer              ,      'get Script’s defer';
	ok $elem->defer(0),          ,  'set/get Script’s defer';
	ok!$elem->defer              ,      'get Script’s defer again';
	test_attr $elem, qw-src  1                        3              -;
	test_attr $elem, qw.type application/x-ecmascript text/javascript.;
}

# -------------------------#
# Tests 485-91: HTMLFrameSetElement

{
	my $elem;
	is ref(
		$elem = $doc->createElement('frameset'),
	), 'HTML::DOM::Element::FrameSet',
		"class for frameset";

	$elem->attr(rows     => '*,50%');
	$elem->attr(cols   => '50%,10%,*');

	no # silly
	warnings # about
	'qw';
	test_attr $elem, qw 2 rows *,50% *,70%         2;
	test_attr $elem, qw 2 cols 50%,10%,* 10%,*,10% 2;
}

# -------------------------#
# Tests 491-518: HTMLFrameElement

{
	my $elem;
	is ref(
		$elem = $doc->createElement('frame'),
	), 'HTML::DOM::Element::Frame',
		"class for frame";

	$elem->attr(frameborder  => '1');
	$elem->attr(longdesc     => 'shortescritoire');
	$elem->attr(marginheight => '50');
	$elem->attr(marginwidth  => '5010');
	$elem->attr(name         => '50,10,*'); # nice name
	$elem->attr(noresize     => '50,10,*');
	$elem->attr(scrolling    => 'yEs');
	$elem->attr(src          => '50,10,*');

	no # silly
	warnings # about
	'qw';
	test_attr $elem, qw 2 frameBorder 1 0        2;
	test_attr $elem, qw 2 longDesc shortescritoire shortEscritoire 2;
	test_attr $elem, qw 2 marginHeight 50      500  2;
	test_attr $elem, qw 2 marginWidth  5010    1500 2;
	test_attr $elem, qw 2 name         50,10,* Bob  2;
	ok $elem->noResize             ,      'get Frame’s noResize';
	ok $elem->noResize(0),         ,  'set/get Frame’s noResize';
	ok!$elem->noResize             ,      'get Frame’s noResize again';
	test_attr $elem, qw 2 scrolling yes     auto    2;
	test_attr $elem, qw 2 src       50,10,* foo.gif 2;

	# weird frameborder test; strictly, since this is a value list, it
	# has to be normalised to lc
	$elem->setAttribute('frameborder'=>'bOOhoO');
	is frameBorder $elem, 'boohoo', 'frame->frameBorder is lc';

	isa_ok $elem->contentDocument, 'HTML::DOM','frame contentDocument';
}

# -------------------------#
# Tests 519-51: HTMLIFrameElement

{
	my $elem;
	is ref(
		$elem = $doc->createElement('iframe'),
	), 'HTML::DOM::Element::IFrame',
		"class for iframe";

	$elem->attr(align        => 'leFt');
	$elem->attr(frameborder  => '1');
	$elem->attr(height       => '2');
	$elem->attr(longdesc     => 'shortescritoire');
	$elem->attr(marginheight => '50');
	$elem->attr(marginwidth  => '5010');
	$elem->attr(name         => '50,10,*'); # nice name
	$elem->attr(scrolling    => 'yeS');
	$elem->attr(src          => '50,10,*');
	$elem->attr(width        => '50');

	no # silly
	warnings # about
	'qw';
	test_attr $elem, qw 2 align       left right 2;
	test_attr $elem, qw 2 frameBorder 1    0     2;
	test_attr $elem, qw 4 height      2    23    4;
	test_attr $elem, qw 2 longDesc shortescritoire shortEscritoire 2;
	test_attr $elem, qw 2 marginHeight 50      500  2;
	test_attr $elem, qw 2 marginWidth  5010    1500 2;
	test_attr $elem, qw 2 name         50,10,* Bob  2;
	test_attr $elem, qw 2 scrolling yes     auto    2;
	test_attr $elem, qw 2 src       50,10,* foo.gif 2;
	test_attr $elem, qw 2 width     50      500     2;

	# weird frameborder test; strictly, since this is a value list, it
	# has to be normalised to lc
	$elem->setAttribute('frameborder'=>'bOOhoO');
	is frameBorder $elem, 'boohoo', 'frame->frameBorder is lc';

	isa_ok $elem->contentDocument,'HTML::DOM','iframe contentDocument';
}

# -------------------------#
# Tests 554-5: HTMLParagraphElement

{
	is ref(
		my $elem = $doc->createElement('p'),
	), 'HTML::DOM::Element::P',
		"class for p";
	;
	$elem->attr(align     => 'leFT');

	test_attr $elem, qw 2 align left right       2;
}