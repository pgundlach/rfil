#!/opt/ruby/1.8/bin/ruby

require 'test/unit'

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'rfil/rfi'
require 'rfil/font/metric'


# The samples are taken from afm2tfm output from savorg__.afm.

class TestFontMetric < Test::Unit::TestCase
  include RFIL
  def test_fm
    fm=Font::Metric.new
    fm.familyname="FamilyName"
    assert_equal(fm.familyname,"FamilyName")
  end

  def test_filename
    fm=Font::Metric.new
    fm.pathname="foo.afm"
    assert_equal("foo.pfb",fm.fontfilename)
    
    fm.pathname="bar.tt"
    assert_equal("bar.tt",fm.fontfilename)

    fm.fontfilename="baz.otf"
    assert_equal("baz.otf",fm.fontfilename)
  end
  
#   def test_isupper_islower
#     fm=FontFont::Metric.new
#     fm.chars['hyphen']=RFI::Char.new('hyphen')
#     # simple case:
#     fm.chars['B']=RFI::Char.new('B')
#     fm.chars['b']=RFI::Char.new('b')
#     assert(fm.is_uppercase?("B"))
#     assert_equal(false,fm.is_lowercase?("B"))
#     assert(fm.is_lowercase?("b"))
#     assert_equal(false,fm.is_uppercase?("b"))
#     # no 'other' char:
#     fm.chars['f']=RFI::Char.new('f')
#     fm.chars['G']=RFI::Char.new('G')
#     assert(fm.is_uppercase?("G"))
#     assert_equal(false,fm.is_lowercase?("G"))
#     assert(fm.is_lowercase?("f"))
#     assert_equal(false,fm.is_uppercase?("f"))
#     # 'difficult', cannot just capitalize the name
#     fm.chars['ae']=RFI::Char.new('ae')
#     fm.chars['AE']=RFI::Char.new('AE')
#     assert(fm.is_uppercase?("AE"))
#     assert_equal(false,fm.is_lowercase?("AE"))
#     assert(fm.is_lowercase?("ae"))
#     assert_equal(false,fm.is_uppercase?("ae"))
#     assert_equal(false,fm.is_lowercase?("hyphen"))
#     assert_equal(false,fm.is_lowercase?("hyphen"))
#     assert_equal("AE",fm.capitalize("ae"))
#     assert_raise(ArgumentError) {
#       fm.capitalize("hyphen")
#     }
#     assert(fm.is_lowercase?('dotlessi'))
#     assert_equal(false,fm.is_uppercase?('dotlessi'))
#     assert_equal("I",fm.capitalize('dotlessi'))
#     assert_equal("J",fm.capitalize('dotlessj'))
#     assert(! fm.is_lowercase?('underscore'))
#     assert(fm.is_lowercase?('germandbls'))
#   end

  def test_fake_caps
    fm=Font::Metric.new
    fm.chars=RFI::Glyphlist.new
    fm.chars['B']=RFI::Char.new('B')
    fm.chars['b']=RFI::Char.new('b')
    fm.chars['ogonek'] = RFI::Char.new('ogonek')
    fm.chars['fi'] = RFI::Char.new('fi')
    fm.chars['y'] = RFI::Char.new('y')
    fm.chars['Y'] = RFI::Char.new('Y')
    fm.chars['B'].kern_data={'ogonek'=>[-3,0],'fi'=>[5,0],'Y'=>[-19,0] }
    fm.chars['b'].kern_data={'y'=>[-4,0] }

    c=RFI::Char.new('F')
    fm.chars['F'] = c
    c.b=[33, -2, 499, 669]
    c.wx=520

    c=RFI::Char.new('f')
    fm.chars['f']=c
    c=fm.chars['f']
    c.b=[25, -2, 345, 730]
    c.wx=308


    fm.chars['i']=RFI::Char.new('i')
    fm.chars['I']=RFI::Char.new('I')
    fm.chars.apply_ligkern_instructions("f i =: fi")
    assert_equal('fi',fm.chars['f'].lig_data['i'].result)

    # fm.chars.fix_height(415)
    fm.chars.fake_caps(0.5)
    # ligs deleted
    assert_equal(nil,fm.chars['f'].lig_data['i'])
    assert_equal(fm.chars['B'].kern_data,
                 {'ogonek'=>[-3,0],'fi'=>[5,0],'y'=>[-9.5,0],'Y'=>[-19,0] })
    assert_equal(fm.chars['b'].kern_data,
                 {'ogonek'=>[-1.5,0],'fi'=>[2.5,0],'y'=>[-9.5,0] })

    assert_equal('F',fm.chars['f'].mapto)
    assert_equal(260,fm.chars['f'].wx)
    assert_equal(334.5,fm.chars['f'].charht)
    assert_equal(1,fm.chars['f'].chardp)
    assert_equal(0,fm.chars['f'].charic)
  end
#!!!! -> move to tc_font
  #   def test_transform
#     fm=Font::Metric.new
#     assert_equal(200,fm.transform(200,0))
#     fm.efactor=0.5
#     assert_equal(100,fm.transform(200,0))
#     fm.efactor=1
#     fm.slantfactor=0.50
#     assert_equal(20,fm.transform(10,20))
#   end
end
