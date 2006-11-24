#!/opt/ruby/1.8/bin/ruby 

require 'test/unit'
require 'fileutils'

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'tex/tfm'


class TestTFM < Test::Unit::TestCase
  def test_parse
    t=TeX::TFM.new
    t.read_pl("tricky.pl")
    assert_equal("TEXBASE1ENCODING", t.codingscheme)
    assert_equal(0.0,t.params[1])
    assert_equal(0.27799,t.params[2])
    assert_equal({:chardp=>0.212995, :lig_kern=>73, :charwd=>0.5, :charht=>0.533997},t.chars[231])
    assert_equal({:chardp=>0.212995, :charwd=>0.5, :charht=>0.712493},t.chars[255])
  end
  def test_read
    filename="tricky.tfm"
    assert(FileUtils.uptodate?(filename, filename.chomp('.tfm')+'.pl'),
           "Please make sure that the tfm file #{filename} is uptodate by running make")
    f=File.open(filename)
    tfm=TeX::TFM.new
    # tfm.verbose=true
    tfm.read_tfm(f)
    f.close
    assert_equal(17,tfm.face)
    assert_equal("tricky.tfm",tfm.tfmfilename)
    assert_equal(10.1234,tfm.designsize)
    assert_equal(256,tfm.chars.size)
    assert_equal(0.27799,tfm.params[2])
    File.open("/tmp/newtfm.pl","w") { |f|
      f << tfm.to_s
    }
  end
  def test_write
    filename="tricky.tfm"
    f=File.open(filename)
    tfm=TeX::TFM.new
    # tfm.verbose=true
    tfm.read_tfm(f)
    f.close
    assert_raise(Errno::EEXIST) {
      tfm.save
    }

    tfm.tfmpathname="/tmp/newtfm.tfm"
    tfm.designsize=10.12345
    tfm.chars[254][:charht]=0.712493
    tfm.chars[255][:charht]=0.712492
     tfm.save(true)
    str=""
    tfm.write_file(str)
  end
  def test_big_decimal_shorten_mincover
    # There was a bug where the following data lead to an endless loop. This was due to the fact that 
    # the calculation with floats had some strange effects, e.g. 0.018-0.017=0.000999999999999997
    # this confused min_cover. The solution was to use BigDecimal
    w = TeX::TFM::TFMWriter.new(nil)
    data=[0.0, 0.003, 0.007, 0.01, 0.013, 0.014, 0.017, 0.018, 0.019, 0.02, 0.021, 0.024 ]
    data.each do |d|
      w.sort_in(3,d)
    end
    w.shorten(3,2)
  end


end
