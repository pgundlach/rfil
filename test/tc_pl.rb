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
end
