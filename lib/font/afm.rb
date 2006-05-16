# Last Change: Tue May 16 14:40:57 2006

# require 'rfi'

require 'strscan'
require 'pathname'

require 'font/metric'

module Font
  # = AFM -- Access type1 font metric files
  #
  # == General information
  #
  # Read and parse a (type1) afm file. The afm file must be compliant to
  # the afm specification as described in 'Adobe Font Metrics File
  # Format Specification' Version 4.1, dated October 7 1998.
  #
  # == Example usage
  #
  # === Read an afm file
  #  filename = "/opt/tetex/3.0/texmf/fonts/afm/urw/palatino/uplb8a.afm"
  #  afm=AFM.new
  #  afm.read(filename)
  #  afm.filename           # => "/opt/..../uplb8a.afm"
  #  afm.count_charmetrics  # => 316
  #  afm.encodingscheme     # => "AdobeStandardEncoding"
  #  # ....
  #
  class AFM < Metric

    # This is set to true if there is something wrong in the afm file.
    # Diagnostics can be turned on with <tt>:verbose</tt> set to true
    # when creating the object.
    attr_reader :something_strange

    # Number of characters found in the afm file.
    attr_accessor :count_charmetrics

    # Number of encoded character found in the afm file.
    attr_accessor :count_charmetrics_encoded

    # Number of unencoded character found in the afm file.
    attr_accessor :count_charmetrics_unencoded

    # The default encoding of the font.
    attr_accessor :encodingscheme

    # Boundingbox of the font. Array of for elements.
    attr_accessor :fontbbox

    # Underline position of the font.
    attr_accessor :underlineposition

    # Underline thickness.
    attr_accessor :underlinethickness

    # Height of caps.
    attr_accessor :capheight

    # Height of ascender.
    attr_accessor :ascender

    # Height of descender.
    attr_accessor :descender

   
    # Create an empty afm file. If _afm_ is set, use this to initialize
    # the object. _afm_ is either a string with the contents of an afm
    # file or a File object that points to the afm file. _options_
    # currently only accepts <tt>:verbose</tt> (true/false), that prints
    # out some diagnostic information on STDERR.
    def initialize(options={})
      @something_strange = false
      super()
      @outlinetype=:type1
      @comment = ""
      @verbose=options[:verbose]==true
    end

    # Read the afm file given with _filename_. _filename_ must be full
    # path to the afm file, it does not perform any lookups. Returns self.
    def read (filename)
      @filename=File.basename(filename)
      @name=@filename.chomp(".afm")
      self.pathname=Pathname.new(filename).realpath.to_s
      parse(File.read(filename))
    end

    # Return a string representation of the afm file that is compliant
    # with the afm spec.
    def to_s
      s ="StartFontMetrics 2.0\n"
      s << "Comment Generated using the RFI Library\n"
      %w( FontName FullName FamilyName Weight Notice ItalicAngle
        IsFixedPitch UnderlinePosition UnderlineTickness Version
        EncodingScheme CapHeight XHeight Descender Ascender ).each {|kw|

        meth=kw.downcase.to_sym
        value=self.send(meth) if self.respond_to?(meth)
        if value
          s << kw << " " << value.to_s << "\n"
        end
      }
      s << "FontBBox " << @fontbbox.join(" ") << "\n"
      s << "StartCharMetrics #@count_charmetrics\n"
      @chars.sort{ |a,b|
        # puts "a=#{a[1].c}, b=#{b[1].c}"
        if a[1].c == -1
          b[1].c == -1 ? 0 : 1
        else
          b[1].c == -1 ? -1 :  a[1].c <=> b[1].c
        end      
      }.each { |a,b|
        s << "C #{b.c} ; WX #{b.wx} ; N #{a} ; B #{b.b.join(" ")}\n"
      }
      s << "EndCharMetrics\nStartKernData\nStartKernPairs"
      count=0
      @chars.each_value { |c|
        count += c.kern_data.size
      }
      s << " #{count}\n"
      @chars.sort{ |a,b| a[0] <=> b[0] }.each { |name,char|
        char.kern_data.each { |destname, value|
          s << "KPX #{name} #{destname} #{value[0]}\n"
        }
      }
      s << "EndKernPairs\nEndKernData\nEndFontMetrics\n"
      s
    end
    
    # Parse the contents of the String _txt_. Returns self.
    def parse(txt)
      @chars ||= Hash.new
      @s=StringScanner.new(txt.gsub(/\r\n/,"\n"))
      @s.scan(/StartFontMetrics/)
      get_fontmetrics
      self
    end
    
    #######
    private
    #######

    def get_keyword
      @s.skip_until(/\s+/)
      @s.scan(/[A-Z][A-Za-z0-9]+/)
    end

    def get_integer
      @s.skip(/\s+/)
      @s.scan(/-?\d+/).to_i
    end

    def get_number
      @s.skip(/\s+/)
      @s.scan(/-?\d+(?:\.\d+)?/).to_f
    end

    def get_boolean
      @s.skip(/\s+/)
      @s.scan(/(true|false)/) == 'true'
    end

    def get_name
      @s.skip(/\s+/)
      @s.scan(/[^\s]+/)
    end

    def get_string
      @s.skip(/\s+/)
      @s.scan(/.*/)
    end

    def get_fontmetrics
      @version = get_number
      loop do
        kw=get_keyword
        STDERR.puts "KW: " + kw if @verbose
        case kw 
        when "FontName"
          @fontname=get_string
        when "FamilyName" 
          @familyname = get_string
        when "FullName" 
          @fullname = get_string
        when "EncodingScheme"
          @encodingscheme = get_string
        when "ItalicAngle"
          @italicangle = get_number
        when "IsFixedPitch"
          @isfixedpitch = get_boolean
        when "Weight" 
          @weight = get_string
        when "XHeight"
          @xheight= get_number
        when "Comment" 
          @comment << get_string << "\n"
        when "FontBBox"
          @fontbbox = [get_number,get_number, get_number, get_number]
        when "Version" 
          @version = get_string
        when "Notice" 
          @notice = get_string
        when "MappingScheme"
          @mappingscheme = get_integer
        when "EscChar"
          @escchar = get_integer
        when "CharacterSet"
          @characterset = get_string
        when "Characters"
          @characters = get_integer
        when "IsBaseFont"
          @isbasefont = get_boolean
        when "VVector"
          @vvector = [get_number,get_number]
        when "IsFixedV"
          @isfixedv = get_boolean
        when "CapHeight" 
          @capheight = get_number
        when "Ascender" 
          @ascender = get_number
        when "Descender" 
          @descender = get_number
        when "UnderlinePosition"
          @underlineposition = get_number
        when "UnderlineThickness"
          @underlinethickness = get_number
        when "StartDirection"
          get_direction
        when "StartCharMetrics"
          get_charmetrics
        when "StartKernData"
          get_kerndata
        when "StartComposites"
          get_composites
        when "EndFontMetrics" 
          break 
        end
      end
    end
    def get_direction
      # ignored
    end
    def get_charmetrics
      @count_charmetrics = get_integer
      @count_charmetrics_encoded = 0
      @count_charmetrics_unencoded = 0
      loop do
        @s.skip_until(/\n/)
        nextstring =  @s.scan_until(/(?:StopCharMetrics|.*)/)
        return if nextstring=="EndCharMetrics"
        a=nextstring.split(';')
        # ["C 32 ", " WX 250 ", " N space ", " B 125 0 125 0 "]
        a.collect! { |elt|
          elt.strip.split(/ /,2)
        }
        # [["C", "32"], ["WX", "250"], ["N", "space"], ["B", "125 0 125 0"]]
        char=new_glyph
        a.each { |elt|
          key,value = elt
          case key
          when "N"
            char.name=value
          when "B"
            #special treatment for bounding box
            char.b = value.split.collect { |e| e.to_i }
            char.llx = char.llx
            char.urx = char.urx
            # We need to avoid negative heights or depths. They break
            # accents in math mode, among other things.
            char.lly = 0 if char.lly > 0
            char.ury = 0 if char.ury < 0
          when "C"
            char.c = value.to_i
          when "CH"
            # hex: '<20>' -> '0x20' -> .to_i -> 32
            char.c = value.sub(/</,'0x').sub(/>/,'').to_i(16)
          when "WX"
            char.wx = value.to_i
            # for "L", check  /var/www/mirror/system/tex/texmf-local/fonts/afm/jmn/hans/hans.afm
          when "L", nil
            #ignore
          else
            char.send((key.downcase + "=").to_sym,value.to_i)
          end
        }

        @chars[char.name]=char
        # update information about encoded/unencoded
        if char.c > -1
          @count_charmetrics_encoded += 1
        else
          @count_charmetrics_unencoded += 1
        end
      end
      raise "never reached"
    end
    def get_kerndata
      loop do
        kw = get_keyword
        STDERR.puts "kw=" + kw if @verbose
        case kw
        when "EndKernData"
          return
        when "StartKernPairs"
          get_kernpairs
        when "StartTrackKern"
          # TrackKern
          get_trackkern
        else
          # KernPairs0
          # KernPairs1
          raise "not implemented"
        end
      end
      raise "never reached"
    end
    def get_composites
      count = get_integer
      loop do
        kw = get_keyword
        STDERR.puts "get_composites keyword = '" + kw + "'" if @verbose
        case kw
        when "CC"
          get_composite
        when "EndComposites"
          return
        else
          STDERR.puts "next to read = " +  @s.string[@s.pos,40]
          raise "AFM error"
        end
      end
      raise "never reached"
    end
    def get_composite
      glyphname = get_name
      count = get_integer
      @s.skip_until(/;\s+/)
      count.times do 
        nextstring = get_name
        raise "AFM Error" unless nextstring == "PCC"
        [get_number,get_number]
        @s.skip_until(/;/)
      end
    end

    def get_trackkern
      count = get_integer
      loop do
        case get_keyword
        when "EndTrackKern"
          return
        when "TrackKern"
          # TrackKern degree min-ptsize min-kern max-ptsize max-kern
          [get_integer,get_number,get_number,get_number,get_number]
        else
          raise "afm error"
        end
      end
      raise "never reached"
    end

    def get_kernpairs
      count = get_integer
      loop do
        case get_keyword
        when "KPX"     # y is 0
          name=get_name
          # if @info['chars'][name]
          if @chars[name]
            # array is [x,y] kerning
            destname,num=get_name,get_number
            # somethimes something stupid like
            # KPX .notdef y -26
            # KPX A .notdef -43
            # is in the afm data... :-( -> reject those entries
            # if @info['chars'][destname]
            if @chars[destname]
              @chars[name].kern_data[destname] = [num,0]
            else
              STDERR.puts "info: unused kern data for " + name if @verbose
            end
          else
            # ignore this entry, print a message
            STDERR.puts "info: unused kern data for " + name if @verbose
            @something_strange=true
            [get_name,get_number] # ignored
          end
        when "EndKernPairs"
          return
        else
          STDERR.puts @s.pos
          raise "not implmented"
        end
      end
      raise "never reached"
    end
  end
end
