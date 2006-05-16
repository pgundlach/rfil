#!/opt/ruby/1.8/bin/ruby

require 'test/unit'

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'font/truetype'

class TestTrueType < Test::Unit::TestCase
  
  def test_startup
    t=Font::TrueType.new
    t.read("dustismo_roman.ttf")
  end

end
