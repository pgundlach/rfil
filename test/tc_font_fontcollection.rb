#!/opt/ruby/1.8/bin/ruby

require 'test/unit'

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'font'
require 'fontcollection'
require 'enc'
require 'kpathsea'

class TestFontFontCollection < Test::Unit::TestCase
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
    font=Font.new
    assert_equal("StandardEncoding",font.texenc[0].encname)
    assert_equal(nil,font.mapenc)
    font.mapenc="ec.enc"
    font.texenc="ec.enc"
    assert(font.mapenc==@ecenc)
    assert(font.texenc[0]==@ecenc)
    # we now define encodings only in the fontcollection
    fc=FontCollection.new()
    fc.mapenc="ec.enc"
    fc.texenc="ec.enc"
    assert(fc.mapenc==@ecenc)
    assert(fc.texenc[0]==@ecenc)
    font=Font.new(fc)
    assert(font.mapenc==@ecenc)
    assert(font.texenc[0]==@ecenc)
    font.mapenc=@texnansienc
    assert(font.mapenc==@texnansienc)
  end

  def test_dirs
    fc=FontCollection.new()
    fc.set_dirs(:vpl => "/vpl")
    assert_equal("/vpl",fc.get_dir(:vpl))
    
    font=Font.new(fc)
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
  end
end
