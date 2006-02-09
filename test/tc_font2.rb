#!/opt/ruby/1.8/bin/ruby

require 'test/unit'

$:.unshift File.join(File.dirname(__FILE__), "..", "lib")

require 'font'

class TestFontb < Test::Unit::TestCase
  include TeX
  def test_write
    t=Time.new
    # I want to see which files actually changed. A more clever solution?
    sleep 1
    
    destdir=File.join(Dir.getwd,"output")
    f=File.join(destdir,"savorg__.vf")
    if File.exists? f
      assert(File.mtime(f) < t)
    end
    font=RFI::Font.new
    font.load_variant("savorg__.afm")
    font.set_dirs(destdir)
    font.write_files
    assert(File.mtime(File.join(destdir,"savorg__.vf")) > t)
    font.texenc=["ec.enc","texnansi.enc"]
    #font.texenc=["texnansi.enc"]
    font.write_files
    
    filepath=(File.join(destdir,"ec-savorg__.vf"))
    assert(File.exists?(filepath), "I cannot find: #{filepath}")
    assert(File.mtime(filepath) > t,
           "The file #{filepath} did not change as I thought it would.")
    assert(File.mtime(File.join(destdir,"texnansi-savorg__.vf")) > t)
  end
  
end
