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
#     @kpse=Kpathsea.new
#     @kpse.open_file("ec.enc","enc") { |f|
#       @ecenc=ENC.new(f)
#     }
#     @kpse.open_file("texnansi.enc","enc") { |f|
#       @texnansienc=ENC.new(f)
#     }
  end
  def test_bar
    @kpse=Kpathsea.new
     @kpse.open_file("ec.enc","enc") { |f|
       @ecenc=ENC.new(f)
     }
    a=ENC.new
    p a.class
    a.encname="foo"
    p a.encname
    p a.size
    
  end
  def test_foo
    return
#     require 'fontcollection'
    destdir=File.join(Dir.getwd,"output")
#     fc=FontCollection.new('savoy')
#     fc.set_dirs(destdir)
#     regular=Font.new(fc)
#     regular.load_variant("savorg__.afm")
#     italic=Font.new(fc)
#     italic.load_variant("savoi___.afm")

#     fc.mapenc="8r"
#     fc.texenc="ec"

#     # magic!
#     puts fc.write_files
    f=Font.new
    f.texenc="ec"
    f.set_dirs(destdir)
    f.load_variant("savorg__.afm")
    fc = f.load_variant("savorg__.afm")
    f.fake_caps(fc,0.8)
    f.copy(fc,:lowercase)
    f.defaultfm.chars.apply_ligkern_instructions(RFI::STDLIGKERN)
    f.write_files
#    v = font.vpl(font.mapenc,font.texenc[0])
    # p v.mapfont
    # puts v.to_s
#    font.write_files(:dryrun => false,:verbose=>false)
  end
end

# (CHARACTER D 99
#    (COMMENT c)
#    (CHARWD R 433)
#    (CHARHT R 426)
#    (CHARDP R 14)
#    )


# (CHARACTER D 99
#    (COMMENT c)
#    (CHARWD R 346.4)
#    (CHARHT R 678)
#    (CHARDP R 10.4)
#    (CHARIC R 178.4)
#    (MAP
#       (SELECTFONT D 1)
#       (SETCHAR D 67)
#       )
#    )

