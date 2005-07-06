#!/usr/bin/env ruby

# Last Change: Wed Jul  6 16:44:09 2005

# Reimplementation of afm2tfm, as shipped with dvips
# This is not the reimplementation I mentioned at the 35th NTG meeting

require 'optparse'
require 'ostruct'

$:.unshift File.join(File.dirname(__FILE__),"..","lib")


require 'font'

options=OpenStruct.new
options.capheight = 0.8

ARGV.options { |opt|
  opt.banner = "Usage: #{File.basename($0)} FILE[.afm] [options] ... [FILE[.tfm]]"
  opt.on("-c REAL", Float,
         "use REAL for height of small caps made with -V [0.8]") {|c|
    if c and c >= 0.01
      options.capheight=c
    else
      puts "! Bad small caps height"
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
  # the -u behaviour is not copied verbatim. afm2tfm introduces some
  # randomness: for example, when going '-t ec -p 8r': O 200 (Abreve)
  # is not in 8r encoding, so it could do O 200 -> O 200 (Euro), but
  # assume that this is not in the font. afm2tfm does now O 200 -> O 4
  # (fraction), for whatever reason. If fraction is not in the font,
  # afm2tfm does O 200 -> O 252 (ordfeminine). Why? Because.
  #opt.on("-u","output only characters from encodings, nothing extra") {
  #  mixencodings=false
  #}
  opt.on("-v FILE[.vpl]", String, "make a VPL file for conversion to VF") { |v|
    options.writevf=true
    options.vffile=v
  }
  opt.on("-V SCFILE[.vpl]","like -v, but synthesize smallcaps as lowercase") { |v|
    writevf=true
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
font.load_variant(inputfile)


font.texenc=options.texenc || "8a.enc"
font.mapenc=options.mapenc || "8a.enc"
fn=font.map_fontname(font.mapenc) + ".tfm"
font.pl(font.texenc[0]).write_tfm(File.join(font.get_dir(:tfm),fn))

if options.fakecaps
  fc = font.load_variant(inputfile)
  font.fake_caps(fc,options.capheight)
  font.copy(fc,:lowercase)
end

vf=File.join(font.get_dir(:vf),options.vffile+".vf")
tfm=File.join(font.get_dir(:tfm),options.vffile+ ".tfm")
font.vpl(font.mapenc,font.texenc[0]).write_vf(vf,tfm)


# puts font.vpl(font.mapenc,font.texenc[0]).to_s

                          exit

a.read
# inenc, outenc and font are set
a.mixencodings if mixencodings
a.create_tfm
#puts a.create_pl
if writevf
  a.create_vpl
end
puts a.mapline
