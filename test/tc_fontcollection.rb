#!/opt/ruby/1.8/bin/ruby

require 'test/unit'

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'fontcollection'
require 'font'

class TestFontCollection < Test::Unit::TestCase
  
  def test_startup
    fc=FontCollection.new('Helvetica')
  end
  def test_register
    fc=FontCollection.new('Helvetica')
    # needs font object
    assert_raise(ArgumentError) {
      fc.register_font("foo")
    }
    f=Font.new(fc)
    # p fc.write_mapfile
  end
end
