#!/opt/ruby/1.8/bin/ruby

require 'test/unit'

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'rfi'

# The samples are taken from afm2tfm output from savorg__.afm.

class Empty ; end

class TestRFI < Test::Unit::TestCase

  def test_char
    c=RFI::Char.new
    c.name="hyphen"
    c.wx="207"
    c.c=45
    c.b=[0, 187, 207, 240]
    c.kern_data={"A"=>[21,0],"T" => [-48,0]}
    lig=RFI::LIG.new("hyphen","endash","emdash",:"=:")
    c.lig_data = {'endash' => lig }
    assert_equal(c.llx,0)
    assert_equal(c.lly,187)
    assert_equal(c.lig_data['endash'].result,'emdash')
  end
  def test_char_has_ligkern
    e=Empty.new
    gl=RFI::Glyphlist.new
    gl['endash']=RFI::Char.new('endash')
    c=gl['endash']
    assert_raise(ArgumentError,"has_ligkern? should throw an exception " +
                   "if argument does not respond to include?") {
      c.has_ligkern?(e)
    }
    gl.apply_ligkern_instructions("endash hyphen =: emdash")
    assert(c.has_ligkern?)
    assert(! c.has_ligkern?([]),"No ligkern information if glyphlist is empty")
    assert(c.has_ligkern?(['endash','hyphen','emdash']))

    # hyphen is missing in glyphindex
    assert(! c.has_ligkern?(['endash','emdash']))
    c.kern_data['A']=[10,0]
    assert(c.has_ligkern?(['endash','A']))
    assert(! c.has_ligkern?(['endash','B']))
  end
  def test_lig
    lig=RFI::LIG.new("hyphen","endash","emdash",:"=:")
    assert_equal(lig.left,"hyphen")
    assert_equal(lig.right,"endash")
    assert_equal(lig.result,"emdash")
    assert_equal(lig.type,:"=:")    
  end
  def test_glyphlist
    gl=RFI::Glyphlist.new
    gl['endash']=RFI::Char.new('endash')
    gl.apply_ligkern_instructions("endash hyphen =: emdash")
    assert_equal(gl['endash'].lig_data['hyphen'].result,'emdash')

    gl['hyphen']=RFI::Char.new('hyphen')
    gl['hyphen'].kern_data={"A"=>[21,0],"T" => [-48,0]}
    gl.apply_ligkern_instructions("hyphen {} A")
    assert_equal(gl['hyphen'].kern_data,{"T" => [-48,0]})

    gl.apply_ligkern_instructions("hyphen {} *")
    assert_equal(gl['hyphen'].kern_data,{})
    assert_raise(ArgumentError) {
      gl.apply_ligkern_instructions("* {} *")
    }

    gl['hyphen'].kern_data={"A"=>[21,0],"T" => [-48,0]}
    assert(gl['hyphen'].x_kerns.member?(["A", 21]))
    assert(gl['hyphen'].x_kerns.member?(["T", -48]))

    gl['A']=RFI::Char.new('A')
    gl.apply_ligkern_instructions("A B =: C")
    gl.apply_ligkern_instructions("A D =: E")
    gl.apply_ligkern_instructions("A D =: F")
    # TODO: put this in tc_font
    # assert_equal(2,fm.get_lig('A').size)
    assert(gl['A'].has_ligkern?)

    gl['B']=RFI::Char.new('B')
    assert_equal(false, gl['B'].has_ligkern?)
    assert_raise(NoMethodError) {
      assert_equal(false, gl['C'].has_ligkern?)
    }

  end
  def test_glyphlist_uc_lc
    require 'font'
    font=Font.new
    font.load_variant("savorg__.afm")
    gl=font.defaultfm.chars
    gl.update_uc_lc_list
    assert(gl['A'].is_uppercase?)
    assert(gl['a'].is_lowercase?)
    assert(gl['AE'].is_uppercase?)
    assert(gl['ae'].is_lowercase?)
    assert_equal('OE',gl['oe'].capitalize)
    assert_equal('ae',gl['AE'].downcase)
    assert_equal('I',gl['dotlessi'].capitalize)
    assert_equal('SS',gl['germandbls'].capitalize)
    assert_equal(nil,gl['A'].capitalize)
  end
end
