#!/usr/bin/env ruby


require "test/unit"
$:.unshift  File.join(File.dirname(__FILE__), "..", "lib")

require "rfil/font"

class TestZiff < Test::Unit::TestCase
  include RFIL

  def test_ziff
    font=RFI::Font.new
    font.load_variant("Ziff.afm")
    font.mapenc="ec"

    font.to_tfm(font.mapenc)
  end
end