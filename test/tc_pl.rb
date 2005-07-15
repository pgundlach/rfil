#!/opt/ruby/1.8/bin/ruby 

require 'test/unit'

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'pp'
require 'pl'
require 'plparser'

class TestPL < Test::Unit::TestCase
  
  def test_parser
    str="(VTITLE a vtitle)
(COMMENT a comment)
(FAMILY a-family__)
(CODINGSCHEME AdobeStandardEncoding + ECEncoding)
(DESIGNSIZE R 10.0)
(DESIGNUNITS R 1000)
(COMMENT DESIGNSIZE (1 em) IS IN POINTS)
(COMMENT OTHER DIMENSIONS ARE MULTIPLES OF DESIGNSIZE/1000)
(FONTDIMEN
   (SPACE D 300)
   (STRETCH D 200)
   (SHRINK D 100)
   (XHEIGHT D 415)
   (QUAD D 1000)
   (EXTRASPACE D 111)
   )
"
    pl=PL.new(false)
    pl.parse(str)
    assert_equal("a vtitle",pl.vtitle)
    assert_equal(1000,pl.designunits)
  end
  def test_writer
    pl=PL.new(false)
    pl.family="foo"
    npl=PL.new(false)
    npl.parse(pl.to_s)
    assert_equal("foo",npl.family)
    npl.family="fam"
    assert_equal("fam",npl.family)
    
    pl.family="bar"
    npl=PL.new(false)
    npl.parse(pl.to_s)
    assert_equal("bar",npl.family)
  end
  def test_cache
    pl=PL.new
    hyphen1={:ligkern=>RFI::LigKern.new({:lig=>[RFI::LIG.new(45,45,21,:lig),
                                       RFI::LIG.new(45,127,21,:lig)],:krn =>
                                       [[28,11.0], [89, -42.0]]}),
      :charwd=>207.0, :comment=>"hyphen", :charht=>240.0}
    hyphen2={:ligkern=>45 ,:charwd=>207.0, :comment=>"hyphen", :charht=>240.0}
    hyphen3={:ligalias=>45, :charwd=>207.0, :comment=>"hyphen", :charht=>240.0}
    otherchar={:charwd=>207.0, :comment=>"other", :charht=>240.0}

    pl[0]=otherchar
    pl[45]=hyphen1
    pl[127]=hyphen2
    pl[1]=hyphen3
    # 45 is 1 + :alias
    assert_equal(pl[1][:ligkern][:krn],pl[45][:ligkern][:krn])
    assert_equal(pl[1][:ligkern][:lig],pl[45][:ligkern][:lig])

    assert_equal(Set.new([1,127]),pl[45][:ligkern][:alias])

    assert_equal(45,pl[1][:ligalias])
    assert_equal(nil,pl[0][:ligkern])
    assert_equal(otherchar,pl[0])
    assert_equal("(LIGTABLE
   (LABEL O 1)
   (LABEL O 55)
   (LABEL O 177)
   (KRN O 34 R 11.0)
   (KRN C Y R -42.0)
   (LIG O 55 O 25)
   (LIG O 177 O 25)
   (STOP)
   )
(CHARACTER O 0
   (CHARWD R 207.0)
   (CHARHT R 240.0)
   )
(CHARACTER O 1
   (CHARWD R 207.0)
   (CHARHT R 240.0)
   )
(CHARACTER O 55
   (CHARWD R 207.0)
   (CHARHT R 240.0)
   )
(CHARACTER O 177
   (CHARWD R 207.0)
   (CHARHT R 240.0)
   )
",pl.to_s)
  end

  def test_array
    str="(VTITLE Created by afm2tfm savorg__.afm -T ec.enc -V foo.vpl -c 0.5)
(COMMENT Please edit that VTITLE if you edit this file)
(FAMILY TeX-savorg__-CSC)
(CODINGSCHEME ECEncoding)
(DESIGNSIZE R 10.0)
(DESIGNUNITS R 1000)
(COMMENT DESIGNSIZE (1 em) IS IN POINTS)
(COMMENT OTHER DIMENSIONS ARE MULTIPLES OF DESIGNSIZE/1000)
(FONTDIMEN
   (SPACE D 300)
   (STRETCH D 200)
   (SHRINK D 100)
   (XHEIGHT D 415)
   (QUAD D 1000)
   (EXTRASPACE D 111)
   )
(MAPFONT D 0
   (FONTNAME savorg__)
   )
(MAPFONT D 1
   (FONTNAME savorg__)
   (FONTAT D 500)
   )
(LIGTABLE
   (LABEL O 55) (comment hyphen)
   (LABEL O 177) (comment hyphen)
   (LIG O 55 O 25)
   (LIG O 177 O 25)
   (KRN O 34 R 11) (comment fi)
   (KRN C Y R -42)
   (KRN C y R -21.0)
   (KRN C W R -31)
   (KRN C w R -15.5)
   (KRN C V R -23)
   (KRN C v R -11.5)
   (KRN C T R -48)
   (KRN C t R -24.0)
   (KRN C A R 21)
   (KRN C a R 10.5)
   (STOP)
 )
(CHARACTER O 177 (comment hyphen)
   (CHARWD R 207)
   (CHARHT R 240)
   )
(CHARACTER O 212 (comment Lslash)
   (CHARWD R 561)
   (CHARHT R 669)
   (CHARDP R 2)
   (CHARIC R 12)
   )
(CHARACTER O 222 (comment Scaron)
   (CHARWD R 468)
   (CHARHT R 870)
   (CHARDP R 13)
   )
"
    pl = PL.new
    pl.parse(str)
    s=Set.new()
    s.add(127)
    a={:charht=>240.0,
      :charwd=>207.0,
      :ligalias=>45,
      :comment=>"hyphen",
      :ligkern=> RFI::LigKern.new(:alias=>s,
                                 :comment=>"hyphenhyphenfi",
                                 :lig=>[ RFI::LIG.new(127,45,21,:lig),
                                   RFI::LIG.new(127,127,21,:lig)],
                                 :krn=>[
                                   [28, 11.0],
                                   [65, 21.0],
                                   [84, -48.0],
                                   [86, -23.0],
                                   [87, -31.0],
                                   [89, -42.0],
                                   [97, 10.5],
                                   [116, -24.0],
                                   [118, -11.5],
                                   [119, -15.5],
                                   [121, -21.0]
                                 ])}
      
    assert_equal(a,pl[127])
    a[:charwd]=400
    pl[127]=a
    assert_equal(400,pl[127][:charwd])
    #roundtrip check, pl.ligtable= might have some errors
    a=pl.ligtable
    pl.ligtable=a
    assert_equal(a,pl.ligtable)
    # mutate ligtable, this must not affect the original one
    a[45][:krn][0][0]=9999
    assert_equal(28,pl.ligtable[45][:krn][0][0])
  end
  def test_fontdimen
    require 'font'
    font=Font.new
    font.load_variant("savorg__.afm")
    font.mapenc="8r"
    font.texenc="ec"
    pl=PL.new(true)
    v = font.vpl(font.mapenc,font.texenc[0])
    assert_equal(10.0,v.designsize)
    assert_equal({:space=>300, :stretch=>200, :shrink=>100, :xheight=>415,
                   :quad=>1000, :extraspace=>111 },v.fontdimen)
    v.fontdimen={:space=>100, :stretch=>200, :shrink=>300, :xheight=>400,
                   :quad=>500, :extraspace=>600 }
    b="(FONTDIMEN
   (SPACE D 100)
   (STRETCH D 200)
   (SHRINK D 300)
   (XHEIGHT D 400)
   (QUAD D 500)
   (EXTRASPACE D 600)
   )
"
    assert_equal(b,v.fontdimen(true).to_s)
  end
  def test_ligkern
    lt=RFI::LigKern.new()
    lt[:lig]=[ RFI::LIG.new(127,45,21,:lig),
      RFI::LIG.new(127,127,21,:lig)]
    
    lt[:krn]=[[28, 11.0],
      [89, -42.0],
      [121, -21.0],
      [87, -31.0],
      [119, -15.5],
      [86, -23.0],
      [118, -11.5],
      [84, -48.0],
      [116, -24.0],
      [65, 21.0],
      [97, 10.5]]
    lt2=lt.dup
    assert(lt2==lt)
    lt2[:krn][0][0]=-1
    lt2[:lig][0].left=99
    assert(lt2!=lt)
    assert_equal(127,lt[:lig][0].left)
    assert_equal(28,lt[:krn][0][0])
  end
  def test_lig_kern_combinations
    pl=PL.new
    pl.parse("(LIGTABLE
   (LABEL O 4)
   (KRN O 34 R -33)
   (KRN C Y R -85)
   (KRN C y R -42.5)
   (STOP)
   (LABEL O 5)
   (LIG D 4 D 99)
   (KRN O 1 R 1)
   (KRN C Y R -2)
   (KRN C y R 3)
   (STOP)
   (LABEL O 6)
   (LIG D 4 D 50)
   (STOP)
   (LABEL O 7)
   (LABEL D 8)
   (KRN O 34 R -33)
   (KRN C Y R -85)
   (KRN C y R -42.5)
   (STOP)
   (LABEL O 11)
   (LABEL O 12)
   (LIG D 4 D 99)
   (KRN O 1 R 1)
   (KRN C Y R -2)
   (KRN C y R 3)
   (STOP)
   (LABEL O 13)
   (LABEL O 14)
   (LIG D 4 D 50)
   (STOP)
)
(CHARACTER O 4
   (CHARWD R 500)
   (CHARHT R 654)
   )
(CHARACTER O 5
   (CHARWD R 10)
   (CHARHT R 20)
   )
(CHARACTER O 6
   (CHARWD R 30)
   (CHARHT R 40)
   )
(CHARACTER O 7
   (CHARWD R 30)
   (CHARHT R 40)
   )
(CHARACTER O 10
   (CHARWD R 30)
   (CHARHT R 40)
   )
(CHARACTER O 11
   (CHARWD R 30)
   (CHARHT R 40)
   )
(CHARACTER O 12
   (CHARWD R 30)
   (CHARHT R 40)
   )
(CHARACTER O 13
   (CHARWD R 30)
   (CHARHT R 40)
   )
(CHARACTER O 14
   (CHARWD R 30)
   (CHARHT R 40)
   )
")
    l1=RFI::LIG.new(5,4,99,:lig)
    l2=RFI::LIG.new(6,4,50,:lig)
    # different combinations: 1: kern only, 2: lig and kern, 3: lig only
    assert_equal([[28, -33.0], [89, -85.0], [121, -42.5]],pl[4][:ligkern][:krn])
    assert_equal(nil,pl[4][:ligkern][:lig])

    assert_equal([l1],pl[5][:ligkern][:lig])
    assert_equal([[1, 1.0], [89, -2.0], [121, 3.0]],pl[5][:ligkern][:krn])

    assert_equal([l2],pl[6][:ligkern][:lig])
    assert_equal(nil,pl[6][:ligkern][:krn])

    # now with aliases
    assert_equal([[28, -33.0], [89, -85.0], [121, -42.5]],pl[7][:ligkern][:krn])
    assert_equal([[28, -33.0], [89, -85.0], [121, -42.5]],pl[8][:ligkern][:krn])
    assert_equal(nil,pl[7][:ligkern][:lig])
    assert_equal(nil,pl[8][:ligkern][:lig])
    assert_equal(Set.new([8]), pl[7][:ligkern][:alias])
    assert_equal(7,pl[8][:ligalias])

    assert_equal([l1],pl[9][:ligkern][:lig])
    assert_equal([l1],pl[10][:ligkern][:lig])
    assert_equal([[1, 1.0], [89, -2.0], [121, 3.0]],pl[9][:ligkern][:krn])
    assert_equal([[1, 1.0], [89, -2.0], [121, 3.0]],pl[10][:ligkern][:krn])
    assert_equal(Set.new([10]), pl[9][:ligkern][:alias])
    assert_equal(9,pl[10][:ligalias])

    
    assert_equal([l2],pl[11][:ligkern][:lig])
    assert_equal([l2],pl[12][:ligkern][:lig])
    assert_equal(nil,pl[11][:ligkern][:krn])
    assert_equal(nil,pl[12][:ligkern][:krn])
    assert_equal(Set.new([12]), pl[11][:ligkern][:alias])
    assert_equal(11,pl[12][:ligalias])
end

end
