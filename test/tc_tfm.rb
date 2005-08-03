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
    # tfm.verbose=true
    tfm.read_file(f)
    f.close
    
    assert_equal("tricky.tfm",tfm.filename)
    assert_equal(10.0,tfm.designsize)
    assert_equal(256,tfm.chars.size)
  end
  def test_write
    filename="tricky.tfm"
    f=File.open(filename)
    tfm=TFM.new
    # tfm.verbose=true
    tfm.read_file(f)
    f.close
    assert_raise(Errno::EEXIST) {
      tfm.save
    }

    tfm.pathname="/tmp/newtfm.tfm"
    tfm.designsize=10.12345
    tfm.chars[254][:charht]=0.712493
    tfm.chars[255][:charht]=0.712492
     tfm.save(true)
    str=""
    tfm.write_file(str)
    # pp str
#     filename="/tmp/newtfm.tfm"
#     f=File.open(filename)
#     tfm=TFM.new
#     tfm.verbose=true
#     tfm.read_file(f)
#     f.close
    
  end

end
