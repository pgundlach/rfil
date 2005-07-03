#!/opt/ruby/1.8/bin/ruby

require 'test/unit'

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'afm'

class TestFont < Test::Unit::TestCase
  
  def test_startup
    a=AFM.new
  end

  def test_read
    a=AFM.new
    a.read("savorg__.afm")
  end
end
