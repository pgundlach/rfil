#!/opt/ruby/1.8/bin/ruby

# this file test some metrics that are output of the font#vpl and
# alike

require 'test/unit'
require 'pp'

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'font'


class TestMetric < Test::Unit::TestCase
  def test_fake_caps
    font=RFI::Font.new
    font.load_variant("savorg__.afm")
    fc=font.load_variant("savorg__.afm")
    font.fake_caps(fc,0.8)
    font.copy(fc,:lowercase,:ligkern=>true)
    font.apply_ligkern_instructions(RFI::STDLIGKERN)
    font.mapenc="ec"
    font.texenc="ec"
    v = font.vpl(font.mapenc,font.texenc[0])
    # let's pick some interesting chars:
    # fi, dotlessi, germandbls, a, e, i, S, s, hyphen
    # don't ask me why the last ones are interesting...
    c=v[font.mapenc.glyph_index['fi'].min]
    assert_equal({:charht=>730, :chardp=>2, :charic=>0, :charwd=>554},c)

    chars={}
    ligs={}
    ligs['hyphen']=RFI::LigKern.new({:krn=>
                                       [[118, -18.4],
                                       [86, -23],
                                       [119, -24.8],
                                       [97, 16.8],
                                       [87, -31],
                                       [65, 21],
                                       [121, -33.6],
                                       [28, 11],
                                       [89, -42],
                                       [116, -38.4],
                                       [84, -48]],
                                     :alias=>Set.new([127]),
                                     :lig=>[
                                       RFI::LIG.new(45,45,21,"LIG"),
                                       RFI::LIG.new(45,127,21,"LIG")]})
    ligs['s']=RFI::LigKern.new({:krn=>
                                  [[118, 11.2],
                                  [97, -4.8],
                                  [119, 11.2],
                                  [121, 16.0],
                                  [28, 3.2],
                                  [116, 9.6]]})

    ligs['S']=RFI::LigKern.new({:krn=>
                                  [[118, 11.2],
                                  [86, 14],
                                  [119, 11.2],
                                  [97, -4.8],
                                  [87, 14],
                                  [65, -6],
                                  [121, 16.0],
                                  [28, 4],
                                  [89, 20],
                                  [116, 9.6],
                                  [84, 12]]})
    ligs['germandbls']=RFI::LigKern.new({:krn=>
                                           [[118, 11.2],
                                           [97, -4.8],
                                           [119, 11.2],
                                           [121, 16.0],
                                           [28, 3.2],
                                           [116, 9.6]]})
    ligs['a']=RFI::LigKern.new({:krn=>[[118, -58.4],[127, 19.2],[45, 19.2],
                                  [119, -64.0],[46, 15.2],[99, -31.2],
                                  [121, -30.4],[44, 22.4],[111, -31.2],
                                  [113, -31.2],[103, -31.2],[10, -15.2],
                                  [116, -31.2],[117, -34.4]]})
    chars['hyphen']={:charwd=>207,
      :charht=>240,
      :chardp=>0,
      :map=>[[:setchar, 45]],
      :charic=>0}
    chars['s']={:charwd=>374.4,
      :charht=>436.0,
      :chardp=>10.4,
      :map=>[[:selectfont, 1], [:setchar, 83]],
      :charic=>0}
    chars['S']={:charwd=>468,
      :charht=>545.0,
      :chardp=>13,
      :charic=>0}
    chars['i']={:charwd=>261.6,
      :charht=>451.2,
      :chardp=>1.6,
      :map=>[[:selectfont, 1], [:setchar, 73]],
      :charic=>0}
    chars['e']={:charwd=>458.4,
      :charht=>451.2,
      :chardp=>1.6,
      :map=>[[:selectfont, 1], [:setchar, 69]],
      :charic=>0}
    chars['a']={:charwd=>505.6,
      :charht=>451.2,
      :chardp=>1.6,
      :map=>[[:selectfont, 1], [:setchar, 65]],
      :charic=>9.6}
    chars['fi']={:charwd=>554, :charht=>730, :chardp=>2, :charic=>0}
    chars['dotlessi']={:charwd=>261.6,
      :charht=>451.2,
      :chardp=>1.6,
      :map=>[[:selectfont, 1], [:setchar, 73]],
      :charic=>0}
    chars['germandbls']={:charwd=>748.8,
      :charht=>545.0,
      :chardp=>10.4,
      :map=>[[:selectfont, 1], [:setchar, 83], [:setchar, 83]],
      :charic=>0}
    
    chars.each { |name,data|
      c=v[font.mapenc.glyph_index[name].min]
      [:charwd, :charht, :chardp, :charic].each { |sym|
        assert_in_delta(data[sym],c[sym],0.001, "in #{name},#{sym}")
      }
      assert_equal(data[:map],c[:map])
      assert_equal(ligs[name],c[:ligkern])
    }
  end
  def test_slant
    font=RFI::Font.new
    font.load_variant("savorg__.afm")
    font.slant=0.5
    font.apply_ligkern_instructions(RFI::STDLIGKERN)
    font.mapenc="ec"
    font.texenc="ec"
    v = font.vpl(font.mapenc,font.texenc[0])
    chars={}
    ligs={}
    ligs['A']=RFI::LigKern.new({:krn=>
      [[118, -26.0],
       [127, 24.0],
       [45, 24.0],
       [86, -73.0],
       [119, -25.0],
       [46, 19.0],
       [97, 24.0],
       [87, -80.0],
       [98, 15.0],
       [121, -26.0],
       [44, 28.0],
       [99, -8.0],
       [89, -38.0],
       [67, -39.0],
       [111, -16.0],
       [100, -1.0],
       [79, -39.0],
       [113, -1.0],
       [81, -39.0],
       [103, 12.0],
       [71, -39.0],
       [10, -19.0],
       [116, 3.0],
       [84, -39.0],
       [117, 4.0],
       [85, -43.0]]})
    chars['A']={:charwd=>632.0,
      :charht=>564.0,
      :chardp=>2,
      :charic=>294.0}
    
    chars['germandbls']={:charwd=>520.0,
      :charht=>733, :chardp=>12, :charic=>346.5}
    chars.each { |name,data|
      c=v[font.mapenc.glyph_index[name].min]
      [:charwd, :charht, :chardp, :charic].each { |sym|
        assert_in_delta(data[sym],c[sym],0.001, "in #{name},#{sym}")
      }
      assert_equal(data[:map],c[:map])
      assert_equal(ligs[name],c[:ligkern])
    }
  end

  def test_extend
    font=RFI::Font.new
    font.load_variant("savorg__.afm")
    font.efactor=0.5
    font.apply_ligkern_instructions(RFI::STDLIGKERN)
    font.mapenc="ec"
    font.texenc="ec"
    v = font.vpl(font.mapenc,font.texenc[0])

    chars={}
    ligs={}
    chars['germandbls']={:charwd=>260.0, :charht=>733, :chardp=>12,
      :charic=>0}
    
    chars['A']={:charwd=>316.0,
      :charht=>564.0,
      :chardp=>2,
      :charic=>6.0}
    ligs['A']=RFI::LigKern.new({:krn=>
      [[118, -13.0],
       [127, 12.0],
       [45, 12.0],
       [86, -36.5],
       [119, -12.5],
       [46, 9.5],
       [97, 12.0],
       [87, -40.0],
       [98, 7.5],
       [121, -13.0],
       [44, 14.0],
       [99, -4.0],
       [89, -19.0],
       [67, -19.5],
       [111, -8.0],
       [100, -0.5],
       [79, -19.5],
       [113, -0.5],
       [81, -19.5],
       [103, 6.0],
       [71, -19.5],
       [10, -9.5],
       [116, 1.5],
       [84, -19.5],
       [117, 2.0],
       [85, -21.5]]})
    chars.each { |name,data|
      c=v[font.mapenc.glyph_index[name].min]
      [:charwd, :charht, :chardp, :charic].each { |sym|
        assert_in_delta(data[sym],c[sym],0.001, "in #{name},#{sym}")
      }
      assert_equal(data[:map],c[:map])
      assert_equal(ligs[name],c[:ligkern])
    }

end
end
