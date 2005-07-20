# fontmetric.rb - superclass for different font metric formats
# Last Change: Thu Jul 21 01:09:11 2005

# FontMetric is the superclass for font metrics. All information that
# is not specific to a certain kind of file format is accessible via
# this class.

require 'rfi'
class FontMetric
  # to make Rdoc and Ruby happy: [ruby-talk:147778]
  def self.documented_as_accessor(*args) # :nodoc:
  end 
  def self.documented_as_reader(*args)   # :nodoc:
  end
  
  # :type1, :truetype
  attr_accessor :outlinetype
  
  # Hash of glyphs in the font. 
  attr_accessor :chars

  # The filename of the just read metric file. Does not contain the
  # path. To set, change the pathname
  documented_as_reader :filename

  # Absolute pathname of the metric file. Not checked when set.
  attr_accessor :pathname
  
  # File name of the font containing the outlines (the file that needs
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
  
  def initialize
    @chars=RFI::Glyphlist.new
    @outlinetype=nil
    @info={}
    @fontfilename=nil
    @efactor=1.0
    @slantfactor=0.0
    @pathname=nil
  end

  def space  # :nodoc:
    chars['space'].wx
  end

  def filename
    File.basename(@pathname)
  end

  def fontfilename= (obj)  # :nodoc:
    @fontfilename=obj
  end
      
  # This one is documented in the 'attributes' section. If the global
  # variable is unset, just use @filename, perhaps change afm to pfb
  def fontfilename # :nodoc:
    return @fontfilename if @fontfilename
    case filename
    when /\.afm$/
      return filename.chomp(".afm") + ".pfb"
    when /\.tt$/
      return filename
    end
  end
end
