#!/opt/ruby/1.8/bin/ruby

require 'test/unit'

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'afm'

class TestFont < Test::Unit::TestCase
  
  def test_read
    a=nil
    File.open("savorg__.afm") { |f|
      a=AFM.new(f)
    }
    assert_equal(244,a.count_charmetrics)
    assert_equal("AdobeStandardEncoding", a.encodingscheme)
    str= a.to_s
    b=AFM.new(str)
    assert_equal(a.count_charmetrics,b.count_charmetrics)
    assert_equal(a.encodingscheme,b.encodingscheme)
  end
end
