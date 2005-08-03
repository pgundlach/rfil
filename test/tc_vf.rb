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
#    assert_equal([{:scale=>1.0, :designsize=>10.0, :name=>"phvr8r",
#                    :area=>nil, :checksum=>1570792142}], vf.fontlist)

    assert_raise(Errno::EEXIST) {
      vf.save
    }

    vf.pathname="/tmp/newvf.vf"
#    vf.designsize=10.12345
#    vf.chars[254][:charht]=0.712493
#    vf.chars[255][:charht]=0.712492
    str=""
    vf.save(true)
    # vf.write_file(str)
    pp str
  end

end
