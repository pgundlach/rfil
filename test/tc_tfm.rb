#!/opt/ruby/1.8/bin/ruby 

require 'test/unit'

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'pp'
require 'tfm'

class TestTFM < Test::Unit::TestCase
  def test_read
    filename="tricky.tfm"
    f=File.open(filename)
    tfm=TFM.new
    tfm.read_file(f)
    f.close
    p tfm.fontfamily
  end

end
