#!/opt/ruby/1.8/bin/ruby

require 'test/unit'

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'pl'
require 'plparser'

class TestPL < Test::Unit::TestCase
  
  def test_parser
    str="(VTITLE a vtitle)
(COMMENT a comment)
(FAMILY a-family__)
(CODINGSCHEME AdobeStandardEncoding + ECEncoding)
(DESIGNSIZE R 10.0)
(DESIGNUNITS R 1000)
(COMMENT DESIGNSIZE (1 em) IS IN POINTS)
(COMMENT OTHER DIMENSIONS ARE MULTIPLES OF DESIGNSIZE/1000)
(FONTDIMEN
   (SPACE D 300)
   (STRETCH D 200)
   (SHRINK D 100)
   (XHEIGHT D 415)
   (QUAD D 1000)
   (EXTRASPACE D 111)
   )
"
    pl=PL.new(false)
    pl.parse(str)
    assert_equal("a vtitle",pl.vtitle)
  end
  def test_writer
    pl=PL.new(false)
    pl.insert_or_change(:family,"foo")
    npl=PL.new(false)
    npl.parse(pl.to_s)
    assert_equal("foo",npl.family)
    
    pl.insert_or_change(:family,"bar")
    npl=PL.new(false)
    npl.parse(pl.to_s)
    assert_equal("bar",npl.family)
  end
  def test_array
    str="(VTITLE Created by afm2tfm savorg__.afm -T ec.enc -V foo.vpl -c 0.5)
(COMMENT Please edit that VTITLE if you edit this file)
(FAMILY TeX-savorg__-CSC)
(CODINGSCHEME ECEncoding)
(DESIGNSIZE R 10.0)
(DESIGNUNITS R 1000)
(COMMENT DESIGNSIZE (1 em) IS IN POINTS)
(COMMENT OTHER DIMENSIONS ARE MULTIPLES OF DESIGNSIZE/1000)
(FONTDIMEN
   (SPACE D 300)
   (STRETCH D 200)
   (SHRINK D 100)
   (XHEIGHT D 415)
   (QUAD D 1000)
   (EXTRASPACE D 111)
   )
(MAPFONT D 0
   (FONTNAME savorg__)
   )
(MAPFONT D 1
   (FONTNAME savorg__)
   (FONTAT D 500)
   )
(LIGTABLE
   (LABEL O 55) (comment hyphen)
   (LABEL O 177) (comment hyphen)
   (LIG O 55 O 25)
   (LIG O 177 O 25)
   (KRN O 34 R 11) (comment fi)
   (KRN C Y R -42)
   (KRN C y R -21.0)
   (KRN C W R -31)
   (KRN C w R -15.5)
   (KRN C V R -23)
   (KRN C v R -11.5)
   (KRN C T R -48)
   (KRN C t R -24.0)
   (KRN C A R 21)
   (KRN C a R 10.5)
   (STOP)
 )
(CHARACTER O 177 (comment hyphen)
   (CHARWD R 207)
   (CHARHT R 240)
   )
(CHARACTER O 212 (comment Lslash)
   (CHARWD R 561)
   (CHARHT R 669)
   (CHARDP R 2)
   (CHARIC R 12)
   )
(CHARACTER O 222 (comment Scaron)
   (CHARWD R 468)
   (CHARHT R 870)
   (CHARDP R 13)
   )
"
    pl = PL.new
    pl.parse(str)
    a={:charht=>240.0,
       :charwd=>207.0,
       :comment=>"hyphen",
       :krn=> [[28, 11.0],
        [89, -42.0],
        [121, -21.0],
        [87, -31.0],
        [119, -15.5],
        [86, -23.0],
        [118, -11.5],
        [84, -48.0],
        [116, -24.0],
        [65, 21.0],
        [97, 10.5]],
       :lig=> [[45, 21], [127, 21]]}
    assert_equal(a,pl[127])
    a[:charwd]=400
    pl[127]=a
    assert_equal(400,pl[127][:charwd])
  end
end
