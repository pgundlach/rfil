#!/usr/bin/env ruby
#--
# Last Change: Tue May 16 18:10:52 2006
#++
=begin rdoc
== afm2tfm using the ruby font installer library
This is a re-implementation of afm2tfm that is part of dvips. This
does not aim for a 100% compatible output. There are some differences
in the calculation of the font metrics, which, in my opinion, are
reasonable. The -u and -o switch are missing from this implementation.

  Usage: afm2tfm.rb [options] FILE[.afm,.ttf] ... [FILE[.tfm]]
      -c REAL                          use REAL for height of small caps made with -V [0.8]
      -d DIRNAME                       Set the base output directory to DIRNAME
      -e REAL                          widen (extend) characters by a factor of REAL
      -l                               Include ligature and kerning information in tfm file
      -p ENCFILE                       read/download ENCFILE for the PostScript encoding
      -s REAL                          oblique (slant) characters by REAL, generally <<1
      -t ENCFILE                       read ENCFILE for the encoding of the vf file
      -T ENCFILE                       equivalent to -p ENCFILE -t ENCFILE
      -v [FILE]                        make a VF file with filename FILE
      -V [SCFILE]                      like -v, but synthesize smallcaps as lowercase
          --help                       print this message and exit.
          --version                    print version number and exit.

= Usage
See the documentation of the original afm2tfm for an explanation of
the parameters -c, -e, -s, -p, -t, -T, -v and -V.

afm2tfm.rb creates a tfm (tex font metric) file from the font given as
the first argument. This font can be a Postscript Type 1 font metric
file (afm) or a TrueType font. (So the name of the program is a bit
misleading, it is not restricted to Type 1 font metric files.) The tfm
file is written assuming that the underlying TeX text is encoded in
the encoding given with the -p parameter.  

[<tt>-d</tt> DIRNAME] Set the base directory to DIRNAME. All files are written to the base directory. If unset, use the current directory.
[<tt>-l</tt>] Don't discard the ligature and kerning information when writing the tfm file.
[<tt>-v</tt>, <tt>-V</tt> FILE] The filename of the virtual fonts is optional. When unset, construct a name such as <tt>ec-savorg__-capitalized-800</tt>.
---
Remark: this is not the reimplementation I mentioned at the 35th NTG meeting.

Author:: Patrick Gundlach <patrick@gundla.ch>
License::  Copyright (c) 2005 Patrick Gundlach.
           Released under the terms of the GNU General Public License
=end 


# :enddoc:

# font metric differences between afm2tfm and afm2tfm.rb
# tfm: fix_height is applied before writing out the tfm file, so the height
#   of the glpyphs are different.
# slant: charic calculation in the vpl file is not affected by the
#      texheight in afm2tfm.c, but in afm2tfm.rb the height is changed
#      before cahric calculation
# other:
#       in my testfont, the hyphen has a different height in the tfm
#       file: 732 (afm2tfm.c) vs. 240 (afm2tfm.rb)

require 'optparse'
require 'ostruct'
require 'rfil/font'

include RFIL
options=OpenStruct.new

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

  opt.on("-l", "Include ligature and kerning information in tfm file") {
    options.ligkern=true
  }
  
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
    
  opt.on("-t ENCFILE", "read ENCFILE for the encoding of the vf file") {|e|
    options.texenc = e
  }
  opt.on("-T ENCFILE",String,"equivalent to -p ENCFILE -t ENCFILE") {|e|
    options.mapenc  = e
    options.texenc = e
  }
  opt.on("-v [FILE]", String, "make a VF file with filename FILE") { |v|
    options.write_vf=true
    options.vffile=v
  }
  opt.on("-V [SCFILE]","like -v, but synthesize smallcaps as lowercase") { |v|
    options.vffile=v
    options.write_vf=true
    options.fakecaps=true
  }
  opt.on("--help","print this message and exit.") { puts opt; exit 0 }
  opt.on("--version","print version number and exit.") {
    puts "#{File.basename($0)}: Version 0.9"
    puts "Uses RFI Library (https://foundry.supelec.fr/projects/rfil)"
    puts "[Based on afm2tfm(k) (dvips(k) 5.95a) 8.1 (C) 2005 Radical Eye Software.]"
    exit
  }
  opt.parse!
}

if ARGV.size == 0
  puts "#{File.basename($0)}: Need at least one file argument."
  puts "Try `#{File.basename($0)} --help' for more information."
  exit 0
end

inputfile=ARGV.shift

if ARGV.size >0
  options.outputfilename=ARGV.shift
end

font = RFI::Font.new
font.write_vf = options.write_vf

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

font.apply_ligkern_instructions(RFI::STDLIGKERN)

font.efactor=options.efactor || 1.0
font.slant  =options.slant   || 0.0

ploptions=options.ligkern==true ? {:noligs=>false} : {:noligs=>true}

fn=font.map_fontname(font.mapenc) + ".tfm"
f=font.to_tfm(font.mapenc,ploptions)
f.tfmpathname=File.join(font.get_dir(:tfm),fn)
f.save(true)

if options.fakecaps
  fc = font.load_variant(inputfile)
  font.fake_caps(fc,options.capheight || 0.8)
  font.copy(fc,:lowercase,:ligkern=>true)
end

if options.write_vf
  vffilename=if options.vffile
               options.vffile
             else
               font.tex_fontname(font.texenc[0])
             end
  vf= File.join(font.get_dir(:vf) ,vffilename+".vf")
  tfm=File.join(font.get_dir(:tfm),vffilename+ ".tfm")
  vpl=font.to_vf(font.mapenc,font.texenc[0])
  vpl.tfmpathname=File.join(font.get_dir(:tfm) ,vffilename + ".tfm")
  vpl.vfpathname=File.join(font.get_dir(:vpl) ,vffilename + ".vf")
  vpl.save(true)
  #  vplfile= File.join(font.get_dir(:vpl) ,vffilename + ".vpl")
  #  vpl.write_vpl(vplfile)
  #  vpl.write_vf(vf,tfm)
end
puts font.maplines

