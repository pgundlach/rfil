#! /usr/bin/env ruby
# Last Change: Tue Mar  7 21:30:27 2006

# unittest.rb
# this file runs all test

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
# font2 is slow
require 'tc_font2'
require 'tc_fontcollection'
require 'tc_font_fontcollection'
require 'tc_rfi'
require 'tc_tfm'
require 'tc_vf'
