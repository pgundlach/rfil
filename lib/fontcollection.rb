# fontcollection.rb
# Last Change: Sun Jul  3 23:41:18 2005

require 'helper'

# A set of fonts (regular,bold,italic). Used to write an fd-file for
# LaTeX or a typescript for ConTeXt. Register different fonts and set
# encodings, so you dont't have to specify them in each font.

class FontCollection
  include Helper
  # Name of the font collection
  attr_accessor :name
  
  # One object or one or more objects in an array that describe the
  # encoding of the postscript font. Object can either be a string
  # that represents the filename of the encoding ("8r.enc", "8r") or
  # an ENC object that already contains the encoding
  attr_accessor :mapenc

  # One object or one ore more objects in an array that describe the
  # encoding of the font TeX expects. Object can either be a string
  # that represents the filename of the encoding ("8r.enc", "8r") or
  # an ENC object that already contains the encoding
  attr_accessor :texenc

  # hash of directories for writing files. Default to current working
  # directory. The setting in the Font object overrides the setting here.  
  attr_accessor :dirs
  
  def initialize(name)
    @kpse=Kpathsea.new
    @name=name
    @mapenc=[]
    @texenc=[]
    @fonts=[]
    @dirs={}
    set_dirs(Dir.getwd)
  end
  
  # Add a font to the collection.
  def register_font (font)
    unless font.respond_to?(:maplines)
      raise ArgumentError, "parameter does not look like a font"
    end
    @fonts.push(font)
  end

  def mapfile
    m=""
    @fonts.each{ |font|
      font.maplines.each{ |ml|
        m << ml << "\n"
      }
    }
    m
  end
  # You can set only one .map-encoding
  def mapenc=(enc) # :nodoc:
    @mapenc=nil
    if enc.instance_of?(ENC)
      @mapenc = enc
    else
      enc.find { |e|
        if e.instance_of?(String)
          @kpse.open_file(e,"enc") { |f|
            @mapenc = ENC.new(f)
          }
          elsif e.instance_of?(ENC)
          @mapenc = ENC
        end
      }
    end
    # set_enc(enc,@mapenc)
  end
  def texenc=(enc) # :nodoc:
    @texenc=[]
    set_enc(enc,@texenc)
  end
  def get_dir(type)
    @dirs[type]
  end
end
