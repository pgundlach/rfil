#!/usr/bin/env ruby
#--
# Last Change: Wed Jul 13 16:30:01 2005
#++
=begin rdoc
== afm2tfm using the ruby font installer library
This is a re-implementation of afm2tfm that is part of dvips. This
does not aim for a 100% compatible output, since that would be too
hard to implement. For example, the absence of the <tt>-u</tt>-switch in
afm2tfm introduces some randomnes, so we assume that <tt>-u</tt> is
always given.

  Usage: afm2tfm.rb [options] FILE[.afm] ... [FILE[.tfm]]
      -c REAL                          use REAL for height of small caps made with -V [0.8]
      -d DIRNAME                       Set the base output directory to DIRNAME
      -e REAL                          widen (extend) characters by a factor of REAL
      -p ENCFILE                       read/download ENCFILE for the PostScript encoding
      -s REAL                          oblique (slant) characters by REAL, generally <<1
      -t ENCFILE                       read ENCFILE for the encoding of the vpl file
      -T ENCFILE                       equivalent to -p ENCFILE -t ENCFILE
      -v FILE[.vpl]                    make a VF file
      -V SCFILE[.vpl]                  like -v, but synthesize smallcaps as lowercase
          --help                       print this message and exit.
          --version                    print version number and exit.
  
---
Remark: this is not the reimplementation I mentioned at the 35th NTG meeting

Author:: Patrick Gundlach <patrickg@despammed.com>
License::  Copyright (c) 2005 Patrick Gundlach.
           Released under the terms of the GNU General Public License
=end 


# :enddoc:

require 'optparse'
require 'ostruct'

$:.unshift File.join(File.dirname(__FILE__),"..","lib")


require 'font'

options=OpenStruct.new
options.capheight = 0.8

ARGV.options { |opt|
  opt.banner = "Usage: #{File.basename($0)} [options] FILE[.afm] ... [FILE[.tfm]]"
  opt.on("-c REAL", Float,
         "use REAL for height of small caps made with -V [0.8]") {|c|
    if c and c >= 0.01
      options.capheight=c
    else
      puts "! Bad small caps height"
      exit -1
    end
  }
  opt.on("-d DIRNAME", String, "Set the base output directory to DIRNAME") {|d|
    if File.exists?(d) and File.directory?(d)
      options.dirname=d
    else
      puts "! #{d} does not exist or is not a directory"
      exit -1
    end
  }
  opt.on("-e REAL", Float, "widen (extend) characters by a factor of REAL") {|e|
    # this test should be in class AFM
    if e and e >= 0.01
      options.efactor=e
    else
      puts "! Bad extension factor"
      exit -1
    end
  }
    
#  opt.on("-O", "use octal for all character codes in the vpl file") {
#    a.use_octal=true
#  }
  opt.on("-p ENCFILE", "read/download ENCFILE for the PostScript encoding") {|e|
    options.mapenc =  e
  }
  opt.on("-s REAL",Float,"oblique (slant) characters by REAL, generally <<1") {|s|
    if s
      options.slant=s
    else
      puts "! Bad slant parameter"
      exit -1
    end
  }
    
  opt.on("-t ENCFILE", "read ENCFILE for the encoding of the vpl file") {|e|
    options.mapenc = e
  }
  opt.on("-T ENCFILE",String,"equivalent to -p ENCFILE -t ENCFILE") {|e|
    options.mapenc  = e
    options.texenc = e
  }
  opt.on("-v FILE[.vpl]", String, "make a VF file") { |v|
    options.vffile=v
  }
  opt.on("-V SCFILE[.vpl]","like -v, but synthesize smallcaps as lowercase") { |v|
    options.vffile=v
    options.fakecaps=true
  }
  opt.on("--help","print this message and exit.") { puts opt; exit 0 }
  opt.on("--version","print version number and exit.") {
    puts "#{File.basename($0)}: Version 0.1"
    puts "[Based on afm2tfm(k) (dvips(k) 5.95a) 8.1 (C) 2005 Radical Eye Software.]"
    puts "experimental!"
    exit
  }
  opt.parse!
}

if ARGV.size == 0
  puts "#{File.basename($0)}: Need at least one file argument."
  puts "Try `#{File.basename($0)} --help' for more information."
  exit 0
end

options.inputfilename=ARGV.shift

if ARGV.size >0
  options.outputfilename=ARGV.shift
end

inputfile=(options.inputfilename.chomp(".afm") + ".afm")
font = Font.new

if options.dirname
  font.set_dirs(options.dirname)
end
                
begin
  font.load_variant(inputfile)
rescue Errno::ENOENT
  puts "! Cannot find file #{inputfile}"
  exit -1
end


font.texenc=options.texenc || "8a.enc"
font.mapenc=options.mapenc || "8a.enc"
fn=font.map_fontname(font.mapenc) + ".tfm"
font.pl(font.texenc[0]).write_tfm(File.join(font.get_dir(:tfm),fn))


if options.fakecaps
  fc = font.load_variant(inputfile)
  font.fake_caps(fc,options.capheight)
  font.copy(fc,:lowercase)
end

if options.vffile
  font.apply_ligkern_instructions(RFI::STDLIGKERN)
  vf=File.join(font.get_dir(:vf),options.vffile+".vf")
  tfm=File.join(font.get_dir(:tfm),options.vffile+ ".tfm")
  font.vpl(font.mapenc,font.texenc[0]).write_vf(vf,tfm)
end
puts font.maplines

