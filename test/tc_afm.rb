#!/opt/ruby/1.8/bin/ruby -w

require 'test/unit'

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'font/afm'

class TestFont < Test::Unit::TestCase
  
  def test_some
    a=Font::AFM.new
    a.read("savorg__.afm")
    assert_equal(244,a.count_charmetrics)
    assert_equal("AdobeStandardEncoding", a.encodingscheme)
    assert_equal("savorg__.afm",a.filename)
    assert_match(/test\/savorg__\.afm$/, a.pathname)
    assert_raise(NoMethodError) { a.filename="foo" }
    a.pathname="foo/bar"
    assert_equal("bar", a.filename)
    str= a.to_s
    b=Font::AFM.new
    b.parse(str)
    assert_equal(a.count_charmetrics,b.count_charmetrics)
    assert_equal(a.encodingscheme,b.encodingscheme)
  end
end
