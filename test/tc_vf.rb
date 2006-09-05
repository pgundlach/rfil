#!/opt/ruby/1.8/bin/ruby 

require 'test/unit'

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'tex/vf'

class TestVF < Test::Unit::TestCase
  def test_parse
    vf=TeX::VF.new
    vf.read_vpl("tricky2.vpl")
  end
  def test_read
    filename="tricky2.vf"
    assert(File.exists?(filename), "Please generate #{filename} by running make or vptovf.")
    vf=TeX::VF.new
    vf.read_vf(filename)
    assert_equal("tricky2.vf", vf.vffilename)
    assert_equal("A TITLE", vf.vtitle)
    assert_equal(2,vf.fontlist.size)
    s=vf.fontlist[1]
    assert_equal(0.8,s[:scale])
    assert_equal("phvr8t.tfm",s[:tfm].tfmfilename)
    
    # we assume that the tfm files are correct and checked in tc_tfm.rb
    c1=vf.chars[1]
    assert_equal([[:selectfont, 1], [:setchar, 30]], c1[:dvi])
    assert_equal(-0.332996, c1[:charwd])
    assert_equal(0.735498, c1[:charht])

    assert_raise(Errno::EEXIST) {   vf.save   }
    File.open("/tmp/newvf.vpl","w") { |f|
      f << vf.to_s
    }
  end

end
