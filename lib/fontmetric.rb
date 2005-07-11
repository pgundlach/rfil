# fontmetric.rb - superclass for different font metric formats
# Last Change: Mon Jul 11 22:51:19 2005

# FontMetric is the superclass for font metrics. All information that
# is not specific to a certain kind of file format is accessible via
# this class.

require 'rfi'

class FontMetric
  # to make Rdoc and Ruby happy: [ruby-talk:147778]
  def self.documented_as_accessor(*args); end
  def self.documented_as_reader(*args); end

  # Hash of glyphs in the font. 
  attr_accessor :chars

  # The filename of the just read metric file
  attr_accessor :filename

  # file name of the font containing the outlines (the file that needs
  # to be put into the pdf-file). The .tt or the .pfb file. If unset
  # use the value of filename, but changed to the correct extension in
  # case of Type 1 fonts.
  documented_as_accessor :fontfilename

  # Some unique name of the font. Use the filename of the font or a
  # name after the KB naming schema. Do not add an extension such as
  # afm or tt.
  attr_accessor :name
  
  # family name of the font
  attr_accessor :familyname

  # xheight in 1/1000 of an em
  attr_accessor :xheight

  attr_accessor :weight

  # natural width of a space
  documented_as_reader :space
  
  attr_accessor :italicangle

  # True if the font is a monospaced font (courier for example).
  attr_accessor :isfixedpitch

  # The official name of the font as supplied by the vendor. Written
  # as FontName in the afm file.
  attr_accessor :fontname

  # The full name of the font, whatever this means. Written as
  # FullName in the afm file.
  attr_accessor :fullname
  
  attr_accessor :efactor

  attr_accessor :slantfactor

  
  def initialize
    @chars=RFI::Glyphlist.new
    @info={}
    @efactor=1.0
    @slantfactor=0.0
  end

  def space  # :nodoc:
    chars['space'].wx
  end
  # This one is documented in the 'attributes' section. If the global
  # variable is unset, just use @filename, perhaps change afm to pfb
  def fontfilename # :nodoc:
    return @fontfilename if @fontfilename
    case @filename
    when /\.afm$/
      return @filename.chomp(".afm") + ".pfb"
    when /\.tt$/
      return @filename
    end
  end

  def transform (x,y)
    (@efactor * x + @slantfactor * y).round
  end
end

__END__

  def fake_caps (factor)
    # we need to do the following
    # 1. adapt kerning pairs
    # 2. change font metrics (wd)
    # 3. remove ligatures from sc

    @fake_caps=true
    @capheight=factor
    @chars.each { |glyphname,char|
      # puts "glyphname=#{glyphname}, char=#{char}"
      
      if is_lowercase?(glyphname)
        # remove ligatures from sc
        char.lig_data={}
        
        char.kern_data={}
        
        @chars[capitalize(glyphname)].kern_data.each { |destglyph,kerndata|
          unless is_lowercase?(destglyph)
            char.kern_data[destglyph.downcase]=[kerndata[0] * factor,0]
          end
        }
        char.b = @chars[capitalize(glyphname)].b.clone
        char.wx = @chars[capitalize(glyphname)].wx * @capheight
        char.lly *= @capheight
        char.urx *= @capheight
          
      else # char is something like Aring, semicolon, ...
        # if destchar is uppercase letter (A, Aring, ...)
        # 1. delete all kerns to lowercase letters (not e.g. semicolon)
        # 2. duplicate all uc kerns, multiply by factor and insert this
        #    as lc kern
        char.kern_data.delete_if { |destglyph,kerndata|
          is_lowercase?(destglyph)
        }

        new_kern_data={}
        char.kern_data.each { |destglyph,kerndata|
          if is_uppercase?(destglyph)
            new_kern_data[destglyph.downcase]=[kerndata[0]*factor,kerndata[1]]
          end
          new_kern_data[destglyph]=kerndata
        }
        char.kern_data=new_kern_data
      end
      # 2.  
    }
    if @chars['germandbls']
      s=@chars['S']
      d=@chars['germandbls']
      d.b = s.b.dup
      d.wx = s.wx * 2 * @capheight
      d.urx += s.wx
      d.kern_data={}
      @chars['S'].kern_data.each { |destglyph,kerndata|
        unless is_lowercase?(destglyph)
          d.kern_data[destglyph.downcase]=[kerndata[0] * @capheight,0]
        end
      }
        
      # d.kern_data = s.kern_data.dup
      d.pcc_data=[['S',0,0],['S',s.wx,0]]
      d.lly *= @capheight
      d.urx *= @capheight

    end
  end
  
  # A,Aring,... are all "uppercase" glyphs
  def is_uppercase?(glyphname)
    # simple approach first
    return glyphname[0].chr =~ /[A-Z]/ ?  true : false
  end
  
  # a,aring are "lowercase" glyphs, but hyphen is not  
  def is_lowercase?(glyphname)
    return true if glyphname == 'dotlessi'
    return true if glyphname == 'dotlessj'
    return true if glyphname == 'germandbls'
    return true if glyphname.size==1 and glyphname[0].chr =~ /[a-z]/
    return true if %w( ae oe ).member?(glyphname)
    return false if glyphname[0].chr =~ /[A-Z]/
    return @chars[glyphname.capitalize] != nil
  end

  # ae -> AE, lslash -> Lslash, hyphen -> bang (ArgumentError)
  # dotlessi -> I
  def capitalize(glyphname)
    return 'I' if glyphname == 'dotlessi'
    return 'J' if glyphname == 'dotlessj'
    return 'S' if glyphname == 'germandbls'
    return glyphname.upcase if %w( ae oe ).member?(glyphname)
    return glyphname.capitalize if is_lowercase?(glyphname)
    raise ArgumentError, "glyphname (#{glyphname}) cannot be capitalized"
  end

  
