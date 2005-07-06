#!/opt/ruby/1.8/bin/ruby

require 'test/unit'

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'font'
require 'enc'
require 'pl'
require 'plparser'
require 'kpathsea'

class TestFont < Test::Unit::TestCase
  def setup
    @kpse=Kpathsea.new
    @kpse.open_file("ec.enc","enc") { |f|
      @ecenc=ENC.new(f)
    }
    @kpse.open_file("texnansi.enc","enc") { |f|
      @texnansienc=ENC.new(f)
    }
  end
  
  def test_startup
    font=Font.new
    assert_raise(ArgumentError) {
      # font expects a FontCollection object if called w/ arg
      Font.new("some class")
    }
  end
  def test_load_variant
    font=Font.new
    # todo: ligatures,
    assert_equal(0,font.load_variant("savorg__.afm"))
    assert_equal(1,font.load_variant("savoi___.afm"))
    # assert(font.defaultfm.chars)
    assert_raise(Errno::ENOENT) {
      font.load_variant("foo.afm")
    }
    assert_raise(ArgumentError) {
      font.load_variant("bar.xyz")
    }
  end
  def test_mapfont
    font=Font.new
    font.load_variant("savorg__.afm")
    fc=font.load_variant("savoscrg.afm")
    font.copy(fc,:digits)
    font.mapenc="8r"
    font.texenc="ec"
    v = font.vpl(font.mapenc,font.texenc[0])
    assert_equal({0=>{:fontname=>"8r-savorg__-orig"},
                  1=>{:fontname=>"8r-savoscrg-orig"}},v.mapfont)
  end

  def test_vpl
    font=Font.new
    a=ENC.new()
    a.encname="mapenc"
    a[0]=".notdef"
    a[1]="A"
    a[2]="b"
    a[3]="germandbls"
    a[4]="ae"
    a[5]="AE"
    a[6]="dotlessi"
    a[7]="hyphen"
    a[8]="hyphen"
    a[9]="copyright"
    a[10]="c"
    a.update_glyph_index
    a.filename="minienc"
    b=ENC.new()
    b.encname="texenc"
    b[10]="c"
    b[11]="A"
    b[12]="b"
    b[13]="germandbls"
    b[14]="ae"
    b[15]="AE"
    b[16]="dotlessi"
    b[17]="hyphen"
    b[18]="hyphen"
    b[19]="registered"
    b.update_glyph_index
    b.filename="minienc2"

    font.load_variant("savorg__.afm")
    font.mapenc=a
    font.texenc=b
    str=font.vpl(font.mapenc,font.texenc[0]).to_s
    pl=PL.new(true)
    pl.parse(str)

    assert_equal("Installed with rfi library",pl.vtitle)
    assert_equal("Savoy",pl.family)
    assert_equal("mapenc + texenc",pl.codingscheme)
    assert_equal(10.0,pl.designsize)
    assert_equal({:space=>300, :stretch=>200, :shrink=>100, :xheight=>415,
                   :quad=>1000, :extraspace=>111, },pl.fontdimen)
    
    assert_equal({:fontname=>"minienc-savorg__-orig"},
                 pl.mapfont[0])
    assert_equal({ 11=>[[[17, 24],
                         [18, 24],
                         [12, 15],
                         [10, -8]], []],
                   17=>[[[11, 21]], []],
                   18=>[[[11, 21]], []]},pl.ligtable)
    
    ce=[
      # c
      {:slot=>10,
        :chardp=>14,
        :charwd=>433,
        :charht=>426},
      # A
      {:slot=>11,
        :chardp=>2,
        :charic=>12,
        :charwd=>632,
        :charht=>564,
        :map=>[[:setchar, 1]]},
      # b
      {:slot=>12,
        :chardp=>13,
        :charwd=>517,
        :charht=>730,
        :map=>[[:setchar, 2]]},
      # germandbls
      {:slot=>13,
        :chardp=>12,
        :charwd=>520,
        :charht=>733,
        :map=>[[:setchar, 3]]
        },
      # ae 
      {:slot=>14,
        :chardp=>13,
        :charwd=>674,
        :charht=>427,
        :map=>[[:setchar,4]]
        },
      # AE
      {:slot=>15,
        :chardp=>2,
        :charwd=>889,
        :charht=>669,
        :map=>[[:setchar, 5]]
      },
      # dotlessi
      {:slot=>16,
        :chardp=>2.0,
        :charwd=>246.0,
        :charht=>436.0,
        :map=>[[:setchar, 6]]
      },
      # hyphen
      {:slot=>17,
        :charwd=>207.0,
        :map=>[[:setchar, 7]],
        :charht=>240.0},
      # hyphen
      {:slot=>18,
        :charwd=>207.0,
        :map=>[[:setchar, 7]],
        :charht=>240.0}]

    pl.get_charentries.each_with_index { |charentry,i|
      assert_equal(ce[i],charentry)
    }
  end
  def test_pl
    font=Font.new
    a=ENC.new()
    a.encname="mapenc"
    a[0]=".notdef"
    a[1]="A"
    a[2]="b"
    a[3]="germandbls"
    a[4]="ae"
    a[5]="AE"
    a[6]="dotlessi"
    a[7]="hyphen"
    a[8]="hyphen"
    a[9]="copyright"
    a[10]="c"
    a.update_glyph_index
    a.filename="minienc"
    font.load_variant("savorg__.afm")
    font.mapenc=a

    str=font.pl(a).to_s
    npl=PL.new(false)
    npl.parse(str)
    ce=[
      # A
      {:charic=>0.012,
        :slot=>1,
        :chardp=>0.002,
        :charwd=>0.632,
        :charht=>0.702
      },
      # b
      {:slot=>2,
        :chardp=>0.013,
        :charwd=>0.517,
        :charht=>0.73
      },
      # germandbls
      {:slot=>3,
        :chardp=>0.012,
        :charwd=>0.52,
        :charht=>0.733
      },
      # ae
      {:slot=>4,
        :chardp=>0.013,
        :charwd=>0.674,
        :charht=>0.427
      },
      # AE
      {
        :slot=>5,
        :chardp=>0.002,
        :charwd=>0.889,
        :charht=>0.669
      },
      # dotlessi
      {
        :slot=>6,
        :chardp=>0.002,
        :charwd=>0.246,
        :charht=>0.436},
      # hyphen  (ht looks strange!)
      # afm2tfm (and then tftopl) leads to  be something like
      # wd: 0.207, ht: .702
      {:slot=>7,
        :charwd=>0.207,
        :charht=>0.24},
      # hyphen
      {:slot=>8,
        :charwd=>0.207,
        :charht=>0.24},
      # copyright
      {:slot=>9,
        :chardp=>0.013,
        :charwd=>0.804,
        :charht=>0.68},
      # c
      {:slot=>10,
        :chardp=>0.014,
        :charwd=>0.433,
        :charht=>0.426}]
    npl.get_charentries.each_with_index { |charentry,i|
      assert_equal(ce[i],charentry)
    }
    assert_equal(["minienc-savorg__-orig Savoy-Regular <minienc.enc <savorg__.pfb\n"], font.maplines)
    font.texenc=[@ecenc,@texnansienc]
    font.mapenc=nil
    fontmaplines=font.maplines
    mapline=["texnansi-savorg__-orig Savoy-Regular <texnansi.enc <savorg__.pfb\n",
      "ec-savorg__-orig Savoy-Regular <EC.enc <savorg__.pfb\n"]
    assert_equal(mapline.size,fontmaplines.size)
    fontmaplines.each { |fm|
      assert(mapline.member?(fm))
    }
end
  
  def test_vpl_fontname
    font=Font.new
    font.load_variant("savorg__.afm")
    def font.m(a)
      # private:
      map_fontname(a)
    end
    assert_equal("texnansi-savorg__-orig",font.m(@texnansienc))
    assert_equal("ec-savorg__-orig",font.m(@ecenc))

  end
  def test_enc
    font=Font.new
    font.texenc=[@ecenc,@texnansienc]
    assert_equal([@ecenc,@texnansienc],font.texenc)

    # mapenc can only be 0 or one
    font.mapenc=[@ecenc,@texnansienc]
    assert_equal(@ecenc,font.mapenc)
    font.mapenc=nil
    assert_equal(nil,font.mapenc)
  end
  def test_write
    t=Time.new
    # I want to see which files actually changed. A more clever solution?
    sleep 1
    
    destdir=File.join(Dir.getwd,"output")
    f=File.join(destdir,"savorg__.vf")
    if File.exists? f
      assert(File.mtime(f) < t)
    end
    font=Font.new
    font.load_variant("savorg__.afm")
    font.set_dirs(destdir)
    font.write_files
    assert(File.mtime(File.join(destdir,"savorg__.vf")) > t)
    font.texenc=["ec.enc","texnansi.enc"]
    font.write_files
    
    filepath=(File.join(destdir,"ec-savorg__.vf"))
    assert(File.exists?(filepath), "I cannot find: #{filepath}")
    assert(File.mtime(filepath) > t,
           "The file #{filepath} did not change as I thought it would.")
    assert(File.mtime(File.join(destdir,"texnansi-savorg__.vf")) > t)
  end
  
  def test_mapfilename
    font=Font.new
    font.load_variant("savorg__.afm")
    assert_equal("savorg__.map", File.basename(font.mapfilename))
  end
  def test_ensure_font
    font=Font.new
    assert_raise(ScriptError) {   font.fake_caps(1,1)   }
  end
  def test_find_used_fonts
    font=Font.new
    font.load_variant("savorg__.afm")
    b = font.load_variant("savorg__.afm")
    c = font.load_variant("savorg__.afm")
    d = font.load_variant("savorg__.afm")
    font.defaultfm.chars['B'].fontnumber=b
    font.defaultfm.chars['D'].fontnumber=d
    assert_equal([0,1,3],font.find_used_fonts)
  end
end
