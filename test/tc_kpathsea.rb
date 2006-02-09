#!/opt/ruby/1.8/bin/ruby

require 'test/unit'

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'tex/kpathsea'

class TestKpathsea < Test::Unit::TestCase
  include TeX
  def test_startup
    kp=Kpathsea.new
  end
  def test_file_search_open
    kp=Kpathsea.new
    assert(kp.find_file("ec.enc","enc") =~ Regexp.new("fonts/enc/dvips/base/EC.enc"))

    # open_file comes in two flavours: 1) rubyish with block and auto
    # close on block end and 2) manual closing of file after use
    
    kp.open_file("8r.enc","enc") { |f|
      assert(f.readline =~ Regexp.new("% File 8r.enc  TeX Base 1 Encoding"))
    }
    
    f = kp.open_file("texnansi.enc","enc")
    assert(f.readline =~ Regexp.new("% @psencodingfile"))
    f.close
  end
  
  def test_programname
    # I'd like to test different parameters to second parameter of
    # program_name
    kpdoc=Kpathsea.new('doc')
#    assert(kpdoc.find_file("readme.txt","other text files") =~ Regexp.new("texmf/doc/generic/spanish/readme.txt"))
    kp=Kpathsea.new
    assert_nil(kp.find_file("readme.txt","other text files"))
    kp.reset_program_name('doc')
 #   assert(kp.find_file("readme.txt","other text files") =~ Regexp.new("texmf/doc/generic/spanish/readme.txt"))
  end

end
