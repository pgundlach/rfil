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
    f=@kpse.open_file("ec.enc","enc") { |f|
      @ecenc=ENC.new(f)
    }
    f=@kpse.open_file("texnansi.enc","enc") { |f|
      @texnansienc=ENC.new(f)
    }
  end

  def test_foo
    destdir=File.join(Dir.getwd,"output")
    font=Font.new
    font.set_dirs(destdir)
    font.load_variant("savorg__.afm")
    fc=font.load_variant("savorg__.afm")
     font.fake_caps(fc,0.5)
    font.copy(fc, :lowercase)
    font.mapenc="8r"
    font.texenc="ec"
    font.defaultfm.chars.apply_ligkern_instructions(RFI::STDLIGKERN)
    # puts font.vpl(font.mapenc,font.texenc[0]).to_s
    font.write_files(:dryrun => false,:verbose=>false)
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

