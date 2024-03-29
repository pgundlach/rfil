#! /usr/bin/env ruby
# Last Change: Tue May 16 17:11:39 2006

# unittest.rb
# this file runs all test

$:.unshift  File.join(File.dirname(__FILE__), "..", "lib")

require 'tex/kpathsea'
Dir.chdir 'test' unless Dir.pwd =~ /test$/

require 'test/unit'

require 'tc_enc'
require 'tc_kpathsea'
require 'tc_afm'
require 'tc_truetype'
require 'tc_fontmetric'
require 'tc_metric'
require 'tc_font'
require "tc_ziff"
# font2 is slow
require 'tc_font2'
require 'tc_fontcollection'
require 'tc_font_fontcollection'
require 'tc_rfi'
require 'tc_tfm'
require 'tc_vf'
