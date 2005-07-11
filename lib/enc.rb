#--
# enc.rb - read and parse TeX's encoding files
# Last Change: Tue Jul 12 01:03:08 2005
#++
# See the class ENC for the api description.

require 'strscan'
require 'set'
require 'forwardable'
#require 'delegate'


# = ENC -- Access encoding files
#
# == General information
#
# Read a TeX encoding vector (<tt>.enc</tt>-file) and associated
# ligkern instructions. The encoding slot are accessible via #[]
# and #[]=, just like an Array.
#
# == Example usage (read an encoding file)
#  filename = "/opt/tetex/3.0/texmf/fonts/enc/dvips/base/EC.enc"
#  File.open(filename) { |encfile|
#     enc=ENC.new(encfile)
#     enc.encname   # => "ECEncoding"
#     enc           # => ['grave','acute',...]
#     enc.filename  # => "EC.enc"
#     enc.ligkern_instructions  # => ["space l =: lslash","space L =: Lslash",... ]
#  }
# == Create an encoding
#  enc=ENC.new
#  enc.encname="Exampleenc"
#  enc[0]="grave"
#  ....
#  enc.update_glyph_index
#
#  # write encoding to <tt>new.enc</tt>
#  File.open("new.enc") do |f|
#     f << enc.to_s
#  end
#--
# dont't subclass Array directly, it might be a bad idea. See for
# example [ruby-talk:147327]
#++

class ENC # < DelegateClass(Array)
  extend Forwardable

  def_delegators(:@encvector, :size, :[],:each, :each_with_index)
  # _encname_ is the PostScript name of the encoding vector.
  attr_accessor :encname

  # ligkern_instructions is an array of strings (instructions) as
  # found in the encoding file, such as:
  # "quoteright quoteright =: quotedblright"
  # "* {} space"
  attr_accessor :ligkern_instructions

  # hash: key is glyph name, value is array of indexes
  # example: glyph_index['hyphen']=[45,127] in ec.enc
  attr_accessor :glyph_index

  # Filename of the encoding vector. Used for creating mapfile
  # entries. Always ends with ".enc" if read (unless it is unset).
  attr_accessor :filename
  
  # Optional enc is either a File object or a string with the content
  # of a file. If set, the object is initialized with the given
  # encoding vector.
  def initialize (enc=nil)
    @glyph_index={}
    @ligkern_instructions=[]
    # File, Tempfile, IO respond to read
    if enc
      @encvector=[]
      string = enc.respond_to?(:read) ? enc.read : enc
      if enc.respond_to?(:path)
        self.filename= enc.path
      end
      parse(string)
    else
      @encvector=Array.new(256,".notdef")
    end
    # super(@encvector)
  end

  def filename=(fn) # :nodoc:
    @filename=File.basename(fn.chomp(".enc")+".enc")
  end
  # compare encname and array
  def ==(obj)
    #    return true
    return false if obj==nil
    if obj.instance_of?(ENC)
      return false unless @encname==obj.encname
    end
    
    0.upto(255) { |i|
      return false if @encvector[i]!=obj[i]
    }
    true
  end
  def []=(i,obj)
    if obj==nil and @encvector[i] != nil
      @glyph_index.delete(@encvector[i])
      return obj
    end
    
    @encvector[i]=obj
    addtoindex(obj,i)
    return obj
  end
  # Return a string representation of the encoding that is compatible
  # with dvips and alike
  def to_s
    str = ""
    @ligkern_instructions.each { |instr|
      str << "% LIGKERN #{instr} ;\n"
    }
    str << "%\n"
    str << "/#@encname [\n"
    @encvector.each_with_index { |glyphname,i|
      str << "% #{i}\n" if (i % 16 == 0)
      str << " " unless (i % 8 == 0)
      str << "/#{glyphname}"
      str << "\n" if (i % 8 == 7)
    }
    str << "] def\n"
    str
  end

  private

    # creates the glyph_index from the encvector. Use this method after
  # you made changes to the encvector.
  def update_glyph_index
    @encvector.each_with_index { |name,i|
      next if name==".notdef"
      addtoindex(name,i)
    }
  end

  def addtoindex(obj,i)
    return if obj==".notdef"
    if @glyph_index[obj]
      @glyph_index[obj].add i
    else
      @glyph_index[obj]=Set.new([i])
    end
  end

  def tok(s)
    unless s.peek(1) == "/"
      s.skip_until(/[^\/\[\]]+/) # not '/' '[' or ']'
    end
    s.scan(/(?:\/\.?\w+|\[|\])/)
  end
  def parse(str)
    count=0
    s=StringScanner.new(str)
    ligkern=""
    while s.skip_until(/^%\s+LIGKERN\s+/)
      ligkern  << s.scan_until(/$/)
    end
    ligkern.split(';').each  { |instruction|
      @ligkern_instructions.push instruction.strip
    }
    s.string=(str.gsub(/%.*/,''))
    t=tok(s)
    @encname=t[1,t.length-1]
    loop do
      t = tok(s)
      case t
      when "["
        # ignore
      when "]"
        unless @encvector.size == 256
          raise "Unexpected size of encoding. It should contain 256 entries, but has #{@encvector.size} entries."
        end
        update_glyph_index
        return
      else
        name = t[1,t.length-1]
        @encvector.push(name)
      end
    end
    # never reached
    raise "Internal ENC error"
  end
end
