#!/opt/ruby/1.8/bin/ruby

require 'test/unit'

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'rfil/font'
require 'rfil/fontcollection'

class TestFontFontCollection < Test::Unit::TestCase
  include RFIL
  include TeX
  def setup
    @kpse=Kpathsea.new
    @kpse.open_file("ec.enc","enc") { |f|
      @ecenc=ENC.new(f)
    }
    @kpse.open_file("texnansi.enc","enc") {|f|
      @texnansienc=ENC.new(f)
    }
    @kpse.open_file("8a.enc","enc") {|f|
      @aseenc=ENC.new(f)
    }

  end
  def test_enc
    font=RFI::Font.new
    assert_equal("StandardEncoding",font.texenc[0].encname)
    assert_equal(nil,font.mapenc)
    font.mapenc="ec.enc"
    font.texenc="ec.enc"
    assert(font.mapenc==@ecenc)
    assert(font.texenc[0]==@ecenc)
    # we now define encodings only in the fontcollection
    fc=RFI::FontCollection.new()
    fc.mapenc="ec.enc"
    fc.texenc="ec.enc"
    assert(fc.mapenc==@ecenc)
    assert(fc.texenc[0]==@ecenc)
    font=RFI::Font.new(fc)
    assert(font.mapenc==@ecenc)
    assert(font.texenc[0]==@ecenc)
    font.mapenc=@texnansienc
    assert(font.mapenc==@texnansienc)
  end

  def test_dirs
    fc=RFI::FontCollection.new()
    fc.set_dirs(:vpl => "/vpl")
    assert_equal("/vpl",fc.get_dir(:vpl))
    
    font=RFI::Font.new(fc)
    assert_equal("/vpl",font.get_dir(:vpl))
    
    assert_equal(Dir.getwd,font.get_dir(:afm))
    font.set_dirs("/tmp")
    assert_equal("/tmp",font.get_dir(:afm))
    # only affect :afm
    font.set_dirs(:afm => "/foo")
    assert_equal("/foo",font.get_dir(:afm))
    assert_equal("/tmp",font.get_dir(:tfm))
    # vpl has been overridden be font
    assert_equal("/tmp",font.get_dir(:vpl))
    fc.set_dirs("/tmp")
    fc.set_dirs(:tds=>true, :base=>"/tmp")
    # !! check next 4 assertions, are incorrect (trailing /) XXXX
    
#    assert_equal("/tmp/fonts/source/vpl/",fc.get_dir(:vpl))
#   assert_equal("/tmp/fonts/type1/",fc.get_dir(:type1))
#   assert_equal("/tmp/tex/latex/",fc.get_dir(:fd))

    font=RFI::Font.new(fc)
#    assert_equal("/tmp/fonts/source/vpl/",font.get_dir(:vpl))
  end
  def test_options
    fc=RFI::FontCollection.new
    assert_equal(false,fc.options[:dryrun])
    font=RFI::Font.new(fc)
    assert_equal(false,font.options[:verbose])
    font.options[:foo]="bar"
    assert_equal("bar",font.options[:foo])
    assert_equal(nil,fc.options[:foo])
    fc.options[:verbose]=true
    assert_equal(true,font.options[:verbose])
  end
end
