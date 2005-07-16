#!/opt/ruby/1.8/bin/ruby

require 'test/unit'

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'fontcollection'
require 'font'

class TestFontCollection < Test::Unit::TestCase

  def setup
    @fc=FontCollection.new()
  end
  def test_register
    # needs font object
    assert_raise(ArgumentError) {
      @fc.register_font()
    }
  end
  def test_encodings
    @fc.mapenc="8r"
    @fc.texenc=["ec","texnansi"]
    assert_equal("TeXBase1Encoding",@fc.mapenc.encname)
    @fc.texenc.each {|enc|
      assert(["ECEncoding","TeXnANSIEncoding"].member?(enc.encname))
    }
  end
end
