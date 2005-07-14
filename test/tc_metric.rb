#!/opt/ruby/1.8/bin/ruby

# this file test some metrics that are output of the font#vpl and
# alike

require 'test/unit'
require 'pp'

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'font'


class TestMetric < Test::Unit::TestCase
  def test_fake_caps
    font=Font.new
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
    ligs['hyphen']=PL::LigKern.new({:krn=>
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
    ligs['s']=PL::LigKern.new({:krn=>
                                  [[118, 11.2],
                                  [97, -4.8],
                                  [119, 11.2],
                                  [121, 16.0],
                                  [28, 3.2],
                                  [116, 9.6]]})

    ligs['S']=PL::LigKern.new({:krn=>
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
    ligs['germandbls']=PL::LigKern.new({:krn=>
                                           [[118, 11.2],
                                           [97, -4.8],
                                           [119, 11.2],
                                           [121, 16.0],
                                           [28, 3.2],
                                           [116, 9.6]]})
    ligs['a']=PL::LigKern.new({:krn=>[[118, -58.4],[127, 19.2],[45, 19.2],
                                  [119, -64.0],[46, 15.2],[99, -31.2],
                                  [121, -30.4],[44, 22.4],[111, -31.2],
                                  [113, -31.2],[103, -31.2],[10, -15.2],
                                  [116, -31.2],[117, -34.4]]})
    chars['hyphen']={:charwd=>207,
      :charht=>240,
      :chardp=>0,
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
        assert_in_delta(data[sym],c[sym],0.001)
      }
      assert_equal(data[:map],c[:map])
      assert_equal(ligs[name],c[:ligkern])
    }
  end
  
end
