#--
# enc.rb - read and parse TeX's encoding files
# Last Change: Wed Jul  6 20:06:10 2005
#++
# See the class ENC for the api description.
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
#  enc.encvector[0]="grave"
#  ....
#  enc.update_glyph_index

require 'strscan'

# Read a TeX encoding vector (<tt>.enc</tt>-file) and associated
# ligkern instructions. The encoding slot are accessible via []
#--
# Perhaps inheriting from Array is a bad idea? see: [ruby-talk:147327]
#  --pg
#++
class ENC < Array
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
      string = enc.respond_to?(:read) ? enc.read : enc
      if enc.respond_to?(:path)
        self.filename= enc.path
      end
      parse(string)
    else
      #Array.new(256,".notdef")
      # better solution:
      #0.upto(255) {|num|
      #  self[num]=".notdef"
      #}
      super(256,".notdef")
    end
  end

  # creates the glyph_index from the encvector. Use this method after
  # you made changes to the encvector.
  def update_glyph_index
    self.each_with_index { |name,i|
      next if name==".notdef"
      if @glyph_index[name]
        @glyph_index[name].push i
      else
        @glyph_index[name]=[i]
      end
    }
  end
  def filename=(fn) # :nodoc:
    @filename=File.basename(fn.chomp(".enc")+".enc")
  end
  private

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
        unless self.size == 256
          raise "Unexpected size of encoding. It should contain 256 entries, but has #{@encvector.size} entries."
        end
        update_glyph_index
        return
      else
        name = t[1,t.length-1]
        self.push(name)
      end
    end
    # never reached
    raise "Internal ENC error"
  end
  def hash
    @encname.hash
  end
end
