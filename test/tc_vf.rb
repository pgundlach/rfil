#!/opt/ruby/1.8/bin/ruby 

require 'test/unit'

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'pp'
require 'vf'

class TestVF < Test::Unit::TestCase
  def test_read
    filename="tricky2.vf"
    vf=VF.new
    vf.read_file(filename)
    assert_equal("tricky2.vf", vf.filename)
    assert_equal([{:scale=>1.0, :designsize=>10.0, :name=>"phvr8r", :checksum=>0}], vf.fontlist)
  end

end
