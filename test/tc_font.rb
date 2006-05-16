#!/opt/ruby/1.8/bin/ruby -w

require 'test/unit'

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'rfil/font'

class TestFont < Test::Unit::TestCase
  include RFIL
  include TeX
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
    font=RFI::Font.new
    assert_raise(ArgumentError) {
      # font expects a FontCollection object if called w/ arg
      RFI::Font.new("some class")
    }
  end
  def test_load_variant
    font=RFI::Font.new
    # todo: ligatures,
    assert_equal(0,font.load_variant("savorg__.afm"))
    assert_equal(1,font.load_variant("savoi___.afm"))
    # assert(font.defaultfm.chars)
    assert_raise(Errno::ENOENT) {
      font.load_variant("foo.afm")
    }
  end
  def test_mapfont
    font=RFI::Font.new
    font.load_variant("savorg__.afm")
    fc=font.load_variant("savoscrg.afm")
    font.copy(fc,:digits)
    font.mapenc="8r"
    font.texenc="ec"
    vf = font.to_vf(font.mapenc,font.texenc[0])
    assert_equal("8r-savorg__-orig",vf.fontlist[0][:tfm].tfmfilename)
    assert_equal("8r-savoscrg-orig",vf.fontlist[1][:tfm].tfmfilename)
  end

  def test_vpl
    font=RFI::Font.new
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
    b.filename="minienc2"

    font.load_variant("savorg__.afm")
    font.mapenc=a
    font.texenc=b
    str=font.to_vf(font.mapenc,font.texenc[0]).to_s
    # puts str
    vf=VF.new()
    vf.parse_vpl(str)
    assert_equal("Installed with rfi library",vf.vtitle)
    assert_equal("SAVOY",vf.fontfamily)
    assert_equal("MAPENC + TEXENC",vf.codingscheme)
    assert_equal(10.0,vf.designsize)
    assert_equal([nil, 0.0, 0.3, 0.3, 0.1, 0.415, 1.0],vf.params)
    assert_equal("minienc-savorg__-orig",vf.fontlist[0][:tfm].tfmfilename)
    assert_equal([[[:krn, 17, 0.024], [:krn, 18, 0.024], [:krn, 12, 0.015], 
                     [:krn, 10, -0.008]], [[:krn, 11, 0.021]]],  vf.lig_kern)

    ce=[
    {:charht=>0.426, :dvi=>[[:setchar, 10]], :chardp=>0.014, :charwd=>0.433},
    {:charht=>0.564,
      :charic=>0.012,
      :dvi=>[[:setchar, 1]],
      :lig_kern=>0,
      :chardp=>0.002,
      :charwd=>0.632},
    {:charht=>0.73, :dvi=>[[:setchar, 2]], :chardp=>0.013, :charwd=>0.517},
    {:charht=>0.733, :dvi=>[[:setchar, 3]], :chardp=>0.012, :charwd=>0.52},
    {:charht=>0.427, :dvi=>[[:setchar, 4]], :chardp=>0.013, :charwd=>0.674},
    {:charht=>0.669, :dvi=>[[:setchar, 5]], :chardp=>0.002, :charwd=>0.889},
    {:charht=>0.436, :dvi=>[[:setchar, 6]], :chardp=>0.002, :charwd=>0.246},
    {:charht=>0.24, :dvi=>[[:setchar, 7]], :lig_kern=>1, :charwd=>0.207},
    {:charht=>0.24, :dvi=>[[:setchar, 7]], :lig_kern=>1, :charwd=>0.207},
    {:charht=>0.68, :dvi=>[[:setrule, 0.4, 0.4]], :chardp=>0.013,
        :charwd=>0.804}]
    
    for i in 10..19
      assert_equal(ce[i-10],vf.chars[i])
    end
    return
  end
  def test_pl_lig_nolig
    font=RFI::Font.new
    font.load_variant("savorg__.afm")
    font.apply_ligkern_instructions(RFI::STDLIGKERN)

    font.texenc="8r"
    
    plligs  =font.to_tfm(font.texenc[0],:noligs=>false).to_s
    plnoligs=font.to_tfm(font.texenc[0],:noligs=>true).to_s
    ligs=TFM.new.parse_pl(plligs)
    noligs=TFM.new.parse_pl(plnoligs)
    assert_equal(0,noligs.lig_kern.size)
    hyphen=font.texenc[0].glyph_index['hyphen'].min
    lk=[[:lig, 45, 150], [:lig, 173, 150], [:krn, 86, -0.023],
      [:krn, 87, -0.031], [:krn, 65, 0.021], [:krn, 2, 0.011],
      [:krn, 89, -0.042], [:krn, 84, -0.048]]
    assert_equal(lk,ligs.lig_kern[ligs.chars[hyphen][:lig_kern]])
  end

  def test_pl
    font=RFI::Font.new
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
    #    a.update_glyph_index
    a.filename="minienc"
    font.load_variant("savorg__.afm")
    font.mapenc=a

    str=font.to_tfm(a,:noligs=>true).to_s
    tfm=TFM.new
    tfm.parse_pl(str)
    ce=[nil,{:charic=>0.012, :chardp=>0.002, :charwd=>0.632, :charht=>0.564},
      {:chardp=>0.013, :charwd=>0.517, :charht=>0.73},
      {:chardp=>0.012, :charwd=>0.52, :charht=>0.733},
      {:chardp=>0.013, :charwd=>0.674, :charht=>0.427},
      {:chardp=>0.002, :charwd=>0.889, :charht=>0.669},
      {:chardp=>0.002, :charwd=>0.246, :charht=>0.436},
      {:charwd=>0.207, :charht=>0.24},
      {:charwd=>0.207, :charht=>0.24},
      {:chardp=>0.013, :charwd=>0.804, :charht=>0.68},
      {:chardp=>0.014, :charwd=>0.433, :charht=>0.426},
    ]
    count=0
    tfm.chars.each_with_index { |charentry,i|
      count += 1
      assert_equal(ce[i],charentry)
    }
    assert_equal(ce.size,count)
    assert_equal(["minienc-savorg__-orig Savoy-Regular \"mapenc ReEncodeFont\" <minienc.enc <savorg__.pfb\n"], font.maplines)
    font.texenc=[@ecenc,@texnansienc]
    font.mapenc=nil
    fontmaplines=font.maplines
    mapline=["texnansi-savorg__-orig Savoy-Regular \"TeXnANSIEncoding ReEncodeFont\" <texnansi.enc <savorg__.pfb\n",
      "ec-savorg__-orig Savoy-Regular \"ECEncoding ReEncodeFont\" <EC.enc <savorg__.pfb\n"]
    assert_equal(mapline.size,fontmaplines.size)
    fontmaplines.each { |fm|
      assert(mapline.member?(fm), "#{fm} is not recognized")
    }
  end
  
  def test_vpl_fontname
    font=RFI::Font.new
    font.load_variant("savorg__.afm")
    def font.m(a)
      # private:
      map_fontname(a)
    end
    assert_equal("texnansi-savorg__-orig",font.m(@texnansienc))
    assert_equal("ec-savorg__-orig",font.m(@ecenc))

  end
  def test_enc
    font=RFI::Font.new
    font.texenc=[@ecenc,@texnansienc]
    assert_equal([@ecenc,@texnansienc],font.texenc)

    # mapenc can only be 0 or one
    font.mapenc=[@ecenc,@texnansienc]
    #p font.mapenc.encname
    assert_equal(@ecenc,font.mapenc)
    font.mapenc=nil
    assert_equal(nil,font.mapenc)
  end
  
  def test_mapfilename
    font=RFI::Font.new
    font.load_variant("savorg__.afm")
    assert_equal("savorg__.map", File.basename(font.mapfilename))
  end
  def test_ensure_font
    font=RFI::Font.new
    assert_raise(ScriptError) {   font.fake_caps(1,1)   }
  end
  def test_find_used_fonts
    font=RFI::Font.new
    font.load_variant("savorg__.afm")
    b = font.load_variant("savorg__.afm")
    c = font.load_variant("savorg__.afm")
    d = font.load_variant("savorg__.afm")
    font.defaultfm.chars['B'].fontnumber=b
    font.defaultfm.chars['D'].fontnumber=d
    assert_equal([0,1,3],font.find_used_fonts)
  end
  def test_guess_weight_variant
    font=RFI::Font.new
    font.load_variant("savob___.afm")
    font.guess_weight_variant
    assert_equal(:bold,font.weight)
  end

end
