#!/opt/ruby/1.8/bin/ruby

# this file test some metrics that are output of the font#vpl and
# alike

require 'test/unit'

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'rfil/font'


class TestMetric < Test::Unit::TestCase
  include RFIL
  def test_fake_caps
    font=RFI::Font.new
    font.load_variant("savorg__.afm")
    fc=font.load_variant("savorg__.afm")
    font.fake_caps(fc,0.8)
    font.copy(fc,:lowercase,:ligkern=>true)
    font.apply_ligkern_instructions(RFI::STDLIGKERN)
    font.mapenc="ec"
    font.texenc="ec"
    v = font.to_vf(font.mapenc,font.texenc[0])
    # let's pick some interesting chars:
    # fi, dotlessi, germandbls, a, e, i, S, s, hyphen
    # don't ask me why the last ones are interesting...
    fi = font.mapenc.glyph_index['fi'].min
    c=v.chars[fi]
    ch={:charht=>0.730, :chardp=>0.002, :charic=>0,
      :charwd=>0.554, :dvi=>[[:setchar,28]]}
    
    assert_equal(ch,c)
    chars={}
    ligs={}
    ligs['hyphen']=[
      [:lig, 45, 21],
      [:lig, 127, 21],
      [:krn, 118, -0.0184],
      [:krn, 86, -0.023],
      [:krn, 119, -0.0248],
      [:krn, 97, 0.0168],
      [:krn, 87, -0.031],
      [:krn, 65, 0.021],
      [:krn, 121, -0.0336],
      [:krn, 28, 0.011],
      [:krn, 89, -0.042],
      [:krn, 116, -0.0384],
      [:krn, 84, -0.048]]

    ligs['S']=[[:krn, 118, 0.0112],
      [:krn, 86, 0.014],
      [:krn, 119, 0.0112],
      [:krn, 97, -0.0048],
      [:krn, 87, 0.014],
      [:krn, 65, -0.006],
      [:krn, 121, 0.016],
      [:krn, 28, 0.004],
      [:krn, 89, 0.02],
      [:krn, 116, 0.0096],
      [:krn, 84, 0.012]]

  
    ligs['s']=[[:krn, 118, 0.0112],
      [:krn, 97, -0.0048],
      [:krn, 119, 0.0112],
      [:krn, 121, 0.016],
      [:krn, 28, 0.0032],
      [:krn, 116, 0.0096]]
    
    ligs['germandbls']=
      [[:krn, 118, 0.0112],
      [:krn, 97, -0.0048],
      [:krn, 119, 0.0112],
      [:krn, 121, 0.016],
      [:krn, 28, 0.0032],
      [:krn, 116, 0.0096]]
    ligs['a']=[
      [:krn, 118, -0.0584],
      [:krn, 127, 0.0192],
      [:krn, 45, 0.0192],
      [:krn, 119, -0.064],
      [:krn, 46, 0.0152],
      [:krn, 99, -0.0312],
      [:krn, 121, -0.0304],
      [:krn, 44, 0.0224],
      [:krn, 111, -0.0312],
      [:krn, 113, -0.0312],
      [:krn, 103, -0.0312],
      [:krn, 10, -0.0152],
      [:krn, 116, -0.0312],
      [:krn, 117, -0.0344]]
    
    chars['hyphen']={:charwd=>0.207,
      :charht=>0.240,
      :chardp=>0,
      :dvi=>[[:setchar, 45]],
      :charic=>0}
    chars['s']={:charwd=>0.3744,
      :charht=>0.436,
      :chardp=>0.0104,
      :dvi=>[[:selectfont, 1], [:setchar, 83]],
      :charic=>0}
    chars['S']={:charwd=>0.468,
      :charht=>0.545,
      :chardp=>0.013,
      :dvi=>[[:setchar, 83]],
      :charic=>0}
    chars['i']={:charwd=>0.2616,
      :charht=>0.4512,
      :chardp=>0.0016,
      :dvi=>[[:selectfont, 1], [:setchar, 73]],
      :charic=>0}
    chars['e']={:charwd=>0.4584,
      :charht=>0.4512,
      :chardp=>0.0016,
      :dvi=>[[:selectfont, 1], [:setchar, 69]],
      :charic=>0}
    chars['a']={:charwd=>0.5056,
      :charht=>0.4512,
      :chardp=>0.0016,
      :dvi=>[[:selectfont, 1], [:setchar, 65]],
      :charic=>0.0096}
    chars['fi']={:charwd=>0.554, :charht=>0.730, :chardp=>0.002, :charic=>0, :dvi=>[[:setchar, 28]]}
    chars['dotlessi']={:charwd=>0.2616,
      :charht=>0.4512,
      :chardp=>0.0016,
      :dvi=>[[:selectfont, 1], [:setchar, 73]],
      :charic=>0}
    chars['germandbls']={:charwd=>0.7488,
      :charht=>0.5450,
      :chardp=>0.0104,
      :dvi=>[[:selectfont, 1], [:setchar, 83], [:setchar, 83]],
      :charic=>0}
    
    chars.each { |name,data|
      c=v.chars[font.mapenc.glyph_index[name].min]
      [:charwd, :charht, :chardp, :charic].each { |sym|
        assert_in_delta(data[sym],c[sym],0.001, "in #{name},#{sym}")
      }
       assert_equal(data[:dvi],c[:dvi], "in #{name}, :dvi")
      if c[:lig_kern]
        ligs[name].each_with_index {|lk,i|
          instr,nextchar,rest = lk
          assert_equal(nextchar,v.lig_kern[c[:lig_kern]][i][1])
          case instr
          when :kern
            assert_in_delta(rest,v.lig_kern[c[:lig_kern]][i][2],0.001)
          when :lig
            assert_equal(rest,v.lig_kern[c[:lig_kern]][i][2])
          end
        }
      end
    }
  end
  def test_slant
    font=RFI::Font.new
    font.load_variant("savorg__.afm")
    font.slant=0.5
    font.apply_ligkern_instructions(RFI::STDLIGKERN)
    font.mapenc="ec"
    font.texenc="ec"
    v = font.to_vf(font.mapenc,font.texenc[0])
    chars={}
    ligs={}
    ligs['A']=[
      [:krn, 118, -26.0],
       [:krn, 127, 24.0],
       [:krn, 45, 24.0],
       [:krn, 86, -73.0],
       [:krn, 119, -25.0],
       [:krn, 46, 19.0],
       [:krn, 97, 24.0],
       [:krn, 87, -80.0],
       [:krn, 98, 15.0],
       [:krn, 121, -26.0],
       [:krn, 44, 28.0],
       [:krn, 99, -8.0],
       [:krn, 89, -38.0],
       [:krn, 67, -39.0],
       [:krn, 111, -16.0],
       [:krn, 100, -1.0],
       [:krn, 79, -39.0],
       [:krn, 113, -1.0],
       [:krn, 81, -39.0],
       [:krn, 103, 12.0],
       [:krn, 71, -39.0],
       [:krn, 10, -19.0],
       [:krn, 116, 3.0],
       [:krn, 84, -39.0],
       [:krn, 117, 4.0],
       [:krn, 85, -43.0]]
    chars['A']={:charwd=>0.632,
      :charht=>0.564,
      :chardp=>0.002,
      :charic=>0.294,
      :dvi=>[[:setchar, 65]]
    }
    
    
    chars['germandbls']={
      :dvi=>[[:setchar, 255]],
      :charwd=>0.520,
      :charht=>0.733, :chardp=>0.012, :charic=>0.3465}


    chars.each { |name,data|
      c=v.chars[font.mapenc.glyph_index[name].min]
      [:charwd, :charht, :chardp, :charic].each { |sym|
        assert_in_delta(data[sym],c[sym],0.001, "in #{name},#{sym}")
      }
       assert_equal(data[:dvi],c[:dvi], "in #{name}, :dvi")
      if c[:lig_kern]
        ligs[name].each_with_index {|lk,i|
          instr,nextchar,rest = lk
          assert_equal(nextchar,v.lig_kern[c[:lig_kern]][i][1])
          case instr
          when :kern
            assert_in_delta(rest,v.lig_kern[c[:lig_kern]][i][2],0.001)
          when :lig
            assert_equal(rest,v.lig_kern[c[:lig_kern]][i][2])
          end
        }
      end
    }
  end

  def test_extend
    font=RFI::Font.new
    font.load_variant("savorg__.afm")
    font.efactor=0.5
    font.apply_ligkern_instructions(RFI::STDLIGKERN)
    font.mapenc="ec"
    font.texenc="ec"
    v = font.to_vf(font.mapenc,font.texenc[0])

    chars={}
    ligs={}
    chars['germandbls']={:charwd=>0.260, :charht=>0.733, :chardp=>0.012,
      :charic=>0, :dvi=>[[:setchar, 255]]}
    
    chars['A']={:charwd=>0.316,
      :charht=>0.564,
      :chardp=>0.002,
      :charic=>0.006,
      :dvi => [[:setchar, 65]]}
    ligs['A']= [[:krn, 118, -13.0],
       [:krn, 127, 12.0],
       [:krn, 45, 12.0],
       [:krn, 86, -36.5],
       [:krn, 119, -12.5],
       [:krn, 46, 9.5],
       [:krn, 97, 12.0],
       [:krn, 87, -40.0],
       [:krn, 98, 7.5],
       [:krn, 121, -13.0],
       [:krn, 44, 14.0],
       [:krn, 99, -4.0],
       [:krn, 89, -19.0],
       [:krn, 67, -19.5],
       [:krn, 111, -8.0],
       [:krn, 100, -0.5],
       [:krn, 79, -19.5],
       [:krn, 113, -0.5],
       [:krn, 81, -19.5],
       [:krn, 103, 6.0],
       [:krn, 71, -19.5],
       [:krn, 10, -9.5],
       [:krn, 116, 1.5],
       [:krn, 84, -19.5],
       [:krn, 117, 2.0],
       [:krn, 85, -21.5]]
    
    chars.each { |name,data|
      c=v.chars[font.mapenc.glyph_index[name].min]
      [:charwd, :charht, :chardp, :charic].each { |sym|
        assert_in_delta(data[sym],c[sym],0.001, "in #{name},#{sym}")
      }
      assert_equal(data[:dvi],c[:dvi], "in #{name}, :dvi")
      if c[:lig_kern]
        ligs[name].each_with_index {|lk,i|
          instr,nextchar,rest = lk
          assert_equal(nextchar,v.lig_kern[c[:lig_kern]][i][1])
          case instr
          when :kern
            assert_in_delta(rest,v.lig_kern[c[:lig_kern]][i][2],0.001)
          when :lig
            assert_equal(rest,v.lig_kern[c[:lig_kern]][i][2])
          end
        }
      end
    }
    
  end
end
