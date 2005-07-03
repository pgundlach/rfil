#!/opt/ruby/1.8/bin/ruby

require 'tempfile'
require 'test/unit'

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'enc'

class TestENC < Test::Unit::TestCase

  def test_startup
    f=Tempfile.new("tc_enc")
    f << <<EOS
% testenc.enc
% to test the encoding reader class
% 
% LIGKERN space l =: lslash ; space L =: Lslash ;
% LIGKERN question quoteleft =: questiondown ; exclam quoteleft =: exclamdown ;
% LIGKERN hyphen hyphen =: endash ; endash hyphen =: emdash ;
% LIGKERN quoteleft quoteleft =: quotedblleft ;
% LIGKERN quoteright quoteright =: quotedblright ;
%
/TeStencoding [
% 0x00
 /.notdef /dotaccent /fi /fl
 /fraction /hungarumlaut /Lslash /lslash
 /ogonek /ring /.notdef /breve
 /minus /.notdef /Zcaron /zcaron
% 0x10
 /caron /dotlessi /dotlessj /ff
 /ffi /ffl /notequal /infinity
 /lessequal /greaterequal /partialdiff /summation
 /product /pi /grave /quotesingle
% 0x20
 /space /exclam /quotedbl /numbersign
 /dollar /percent /ampersand /quoteright
 /parenleft /parenright /asterisk /plus
 /comma /hyphen /period /slash
% 0x30
 /zero /one /two /three
 /four /five /six /seven
 /eight /nine /colon /semicolon
 /less /equal /greater /question
% 0x40
 /at /A /B /C
 /D /E /F /G
 /H /I /J /K
 /L /M /N /O
% 0x50
 /P /Q /R /S
 /T /U /V /W
 /X /Y /Z /bracketleft
 /backslash /bracketright /asciicircum /underscore
% 0x60
 /quoteleft /a /b /c
 /d /e /f /g
 /h /i /j /k
 /l /m /n /o
% 0x70
 /p /q /r /s
 /t /u /v /w
 /x /y /z /braceleft
 /bar /braceright /asciitilde /.notdef
% 0x80
 /Euro /integral /quotesinglbase /florin
 /quotedblbase /ellipsis /dagger /daggerdbl
 /circumflex /perthousand /Scaron /guilsinglleft
 /OE /Omega /radical /approxequal
% 0x90
 /.notdef /.notdef /.notdef /quotedblleft
 /quotedblright /bullet /endash /emdash
 /tilde /trademark /scaron /guilsinglright
 /oe /Delta /lozenge /Ydieresis
% 0xA0
 /.notdef /exclamdown /cent /sterling
 /currency /yen /brokenbar /section
 /dieresis /copyright /ordfeminine /guillemotleft
 /logicalnot /hyphen /registered /macron
% 0xD0
 /degree /plusminus /twosuperior /threesuperior
 /acute /mu /paragraph /periodcentered
 /cedilla /onesuperior /ordmasculine /guillemotright
 /onequarter /onehalf /threequarters /questiondown
% 0xC0
 /Agrave /Aacute /Acircumflex /Atilde
 /Adieresis /Aring /AE /Ccedilla
 /Egrave /Eacute /Ecircumflex /Edieresis
 /Igrave /Iacute /Icircumflex /Idieresis
% 0xD0
 /Eth /Ntilde /Ograve /Oacute
 /Ocircumflex /Otilde /Odieresis /multiply
 /Oslash /Ugrave /Uacute /Ucircumflex
 /Udieresis /Yacute /Thorn /germandbls
%
%
% LIGKERN space {} * ; * {} space ; zero {} * ; * {} zero ;
% LIGKERN one {} * ; * {} one ; two {} * ; * {} two ;
% LIGKERN three {} * ; * {} three ; four {} * ; * {} four ;
%
% 0xE0
 /agrave /aacute /acircumflex /atilde
 /adieresis /aring /ae /ccedilla
 /egrave /eacute /ecircumflex /edieresis
 /igrave /iacute /icircumflex /idieresis
% 0xF0
 /eth /ntilde /ograve /oacute
 /ocircumflex /otilde /odieresis /divide
 /oslash /ugrave /uacute /ucircumflex
 /udieresis /yacute /thorn /ydieresis
] def

% LIGKERN five {} * ; * {} five ; six {} * ; * {} six ;
% LIGKERN seven {} * ; * {} seven ; eight {} * ; * {} eight ;
% LIGKERN nine {} * ; * {} nine ;
% LIGKERN comma comma =: quotedblbase ; less less =: guillemotleft ;
% LIGKERN greater greater =: guillemotright ;
EOS
    f.open
    a=ENC.new(f)
    f.close
    encv=[".notdef", "dotaccent", "fi", "fl", "fraction", "hungarumlaut", "Lslash", "lslash", "ogonek", "ring", ".notdef", "breve", "minus", ".notdef", "Zcaron", "zcaron", "caron", "dotlessi", "dotlessj", "ff", "ffi", "ffl", "notequal", "infinity", "lessequal", "greaterequal", "partialdiff", "summation", "product", "pi", "grave", "quotesingle", "space", "exclam", "quotedbl", "numbersign", "dollar", "percent", "ampersand", "quoteright", "parenleft", "parenright", "asterisk", "plus", "comma", "hyphen", "period", "slash", "zero", "one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "colon", "semicolon", "less", "equal", "greater", "question", "at", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z", "bracketleft", "backslash", "bracketright", "asciicircum", "underscore", "quoteleft", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "braceleft", "bar", "braceright", "asciitilde", ".notdef", "Euro", "integral", "quotesinglbase", "florin", "quotedblbase", "ellipsis", "dagger", "daggerdbl", "circumflex", "perthousand", "Scaron", "guilsinglleft", "OE", "Omega", "radical", "approxequal", ".notdef", ".notdef", ".notdef", "quotedblleft", "quotedblright", "bullet", "endash", "emdash", "tilde", "trademark", "scaron", "guilsinglright", "oe", "Delta", "lozenge", "Ydieresis", ".notdef", "exclamdown", "cent", "sterling", "currency", "yen", "brokenbar", "section", "dieresis", "copyright", "ordfeminine", "guillemotleft", "logicalnot", "hyphen", "registered", "macron", "degree", "plusminus", "twosuperior", "threesuperior", "acute", "mu", "paragraph", "periodcentered", "cedilla", "onesuperior", "ordmasculine", "guillemotright", "onequarter", "onehalf", "threequarters", "questiondown", "Agrave", "Aacute", "Acircumflex", "Atilde", "Adieresis", "Aring", "AE", "Ccedilla", "Egrave", "Eacute", "Ecircumflex", "Edieresis", "Igrave", "Iacute", "Icircumflex", "Idieresis", "Eth", "Ntilde", "Ograve", "Oacute", "Ocircumflex", "Otilde", "Odieresis", "multiply", "Oslash", "Ugrave", "Uacute", "Ucircumflex", "Udieresis", "Yacute", "Thorn", "germandbls", "agrave", "aacute", "acircumflex", "atilde", "adieresis", "aring", "ae", "ccedilla", "egrave", "eacute", "ecircumflex", "edieresis", "igrave", "iacute", "icircumflex", "idieresis", "eth", "ntilde", "ograve", "oacute", "ocircumflex", "otilde", "odieresis", "divide", "oslash", "ugrave", "uacute", "ucircumflex", "udieresis", "yacute", "thorn", "ydieresis"]
    instructions=["space l =: lslash", "space L =: Lslash", "question quoteleft =: questiondown", "exclam quoteleft =: exclamdown", "hyphen hyphen =: endash", "endash hyphen =: emdash", "quoteleft quoteleft =: quotedblleft", "quoteright quoteright =: quotedblright", "space {} *", "* {} space", "zero {} *", "* {} zero", "one {} *", "* {} one", "two {} *", "* {} two", "three {} *", "* {} three", "four {} *", "* {} four", "five {} *", "* {} five", "six {} *", "* {} six", "seven {} *", "* {} seven", "eight {} *", "* {} eight", "nine {} *", "* {} nine", "comma comma =: quotedblbase", "less less =: guillemotleft", "greater greater =: guillemotright"]
    assert_equal(a.encvector,encv)
    assert_equal(a.encname,"TeStencoding")
    
    # order should not be important
    a.ligkern_instructions.each { |i|
      assert(instructions.member?(i))
    }
    assert_equal(a.glyph_index['hyphen'],[45,173])
  end
  def test_stringenc
    strenc= <<enc
/TeXtext [
% 0x00
/Gamma /Delta /Theta /Lambda /Xi /Pi /Sigma /Upsilon
/Phi /Psi /Omega /arrowup /arrowdown /quotesingle /exclamdown /questiondown
% 0x10
/dotlessi /dotlessj /grave /acute /caron /breve /macron /ring
/cedilla /germandbls /ae /oe /oslash /AE /OE /Oslash
% 0x20
/space /exclam /quotedbl /numbersign /dollar /percent /ampersand /quoteright
/parenleft /parenright /asterisk /plus /comma /hyphen /period /slash
% 0x30
/zero /one /two /three /four /five /six /seven
/eight /nine /colon /semicolon /less /equal /greater /question
% 0x40
/at /A /B /C /D /E /F /G
/H  /I /J /K /L /M /N /O 
% 0x50
/P /Q /R /S /T /U /V /W
/X /Y /Z /bracketleft /backslash /bracketright /circumflex /underscore
% 0x60
/quoteleft /a /b /c /d /e /f /g
/h /i /j /k /l /m /n /o
% 0x70
/p /q /r /s /t /u /v /w
/x /y /z /braceleft /bar /braceright /tilde /dieresis
% 0x80
/.notdef /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef
/.notdef /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef
% 0x90
/.notdef /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef
/.notdef /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef
% 0xA0
/.notdef /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef
/.notdef /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef
% 0xB0
/.notdef /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef
/.notdef /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef
% 0xC0
/.notdef /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef
/.notdef /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef
% 0xD0
/.notdef /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef
/.notdef /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef
% 0xE0
/.notdef /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef
/.notdef /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef
% 0xF0
/.notdef /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef
/.notdef /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef /.notdef
] def
enc
    a=ENC.new(strenc)
    assert_equal("TeXtext",a.encname)
    assert_equal("space",a.encvector[32])
    assert_equal([24],a.glyph_index['cedilla'])
  end

  def test_build_enc
    a=ENC.new()
    a.encname="Minienc"
    a.encvector[0]=".notdef"
    a.encvector[1]="A"
    a.encvector[2]="b"
    a.encvector[3]="germandbls"
    a.encvector[4]="ae"
    a.encvector[5]="AE"
    a.encvector[6]="dotlessi"
    a.encvector[7]="hyphen"
    a.encvector[8]="hyphen"
    a.update_glyph_index
    assert_equal({"dotlessi"=>[6], "germandbls"=>[3], "A"=>[1],
                   "b"=>[2], "AE"=>[5], "ae"=>[4],
                   "hyphen"=>[7, 8],},a.glyph_index)
    a.filename="minienc"
    assert_equal("minienc.enc",a.filename)
    a.filename="minienc.enc"
    assert_equal("minienc.enc",a.filename)
    
  end
end
