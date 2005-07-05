# fontcollection.rb
# Last Change: Wed Jul  6 00:03:00 2005

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
  def mapenc=(enc) # :nodoc:
    set_mapenc(enc)
  end
  def texenc=(enc) # :nodoc:
    @texenc=[]
    set_encarray(enc,@texenc)
  end
  def get_dir(type)
    @dirs[type]
  end
  def write_files(options={})
    mapdir=get_dir(:map); ensure_dir(mapdir)
    
    mapfile=[]
    @fonts.each {|font|
      font.write_files(:mapfile => false)
      mapfile << font.maplines
    }
    mapfilename=File.join(mapdir,@name+".map")
    unless options[:dryrun]==true
      File.open(mapfilename, "w") {|file|
        file << mapfile.to_s
      }
    end
  end
end
