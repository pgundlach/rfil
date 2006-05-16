#--
# fontcollection.rb
# Last Change: Tue May 16 19:02:11 2006
#++

require 'rfil/rfi'
require 'rfil/font'
require 'rfil/helper'

module RFIL # :nodoc: 
  class RFI
    # A set of fonts (regular,bold,italic). Used to write an fd-file for
    # LaTeX or a typescript for ConTeXt. Register different fonts and set
    # encodings, so you dont't have to specify them in each font.
    
    class FontCollection
      include Helper
      def self.documented_as_accessor(*args) # :nodoc:
      end 
      def self.documented_as_reader(*args) # :nodoc:
      end 

      attr_accessor :vendor

      # attr_accessor :fontname
      
      # Name of the font (collection)
      attr_accessor :name
      
      # One object or one or more objects in an array that describe the
      # encoding of the postscript font. Object can either be a string
      # that represents the filename of the encoding ("8r.enc", "8r") or
      # an ENC object that already contains the encoding
      documented_as_accessor :mapenc

      # One object or one ore more objects in an array that describe the
      # encoding of the font TeX expects. Object can either be a string
      # that represents the filename of the encoding ("8r.enc", "8r") or
      # an ENC object that already contains the encoding
      documented_as_accessor :texenc

      # hash of directories for writing files. Default to current working
      # directory. The setting in the Font object overrides the setting here.
      attr_accessor :dirs

      attr_accessor :fonts

      # sans, roman, typewriter
      attr_accessor :style

      attr_accessor :write_vf

      attr_accessor :options
      
      # list of temps
      documented_as_reader :plugins
      
      def initialize()
        @kpse=Kpathsea.new
        @basedir=nil
        @name=nil
        @texenc=nil
        @mapenc=nil
        @write_vf=true
        @fonts=[]
        @options={:verbose=>false,:dryrun=>false}
        @style=nil
        @dirs={}
        @vendor=nil
        @fontname=nil
        set_dirs(Dir.getwd)
        @plugins={}
        # find temps-plugins
        $:.each{ |d|
          a=Dir.glob(d+"/rfil/rfi_plugin_*.rb")
          a.each{ |f|
            require f
          }
        }
        ObjectSpace.each_object(Class){ |x|
          if Plugin > x
            t = x.new(self)
            n = t.name
            if @plugins.has_key?(n)
              raise "Name already registered"
            end
            @plugins[n]=t
          end
        }
        # done initializing plugins
      end
      
      # Add a font to the collection. Return the number of the font.
      def register_font (font)
        unless font.respond_to?(:maplines)
          raise ArgumentError, "parameter does not look like a font"
        end
        fontnumber=@fonts.size
        @fonts << font
        return fontnumber
      end
      
      def run_plugin(name)

        raise "don't know plugin #{name}" unless @plugins.has_key?(name)
        
        # doc for run_plugin
        # Return the contents of the file that should be used by the TeX
        # macro package, i.e a typescript for ConTeXt or an fd-file for
        # Context. Return value is an Array of Hashes. The Hash has three
        # different keys:
        # [<tt>:type</tt>] The type of the file, should be either <tt>:fd</tt> or <tt>:typescript</tt>.
        # [<tt>:filename</tt>] the filename (without a path) of the file
        # [<tt>:contents</tt>] the contents of the file.

        files=@plugins[name].run_plugin
        if files.respond_to?(:each)
          files.each { |fh|
            dir=get_dir(fh[:type])
            filename=File.join(dir,fh[:filename])
            puts "writing file #{filename}" if @options[:verbose]
            
            unless @options[:dryrun]
              ensure_dir(dir)
              File.open(filename,"w") { |f| f << fh[:contents] }              
            end
          }
        end
      end
      def plugins #:nodoc:
        @plugins.keys
      end
      def mapfile
        mapfile=[]
        @fonts.each {|font|
          mapfile << font.maplines
        }
        mapfile.flatten
      end
      def mapenc        # :nodoc:
        return nil if @mapenc==:none
        @mapenc
      end
      def mapenc= (enc)  # :nodoc:
        set_mapenc(enc)
      end
      def texenc       # :nodoc:
        if @texenc
          @texenc
        else
          # @texenc not set
          ret=nil
          @kpse.open_file("8a.enc","enc") { |f|
            ret = [ENC.new(f)]
          }
          return ret
        end
      end
      def texenc= (enc) # :nodoc:
        @texenc=[]
        set_encarray(enc,@texenc)
      end
      def get_dir(type)
        @dirs[type]
      end
      def write_files(options={})
        mapdir=get_dir(:map); ensure_dir(mapdir)
        
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
  end # class RFI
end # module RFIL
