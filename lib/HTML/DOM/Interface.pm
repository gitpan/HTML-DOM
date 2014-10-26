package HTML::DOM::Interface;

use Exporter 5.57 'import';
our $VERSION = '0.017';

=head1 NAME

HTML::DOM::Interface - A list of HTML::DOM's interface members in machine-readable format

=head1 SYNOPSIS

  use HTML::DOM::Interface ':all';
  
  
  # name of DOM interface (HTMLDocument):
  $HTML::DOM::Interface{"HTML::DOM"};
  
  # interface it inherits from (Document):
  $HTML::DOM::Interface{HTMLDocument}{_isa};
  
  # whether this can be used as an array
  $HTML::DOM::Interface{HTMLDocument}{_array};
  # or hash
  $HTML::DOM::Interface{HTMLDocument}{_hash};
  
  
  # Properties and Methods
  
  # list them all
  grep !/^_/, keys %{ $HTML::DOM::Interface{HTMLDocument} };
  
  # see whether a given property is supported
  exists $HTML::DOM::Interface{HTMLDocument}{foo}; # false
  
  # Is it a method?
  $HTML::DOM::Interface{HTMLDocument}{title} & METHOD; # false
  $HTML::DOM::Interface{HTMLDocument}{open}  & METHOD; # true
  
  # Does the method return nothing?
  $HTML::DOM::Interface{HTMLDocument}{open} & VOID; # true
  
  # Is a property read-only?
  $HTML::DOM::Interface{HTMLDocument}{referrer} & READONLY; # true
  
  # Data types of properties
  ($HTML::DOM::Interface{HTMLDocument}{referrer} & TYPE) == STR;  # true
  ($HTML::DOM::Interface{HTMLDocument}{title}    & TYPE) == BOOL; # false
  ($HTML::DOM::Interface{HTMLDocument}{cookie}   & TYPE) == NUM;  # false
  ($HTML::DOM::Interface{HTMLDocument}{forms}    & TYPE) == OBJ;  # true
  
  # and return types of methods:
  ($HTML::DOM::Interface{HTMLDocument}
                           ->{getElementById} & TYPE) == STR;  # false
  ($HTML::DOM::Interface{Node}{hasChildNodes} & TYPE) == BOOL; # true
  ($HTML::DOM::Interface{Node}{appendChild}   & TYPE) == NUM;  # false
  ($HTML::DOM::Interface{Node}{replaceChild}  & TYPE) == OBJ;  # true
  
  # Do these methods have UTF-16 equivalents ending with '16'?
  $HTML::DOM::Interface{Node}{getElementById}      & UTF16;  # false
  $HTML::DOM::Interface{CharacterData}{insertData} & UTF16;  # true
  
  
  # Constants

  # list of constant names in the form "HTML::DOM::Node::ELEMENT_NODE";
  @{ $HTML::DOM::Interface{Node}{_constants} };
  

=head1 DESCRIPTION

The synopsis should tell you almost everything you need to know. But be
warned that C<$foo & TYPE> is meaningless when C<$foo & METHOD> and
C<$foo & VOID> are both true. For more
gory details, look at the source code. In fact, here it is:

=cut

0 and q r

=for ;

  our @EXPORT_OK = qw/METHOD VOID READONLY BOOL STR NUM OBJ TYPE/;
  our %EXPORT_TAGS = (all => \@EXPORT_OK);

  sub METHOD   () {       1 }
  sub VOID     () {    0b10 } # for methods
  sub READONLY () {    0b10 } # for properties
  sub BOOL     () {  0b0000 }
  sub STR      () {  0b0100 }
  sub NUM      () {  0b1000 }
  sub OBJ      () {  0b1100 }
  sub TYPE     () {  0b1100 } # only for use as a mask
  sub UTF16    () { 0b10000 }

  %HTML::DOM::Interface = (
  	'HTML::DOM::Exception' => 'DOMException',
  	'HTML::DOM::Implementation' => 'DOMImplementation',
  	'HTML::DOM::Node' => 'Node',
  	'HTML::DOM::DocumentFragment' => 'DocumentFragment',
  	'HTML::DOM' => 'HTMLDocument',
  	'HTML::DOM::CharacterData' => 'CharacterData',
  	'HTML::DOM::Text' => 'Text',
  	'HTML::DOM::Comment' => 'Comment',
  	'HTML::DOM::Element' => 'HTMLElement',
  	'HTML::DOM::TreeBuilder' => 'HTMLElement',
  	'HTML::DOM::Element::HTML' => 'HTMLHtmlElement',
  	'HTML::DOM::Element::Head' => 'HTMLHeadElement',
  	'HTML::DOM::Element::Link' => 'HTMLLinkElement',
  	'HTML::DOM::Element::Title' => 'HTMLTitleElement',
  	'HTML::DOM::Element::Meta' => 'HTMLMetaElement',
  	'HTML::DOM::Element::Base' => 'HTMLBaseElement',
  	'HTML::DOM::Element::IsIndex' => 'HTMLIsIndexElement',
  	'HTML::DOM::Element::Style' => 'HTMLStyleElement',
  	'HTML::DOM::Element::Body' => 'HTMLBodyElement',
  	'HTML::DOM::Element::Form' => 'HTMLFormElement',
  	'HTML::DOM::Element::Select' => 'HTMLSelectElement',
  	'HTML::DOM::Element::OptGroup' => 'HTMLOptGroupElement',
  	'HTML::DOM::Element::Option' => 'HTMLOptionElement',
  	'HTML::DOM::Element::Input' => 'HTMLInputElement',
  	'HTML::DOM::Element::TextArea' => 'HTMLTextAreaElement',
  	'HTML::DOM::Element::Button' => 'HTMLButtonElement',
  	'HTML::DOM::Element::Label' => 'HTMLLabelElement',
  	'HTML::DOM::Element::FieldSet' => 'HTMLFieldSetElement',
  	'HTML::DOM::Element::Legend' => 'HTMLLegendElement',
  	'HTML::DOM::Element::UL' => 'HTMLUListElement',
  	'HTML::DOM::Element::OL' => 'HTMLOListElement',
  	'HTML::DOM::Element::DL' => 'HTMLDListElement',
  	'HTML::DOM::Element::Dir' => 'HTMLDirectoryElement',
  	'HTML::DOM::Element::Menu' => 'HTMLMenuElement',
  	'HTML::DOM::Element::LI' => 'HTMLLIElement',
  	'HTML::DOM::Element::Div' => 'HTMLDivElement',
  	'HTML::DOM::Element::P' => 'HTMLParagraphElement',
  	'HTML::DOM::Element::Heading' => 'HTMLHeadingElement',
  	'HTML::DOM::Element::Quote' => 'HTMLQuoteElement',
  	'HTML::DOM::Element::Pre' => 'HTMLPreElement',
  	'HTML::DOM::Element::Br' => 'HTMLBRElement',
  	'HTML::DOM::Element::BaseFont' => 'HTMLBaseFontElement',
  	'HTML::DOM::Element::Font' => 'HTMLFontElement',
  	'HTML::DOM::Element::HR' => 'HTMLHRElement',
  	'HTML::DOM::Element::Mod' => 'HTMLModElement',
  	'HTML::DOM::Element::A' => 'HTMLAnchorElement',
  	'HTML::DOM::Element::Img' => 'HTMLImageElement',
  	'HTML::DOM::Element::Object' => 'HTMLObjectElement',
  	'HTML::DOM::Element::Param' => 'HTMLParamElement',
  	'HTML::DOM::Element::Applet' => 'HTMLAppletElement',
  	'HTML::DOM::Element::Map' => 'HTMLMapElement',
  	'HTML::DOM::Element::Area' => 'HTMLAreaElement',
  	'HTML::DOM::Element::Script' => 'HTMLScriptElement',
  	'HTML::DOM::Element::Table' => 'HTMLTableElement',
  	'HTML::DOM::Element::Caption' => 'HTMLTableCaptionElement',
  	'HTML::DOM::Element::TableColumn' => 'HTMLTableColElement',
  	'HTML::DOM::Element::TableSection' => 'HTMLTableSectionElement',
  	'HTML::DOM::Element::TR' => 'HTMLTableRowElement',
  	'HTML::DOM::Element::TableCell' => 'HTMLTableCellElement',
  	'HTML::DOM::Element::FrameSet' => 'HTMLFrameSetElement',
  	'HTML::DOM::Element::Frame' => 'HTMLFrameElement',
  	'HTML::DOM::Element::IFrame' => 'HTMLIFrameElement',
  	'HTML::DOM::NodeList' => 'NodeList',
  	'HTML::DOM::NodeList::Radio' => 'NodeList',
  	'HTML::DOM::NodeList::Magic' => 'NodeList',
  	'HTML::DOM::NamedNodeMap' => 'NamedNodeMap',
  	'HTML::DOM::Attr' => 'Attr',
  	'HTML::DOM::Collection' => 'HTMLCollection',
  	'HTML::DOM::Collection::Elements' => 'HTMLCollection',
  	'HTML::DOM::Collection::Options' => 'HTMLOptionsCollection',
  	'HTML::DOM::Event' => 'Event',
  	'HTML::DOM::View' => 'AbstractView',
  	'HTML::DOM::Event::Mouse' => 'MouseEvent',
  	'HTML::DOM::Event::UI' => 'UIEvent',
  	'HTML::DOM::Event::Mutation' => 'MutationEvent',
  	 DOMException => {
  		code => NUM | READONLY,
  		_constants => [qw[
  			HTML::DOM::Exception::INDEX_SIZE_ERR
  			HTML::DOM::Exception::DOMSTRING_SIZE_ERR
  			HTML::DOM::Exception::HIERARCHY_REQUEST_ERR
  			HTML::DOM::Exception::WRONG_DOCUMENT_ERR
  			HTML::DOM::Exception::INVALID_CHARACTER_ERR
  			HTML::DOM::Exception::NO_DATA_ALLOWED_ERR
  			HTML::DOM::Exception::NO_MODIFICATION_ALLOWED_ERR
  			HTML::DOM::Exception::NOT_FOUND_ERR
  			HTML::DOM::Exception::NOT_SUPPORTED_ERR
  			HTML::DOM::Exception::INUSE_ATTRIBUTE_ERR
  			HTML::DOM::Exception::INVALID_STATE_ERR
  			HTML::DOM::Exception::SYNTAX_ERR
  			HTML::DOM::Exception::INVALID_MODIFICATION_ERR
  			HTML::DOM::Exception::NAMESPACE_ERR
  			HTML::DOM::Exception::INVALID_ACCESS_ERR
  			HTML::DOM::Exception::UNSPECIFIED_EVENT_TYPE_ERR
  		]],
  	 },
  	 DOMImplementation => {
		_hash => 0,
		_array => 0,
  		hasFeature => METHOD | BOOL,
  #		createDocumentType => METHOD | OBJ,
  #		createDocument => METHOD | OBJ,
  #		createCSSStyleSheet => METHOD | OBJ,
  	 },
  	 Node => {
		_hash => 0,
		_array => 0,
  		_constants => [qw[
  			HTML::DOM::Node::ELEMENT_NODE
  			HTML::DOM::Node::ATTRIBUTE_NODE
  			HTML::DOM::Node::TEXT_NODE
  			HTML::DOM::Node::CDATA_SECTION_NODE
  			HTML::DOM::Node::ENTITY_REFERENCE_NODE
  			HTML::DOM::Node::ENTITY_NODE
  			HTML::DOM::Node::PROCESSING_INSTRUCTION_NODE
  			HTML::DOM::Node::COMMENT_NODE
  			HTML::DOM::Node::DOCUMENT_NODE
  			HTML::DOM::Node::DOCUMENT_TYPE_NODE
  			HTML::DOM::Node::DOCUMENT_FRAGMENT_NODE
  			HTML::DOM::Node::NOTATION_NODE
  		]],
  		nodeName => STR | READONLY,
  		nodeValue => STR,
  		nodeType => NUM | READONLY,
  		parentNode => OBJ | READONLY,
  		childNodes => OBJ | READONLY,
  		firstChild => OBJ | READONLY,
  		lastChild => OBJ | READONLY,
  		previousSibling => OBJ | READONLY,
  		nextSibling => OBJ | READONLY,
  		attributes => OBJ | READONLY,
  		ownerDocument => OBJ | READONLY,
  		insertBefore => METHOD | OBJ,
  		replaceChild => METHOD | OBJ,
  		removeChild => METHOD | OBJ,
  		appendChild => METHOD | OBJ,
  		hasChildNodes => METHOD | BOOL,
  		cloneNode => METHOD | OBJ,
  		normalize => METHOD | VOID,
  		isSupported => METHOD | BOOL,
  		namespaceURI => STR | READONLY,
  		prefix => STR,
  		localName => STR | READONLY,
  		hasAttributes => METHOD | BOOL,
  		addEventListener => METHOD | VOID,
  		removeEventListener => METHOD | VOID,
  		dispatchEvent => METHOD | BOOL,
  	 },
  	 NodeList => {
		_hash => 0,
		_array => 1,
  		item => METHOD | OBJ,
  		length => NUM | READONLY,
  	 },
  	 NamedNodeMap => {
		_hash => 0,
		_array => 0,
  		getNamedItem => METHOD | OBJ,
  		setNamedItem => METHOD | OBJ,
  		removeNamedItem => METHOD | OBJ,
  		item => METHOD | OBJ,
  		length => NUM | READONLY,
  #		getNamedItemNS => METHOD | OBJ,
  #		setNamedItemNS => METHOD | OBJ,
  #		removeNamedItemNS => METHOD | OBJ,
  	 },
  	 CharacterData => {
		_isa => 'Node',
		_hash => 0,
		_array => 0,
  		data => STR,
  		length => NUM | READONLY | UTF16,
  		substringData => METHOD | STR | UTF16,
  		appendData => METHOD | VOID,
  		insertData => METHOD | VOID | UTF16,
  		deleteData => METHOD | VOID | UTF16,
  		replaceData => METHOD | VOID | UTF16,
  	 },
  	 Attr => {
		_isa => 'Node',
		_hash => 0,
		_array => 0,
  		name => STR | READONLY,
  		specified => BOOL | READONLY,
  		value => STR,
  		ownerElement => OBJ | READONLY,
  	 },
  	 Text => {
		_isa => 'CharacterData',
		_hash => 0,
		_array => 0,
  		splitText => METHOD | OBJ | UTF16,
  	 },
  	 Comment => {
		_isa => 'CharacterData',
		_hash => 0,
		_array => 0,
  	 },
  	 DocumentFragment => {
		_isa => 'Node',
		_hash => 0,
		_array => 0,
  	 },
  	 HTMLCollection => {
		_hash => 1,
		_array => 1,
  		length => NUM | READONLY,
  		item => METHOD | OBJ,
  		namedItem => METHOD | OBJ,
  	 },
  	 HTMLOptionsCollection => {
		_hash => 1,
		_array => 1,
  		length => NUM,
  		item => METHOD | OBJ,
  		namedItem => METHOD | OBJ,
  	 },
  	 HTMLDocument => {
  		doctype => OBJ | READONLY,
		_hash => 1,
		_array => 0,
  		implementation => OBJ | READONLY,
  		documentElement => OBJ | READONLY,
  		createElement => METHOD | OBJ,
  		createDocumentFragment => METHOD | OBJ,
  		createTextNode => METHOD | OBJ,
  		createComment => METHOD | OBJ,
  		createCDATASection => METHOD | OBJ,
  		createProcessingInstruction => METHOD | OBJ,
  		createAttribute => METHOD | OBJ,
  		createEntityReference => METHOD | OBJ,
  		getElementsByTagName => METHOD | OBJ,
  		importNode => METHOD | OBJ,
  #		createElementNS => METHOD | OBJ,
  #		createAttributeNS => METHOD | OBJ,
  #		getElementsByTagNameNS => METHOD | OBJ,
  		getElementById => METHOD | OBJ,
		_isa => 'Node',
  		title => STR,
  		referrer => STR | READONLY,
  		domain => STR | READONLY,
  		URL => STR | READONLY,
  		body => OBJ,
  		images => OBJ | READONLY,
  		applets => OBJ | READONLY,
  		links => OBJ | READONLY,
  		forms => OBJ | READONLY,
  		anchors => OBJ | READONLY,
  		cookie => STR,
  		open => METHOD | VOID,
  		close => METHOD | VOID,
  		write => METHOD | VOID,
  		writeln => METHOD | VOID,
  		getElementsByName => METHOD | OBJ,
  		createEvent => METHOD | OBJ,
  		defaultView => OBJ | READONLY,
  		styleSheets => OBJ | READONLY,
  #		getOverrideStyle => METHOD | OBJ,
  	 },
  	 HTMLElement => {
  		tagName => STR | READONLY,
		_hash => 0,
		_array => 0,
  		getAttribute => METHOD | STR,
  		setAttribute => METHOD | VOID,
  		removeAttribute => METHOD | VOID,
  		getAttributeNode => METHOD | OBJ,
  		setAttributeNode => METHOD | OBJ,
  		removeAttributeNode => METHOD | OBJ,
  		getElementsByTagName => METHOD | OBJ,
  #		getAttributeNS => METHOD | STR,
  #		setAttributeNS => METHOD | VOID,
  #		removeAttributeNS => METHOD | VOID,
  #		getAttributeNodeNS => METHOD | OBJ,
  #		setAttributeNodeNS => METHOD | OBJ,
  #		getElementsByTagNameNS => METHOD | OBJ,
  		hasAttribute => METHOD | BOOL,
  #		hasAttributeNS => METHOD | BOOL,
		_isa => 'Node',
  		id => STR,
  		title => STR,
  		lang => STR,
  		dir => STR,
  		className => STR,
  		style => OBJ | READONLY,
  	 },
  	 HTMLHtmlElement => {
		_isa => 'HTMLElement',
		_hash => 0,
		_array => 0,
  		version => STR,
  	 },
  	 HTMLHeadElement => {
		_isa => 'HTMLElement',
		_hash => 0,
		_array => 0,
  		profile => STR,
  	 },
  	 HTMLLinkElement => {
		_isa => 'HTMLElement',
		_hash => 0,
		_array => 0,
  		disabled => BOOL,
  		charset => STR,
  		href => STR,
  		hreflang => STR,
  		media => STR,
  		rel => STR,
  		rev => STR,
  		target => STR,
  		type => STR,
  		sheet => OBJ | READONLY,
  	 },
  	 HTMLTitleElement => {
		_isa => 'HTMLElement',
		_hash => 0,
		_array => 0,
  		text => STR,
  	 },
  	 HTMLMetaElement => {
		_isa => 'HTMLElement',
		_hash => 0,
		_array => 0,
  		content => STR,
  		httpEquiv => STR,
  		name => STR,
  		scheme => STR,
  	 },
  	 HTMLBaseElement => {
		_isa => 'HTMLElement',
		_hash => 0,
		_array => 0,
  		href => STR,
  		target => STR,
  	 },
  	 HTMLIsIndexElement => {
		_isa => 'HTMLElement',
		_hash => 0,
		_array => 0,
  		form => OBJ | READONLY,
  		prompt => STR,
  	 },
  	 HTMLStyleElement => {
		_isa => 'HTMLElement',
		_hash => 0,
		_array => 0,
  		disabled => BOOL,
  		media => STR,
  		type => STR,
  		sheet => OBJ | READONLY,
  	 },
  	 HTMLBodyElement => {
		_isa => 'HTMLElement',
		_hash => 0,
		_array => 0,
  		aLink => STR,
  		background => STR,
  		bgColor => STR,
  		link => STR,
  		text => STR,
  		vLink => STR,
  	 },
  	 HTMLFormElement => {
		_isa => 'HTMLElement',
		_hash => 1,
		_array => 1,
  		elements => OBJ | READONLY,
  		length => NUM | READONLY,
  		name => STR,
  		acceptCharset => STR,
  		action => STR,
  		enctype => STR,
  		method => STR,
  		target => STR,
  		submit => METHOD | VOID,
  		reset => METHOD | VOID,
  	 },
  	 HTMLSelectElement => {
		_isa => 'HTMLElement',
		_hash => 0,
		_array => 0,
  		type => STR | READONLY,
  		selectedIndex => NUM,
  		value => STR,
  		length => NUM,
  		form => OBJ | READONLY,
  		options => OBJ | READONLY,
  		disabled => BOOL,
  		multiple => BOOL,
  		name => STR,
  		size => NUM,
  		tabIndex => NUM,
  		add => METHOD | VOID,
  		remove => METHOD | VOID,
  		blur => METHOD | VOID,
  		focus => METHOD | VOID,
  	 },
  	 HTMLOptGroupElement => {
		_isa => 'HTMLElement',
		_hash => 0,
		_array => 0,
  		disabled => BOOL,
  		label => STR,
  	 },
  	 HTMLOptionElement => {
		_isa => 'HTMLElement',
		_hash => 0,
		_array => 0,
  		form => OBJ | READONLY,
  		defaultSelected => BOOL,
  		text => STR | READONLY,
  		index => NUM,
  		disabled => BOOL,
  		label => STR,
  		selected => BOOL,
  		value => STR,
  	 },
  	 HTMLInputElement => {
		_isa => 'HTMLElement',
		_hash => 0,
		_array => 0,
  		defaultValue => STR,
  		defaultChecked => BOOL,
  		form => OBJ | READONLY,
  		accept => STR,
  		accessKey => STR,
  		align => STR,
  		alt => STR,
  		checked => BOOL,
  		disabled => BOOL,
  		maxLength => NUM,
  		name => STR,
  		readOnly => BOOL,
  		size => NUM,
  		src => STR,
  		tabIndex => NUM,
  		type => STR,
  		useMap => STR,
  		value => STR,
  		blur => METHOD | VOID,
  		focus => METHOD | VOID,
  		select => METHOD | VOID,
  		click => METHOD | VOID,
  	 },
  	 HTMLTextAreaElement => {
		_isa => 'HTMLElement',
		_hash => 0,
		_array => 0,
  		defaultValue => STR,
  		form => OBJ | READONLY,
  		accessKey => STR,
  		cols => NUM,
  		disabled => BOOL,
  		name => STR,
  		readOnly => BOOL,
  		rows => NUM,
  		tabIndex => NUM,
  		type => STR | READONLY,
  		value => STR,
  		blur => METHOD | VOID,
  		focus => METHOD | VOID,
  		select => METHOD | VOID,
  	 },
  	 HTMLButtonElement => {
		_isa => 'HTMLElement',
		_hash => 0,
		_array => 0,
  		form => OBJ | READONLY,
  		accessKey => STR,
  		disabled => BOOL,
  		name => STR,
  		tabIndex => NUM,
  		type => STR | READONLY,
  		value => STR,
  	 },
  	 HTMLLabelElement => {
		_isa => 'HTMLElement',
		_hash => 0,
		_array => 0,
  		form => OBJ | READONLY,
  		accessKey => STR,
  		htmlFor => STR,
  	 },
  	 HTMLFieldSetElement => {
		_isa => 'HTMLElement',
		_hash => 0,
		_array => 0,
  		form => OBJ | READONLY,
  	 },
  	 HTMLLegendElement => {
		_isa => 'HTMLElement',
		_hash => 0,
		_array => 0,
  		form => OBJ | READONLY,
  		accessKey => STR,
  		align => STR,
  	 },
  	 HTMLUListElement => {
		_isa => 'HTMLElement',
		_hash => 0,
		_array => 0,
  		compact => BOOL,
  		type => STR,
  	 },
  	 HTMLOListElement => {
		_isa => 'HTMLElement',
		_hash => 0,
		_array => 0,
  		compact => BOOL,
  		start => NUM,
  		type => STR,
  	 },
  	 HTMLDListElement => {
		_isa => 'HTMLElement',
		_hash => 0,
		_array => 0,
  		compact => BOOL,
  	 },
  	 HTMLDirectoryElement => {
		_isa => 'HTMLElement',
		_hash => 0,
		_array => 0,
  		compact => BOOL,
  	 },
  	 HTMLMenuElement => {
		_isa => 'HTMLElement',
		_hash => 0,
		_array => 0,
  		compact => BOOL,
  	 },
  	 HTMLLIElement => {
		_isa => 'HTMLElement',
		_hash => 0,
		_array => 0,
  		type => STR,
  		value => NUM,
  	 },
  	 HTMLDivElement => {
		_isa => 'HTMLElement',
		_hash => 0,
		_array => 0,
  		align => STR,
  	 },
  	 HTMLParagraphElement => {
		_isa => 'HTMLElement',
		_hash => 0,
		_array => 0,
  		align => STR,
  	 },
  	 HTMLHeadingElement => {
		_isa => 'HTMLElement',
		_hash => 0,
		_array => 0,
  		align => STR,
  	 },
  	 HTMLQuoteElement => {
		_isa => 'HTMLElement',
		_hash => 0,
		_array => 0,
  		cite => STR,
  	 },
  	 HTMLPreElement => {
		_isa => 'HTMLElement',
		_hash => 0,
		_array => 0,
  		width => NUM,
  	 },
  	 HTMLBRElement => {
		_isa => 'HTMLElement',
		_hash => 0,
		_array => 0,
  		clear => STR,
  	 },
  	 HTMLBaseFontElement => {
		_isa => 'HTMLElement',
		_hash => 0,
		_array => 0,
  		color => STR,
  		face => STR,
  		size => NUM,
  	 },
  	 HTMLFontElement => {
		_isa => 'HTMLElement',
		_hash => 0,
		_array => 0,
  		color => STR,
  		face => STR,
  		size => STR,
  	 },
  	 HTMLHRElement => {
		_isa => 'HTMLElement',
		_hash => 0,
		_array => 0,
  		align => STR,
  		noShade => BOOL,
  		size => STR,
  		width => STR,
  	 },
  	 HTMLModElement => {
		_isa => 'HTMLElement',
		_hash => 0,
		_array => 0,
  		cite => STR,
  		dateTime => STR,
  	 },
  	 HTMLAnchorElement => {
		_isa => 'HTMLElement',
		_hash => 0,
		_array => 0,
  		accessKey => STR,
  		charset => STR,
  		coords => STR,
  		href => STR,
  		hreflang => STR,
  		name => STR,
  		rel => STR,
  		rev => STR,
  		shape => STR,
  		tabIndex => NUM,
  		target => STR,
  		type => STR,
  		blur => METHOD | VOID,
  		focus => METHOD | VOID,
  	 },
  	 HTMLImageElement => {
		_isa => 'HTMLElement',
		_hash => 0,
		_array => 0,
  		name => STR,
  		align => STR,
  		alt => STR,
  		border => STR,
  		height => NUM,
  		hspace => NUM,
  		isMap => BOOL,
  		longDesc => STR,
  		src => STR,
  		useMap => STR,
  		vspace => NUM,
  		width => NUM,
  		lowSrc => STR,
  	 },
  	 HTMLObjectElement => {
		_isa => 'HTMLElement',
		_hash => 0,
		_array => 0,
  		form => OBJ | READONLY,
  		code => STR,
  		align => STR,
  		archive => STR,
  		border => STR,
  		codeBase => STR,
  		codeType => STR,
  		data => STR,
  		declare => BOOL,
  		height => STR,
  		hspace => NUM,
  		name => STR,
  		standby => STR,
  		tabIndex => NUM,
  		type => STR,
  		useMap => STR,
  		vspace => NUM,
  		width => STR,
  		contentDocument => OBJ | READONLY,
  	 },
  	 HTMLParamElement => {
		_isa => 'HTMLElement',
		_hash => 0,
		_array => 0,
  		name => STR,
  		type => STR,
  		value => STR,
  		valueType => STR,
  	 },
  	 HTMLAppletElement => {
		_isa => 'HTMLElement',
		_hash => 0,
		_array => 0,
  		align => STR,
  		alt => STR,
  		archive => STR,
  		code => STR,
  		codeBase => STR,
  		height => STR,
  		hspace => NUM,
  		name => STR,
  		object => STR,
  		vspace => NUM,
  		width => STR,
  	 },
  	 HTMLMapElement => {
		_isa => 'HTMLElement',
		_hash => 0,
		_array => 0,
  		areas => OBJ | READONLY,
  		name => STR,
  	 },
  	 HTMLAreaElement => {
		_isa => 'HTMLElement',
		_hash => 0,
		_array => 0,
  		accessKey => STR,
  		alt => STR,
  		coords => STR,
  		href => STR,
  		noHref => BOOL,
  		shape => STR,
  		tabIndex => NUM,
  		target => STR,
  	 },
  	 HTMLScriptElement => {
		_isa => 'HTMLElement',
		_hash => 0,
		_array => 0,
  		text => STR,
  		htmlFor => STR,
  		event => STR,
  		charset => STR,
  		defer => BOOL,
  		src => STR,
  		type => STR,
  	 },
  	 HTMLTableElement => {
		_isa => 'HTMLElement',
		_hash => 0,
		_array => 0,
  		caption => OBJ,
  		tHead => OBJ,
  		tFoot => OBJ,
  		rows => OBJ | READONLY,
  		tBodies => OBJ | READONLY,
  		align => STR,
  		bgColor => STR,
  		border => STR,
  		cellPadding => STR,
  		cellSpacing => STR,
  		frame => STR,
  		rules => STR,
  		summary => STR,
  		width => STR,
  		createTHead => METHOD | OBJ,
  		deleteTHead => METHOD | VOID,
  		createTFoot => METHOD | OBJ,
  		deleteTFoot => METHOD | VOID,
  		createCaption => METHOD | OBJ,
  		deleteCaption => METHOD | VOID,
  		insertRow => METHOD | OBJ,
  		deleteRow => METHOD | VOID,
  	 },
  	 HTMLTableCaptionElement => {
		_isa => 'HTMLElement',
		_hash => 0,
		_array => 0,
  		align => STR,
  	 },
  	 HTMLTableColElement => {
		_isa => 'HTMLElement',
		_hash => 0,
		_array => 0,
  		align => STR,
  		ch => STR,
  		chOff => STR,
  		span => NUM,
  		vAlign => STR,
  		width => STR,
  	 },
  	 HTMLTableSectionElement => {
		_isa => 'HTMLElement',
		_hash => 0,
		_array => 0,
  		align => STR,
  		ch => STR,
  		chOff => STR,
  		vAlign => STR,
  		rows => OBJ | READONLY,
  		insertRow => METHOD | OBJ,
  		deleteRow => METHOD | VOID,
  	 },
  	 HTMLTableRowElement => {
		_isa => 'HTMLElement',
		_hash => 0,
		_array => 0,
  		rowIndex => NUM | READONLY,
  		sectionRowIndex => NUM | READONLY,
  		cells => OBJ | READONLY,
  		align => STR,
  		bgColor => STR,
  		ch => STR,
  		chOff => STR,
  		vAlign => STR,
  		insertCell => METHOD | OBJ,
  		deleteCell => METHOD | VOID,
  	 },
  	 HTMLTableCellElement => {
		_isa => 'HTMLElement',
		_hash => 0,
		_array => 0,
  		cellIndex => NUM | READONLY,
  		abbr => STR,
  		align => STR,
  		axis => STR,
  		bgColor => STR,
  		ch => STR,
  		chOff => STR,
  		colSpan => NUM,
  		headers => STR,
  		height => STR,
  		noWrap => BOOL,
  		rowSpan => NUM,
  		scope => STR,
  		vAlign => STR,
  		width => STR,
  	 },
  	 HTMLFrameSetElement => {
		_isa => 'HTMLElement',
		_hash => 0,
		_array => 0,
  		cols => STR,
  		rows => STR,
  	 },
  	 HTMLFrameElement => {
		_isa => 'HTMLElement',
		_hash => 0,
		_array => 0,
  		frameBorder => STR,
  		longDesc => STR,
  		marginHeight => STR,
  		marginWidth => STR,
  		name => STR,
  		noResize => BOOL,
  		scrolling => STR,
  		src => STR,
  		contentDocument => OBJ | READONLY,
  	 },
  	 HTMLIFrameElement => {
		_isa => 'HTMLElement',
		_hash => 0,
		_array => 0,
  		align => STR,
  		frameBorder => STR,
  		height => STR,
  		longDesc => STR,
  		marginHeight => STR,
  		marginWidth => STR,
  		name => STR,
  		scrolling => STR,
  		src => STR,
  		width => STR,
  		contentDocument => OBJ | READONLY,
  	 },
  	 Event => {
		_hash => 0,
		_array => 0,
  		_constants => [qw[
  			HTML::DOM::Event::CAPTURING_PHASE
  			HTML::DOM::Event::AT_TARGET
  			HTML::DOM::Event::BUBBLING_PHASE
  		]],
  		type => STR | READONLY,
  		target => OBJ | READONLY,
  		currentTarget => OBJ | READONLY,
  		eventPhase => NUM | READONLY,
  		bubbles => BOOL | READONLY,
  		cancelable => BOOL | READONLY,
  		timeStamp => OBJ | READONLY,
  		stopPropagation => METHOD | VOID,
  		preventDefault => METHOD | VOID,
  		initEvent => METHOD | VOID,
  	 },
  	 UIEvent => {
		_isa => 'Event',
		_hash => 0,
		_array => 0,
  		view => OBJ | READONLY,
  		detail => NUM | READONLY,
  		initUIEvent => METHOD | VOID,
  	 },
  	 MouseEvent => {
		_isa => 'UIEvent',
		_hash => 0,
		_array => 0,
  		screenX => NUM | READONLY,
  		screenY => NUM | READONLY,
  		clientX => NUM | READONLY,
  		clientY => NUM | READONLY,
  		ctrlKey => BOOL | READONLY,
  		shiftKey => BOOL | READONLY,
  		altKey => BOOL | READONLY,
  		metaKey => BOOL | READONLY,
  		button => NUM | READONLY,
  		relatedTarget => OBJ | READONLY,
  		initMouseEvent => METHOD | VOID,
  	 },
  	 MutationEvent => {
		_isa => 'Event',
		_hash => 0,
		_array => 0,
  		_constants => [qw[
  			HTML::DOM::Event::Mutation::MODIFICATION
  			HTML::DOM::Event::Mutation::ADDITION
  			HTML::DOM::Event::Mutation::REMOVAL
  		]],
  		relatedNode => OBJ | READONLY,
  		prevValue => STR | READONLY,
  		newValue => STR | READONLY,
  		attrName => STR | READONLY,
  		attrChange => NUM | READONLY,
  		initMutationEvent => METHOD | VOID,
  	 },
  	 AbstractView => {
		_hash => 0,
		_array => 0,
  		document => OBJ | READONLY,
  #		getComputedStyle => METHOD | OBJ,
  	 },
  );

__END__

=head1 SEE ALSO

L<HTML::DOM>
