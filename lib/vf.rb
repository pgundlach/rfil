# vf.rb -- Class that models TeX's virtual fonts.
#--
# Last Change: Mon Jul 25 20:27:30 2005
#++

require 'tfm'
require 'kpathsea'


class VF < TFM
  def self.documented_as_accessor(*args) #:nodoc:
  end
  def self.documented_as_reader(*args) #:nodoc:
  end

  # fontlist is an array of Hashes with the following keys:
  # [<tt>:scale</tt>] Relative size of the font
  # [<tt>:designsize</tt>] Arbitrary 
  # [<tt>:name</tt>]    Filename of the font. Without path.
  # [<tt>:area</tt>]    'Path' of the font. Often nil.
  # [<tt>:checksum</tt>] Checksum of that font.
  attr_accessor :fontlist

  # This is the same Array as in TFM. Besides the keys <tt>:charwd</tt>,
  # <tt>:charht</tt>, <tt>:chardp</tt> and <tt>:charic</tt>, we now have a key
  # <tt>:dvi</tt> that holds all vf instructions.
  documented_as_accessor :chars

  # Comment at the beginning of the vf file. Must be < 256 chars.
  attr_accessor :comment
  def initialize
    super
    @comment=nil
    @fontlist=[]
  end
  
  def read_file(file)
    p=VFParser.new(self)
    if file.respond_to? :read
      if file.respond_to? :path
        @pathname=file.path
      end
      p.parse(file.read)
    else
      # we assume it is a string
      @pathname=file
      case file
      when /\.vf$/
        File.open(file) { |f|
          p.parse(f.read)
        }
      else
        raise ArgumentError, "unknown Filetype: #{file}"
      end
    end
    t=TFMParser.new(self)
    tfmpathname=@pathname.chomp(".vf")+".tfm"
    File.open(tfmpathname){ |f|
      t.parse(f.read)
    }
    return self
  end #read_file
end #class VF



# This class is not meant to be used by the programmer. It is used in
# the VF class to read a virtual font from a file.

class VFParser
  # Raise this exception if an error related to the virtual font is
  # encountered. Don't expect this library to be too clever at the beginning.
  class VFError < Exception
  end

  def initialize(vfobj)
    @vfobj= vfobj || VF.new
    @stack=[[0,0,0,0]]
    push
    @index=0
    @dviindex=nil
  end

  # _vfdata_ is a string with the contents of the vf (binary) file.
  # Return a VF object filled with the information of the virtual
  # font. Does not read the tfm data. It is safe to parse tfm data
  # after parsing the virtual font. 
  def parse(vfdata)
    raise ArgumentError, "I expect a string" unless vfdata.respond_to?(:unpack)
    @index=0
    @data=vfdata.unpack("C*")

    raise VFError, "This does not look like a vf to me" if 247 != get_byte
    raise VFError, "Unknown VF version" unless  202 == get_byte

    @vfobj.comment=get_chars(get_byte)

    tfmcksum = get_qbyte
    tfmdsize = get_fix_word

    while b=get_byte
      case b
      when 0..241
        @index -= 1
        parse_char(:short)
      when 242
        parse_char(:long)
      when 243,244,245,246
        # jippie, a (map)font
        fontnumber=get_bytes(243-b+1,false)
        tmp=@vfobj.fontlist[fontnumber]={}
        tmp[:checksum]=get_qbyte
        tmp[:scale]=get_fix_word
        tmp[:designsize] = get_fix_word
        a = get_byte   # length of area (directory?)
        l = get_byte   # length of fontname
        tmp[:area]=get_chars(a)
        tmp[:name]=get_chars(l)
      when 248
        parse_postamble
      else
        raise VFError, "unknown instruction number #{b.inspect}"
      end
    end
    return @vfobj
  end # parse
  
  
  #######
  private
  #######
  
  def parse_postamble
    while get_byte
    end
  end
  # type: :long, :short
  def parse_char(type)
    instructions=[]
    case type
    when :long
      pl=get_qbyte
      cc=get_qbyte
      tfm=out_as_fix(get_bytes(4,true,@index))
      @index+=4
    when :short
      pl=get_byte
      cc=get_byte
      tfm=out_as_fix(get_bytes(3,true,@index))
      @index+=3
    else 
      raise ArgumentError,"unknown type: #{type}"
    end
    dvi=@data[(@index..@index+pl-1)]
    @dviindex=@index
    @index += pl
    while i = get_byte(@dviindex) and @dviindex < @index
      case i
      when 0
        # setchar 0
        raise "not implementd"
      when 1..127
        instructions << [:setchar, i]
        @dviindex += 1
      when 128..131
        c=4-(131-i)
        instructions << [:setchar, get_bytes(c,false,@dviindex+1)]
        @dviindex += c+1
      when 132,137
        x=out_as_fix(get_bytes(4,true,@dviindex+1))
        y=out_as_fix(get_bytes(4,true,@dviindex+5))
        instructions << [:setrule,x,y]
        @dviindex += 9
      when 133..136
        c=4-(136-i)
        instructions << [:setchar, get_bytes(c,false,@dviindex+1)]
        @dviindex += c+1
      when 138
        # nop
        @dviindex +=1
      when 139,140
        raise VFError, "illegal instruction in VF: #{i}"
      when 141
        instructions << [:push]
        push
        @dviindex +=1
      when 142 
        instructions << [:pop]
        pop
        @dviindex +=1
      when 143..146
        c=4-(146-i)
        b=out_as_fix(get_bytes(c,true,@dviindex+1))
        instructions << [:moveright, b]
      when 147
        instructions << [:moveright, _w]
        @dviindex +=1
      when 148..151
        c=4-(151-i)
        self._w=out_as_fix(get_bytes(c,true,@dviindex+1))
        instructions << [:moveright,_w]
        @dviindex += c+1
      when 152
        instructions << [:moveright, _x]
        @dviindex +=1
      when 153..156
        c=4-(156-i)
        x=out_as_fix(get_bytes(c,true,@dviindex+1))
        self._x=x
        instructions << [:moveright,x]
        @dviindex += c+1
      when 157..160
        # are these really used?
        c=4-(160-i)
        v=out_as_fix(get_bytes(c,true,@dviindex+1))
        instructions << [:movedown,v]
        @dviindex += c+1
      when 161
        instructions << [:movedown, _y]
        @dviindex +=1
      when 162..165
        c=i-162+1
        self._y = out_as_fix(get_bytes(c,true,@dviindex+1))
        instructions << [:movedown,_y]
        @dviindex += c+1
      when 166
        instructions << [:movedown, _z]
        @dviindex +=1
      when 167..170
        c=i-167+1
        self._z = out_as_fix(get_bytes(c,true,@dviindex+1))
        instructions << [:movedown,_z]
        @dviindex += c+1
      when 171..234
        instructions << [:selectfont, 63-234+i]
        @dviindex += 1
      when 235..238
        c=i-235+1
        instructions << [:selectfont, get_bytes(c,true,@dviindex+1)]
        @dviindex += c+1
      when 239..242
        c=i-239+1
        k=get_bytes(c,true,@dviindex+1)
        if k < 0
          raise VFError, "length of special is negative"
        end
        instructions << [:special, get_chars(k,@dviindex+2)]
        @dviindex += 2+k
      when 243..255
        raise VFError, "illegal instruction in VF: #{i}"
      else
        raise "not implemented: #{i}"
      end
    end
    # puts "charcode=#{cc} (octal #{sprintf("%o",cc)})"
    tmp=if @vfobj.chars[cc]
          @vfobj.chars[cc]
        else
          Hash.new
        end
    @vfobj.chars[cc]=tmp
    tmp[:dvi]=instructions
    # puts "pl=#{pl}"
    # puts "tfm=#{tfm}"
    # puts "dvi=#{dvi.inspect}"
  end
  def push
    top=@stack[-1]
    @stack.push top.dup
  end
  def pop
    if @stack.size < 2
      raise VFError, "more pop then push on stack"
    end
    return @stack.pop
  end
  def _w=(value)
    @stack[-1][0]=value
  end
  def _w
    @stack[-1][0]
  end
  def _x=(value)
    @stack[-1][1]=value
  end
  def _x
    @stack[-1][1]
  end

  def _y=(value)
    @stack[-1][2]=value
  end
  def _y
    @stack[-1][2]
  end

  def _z=(value)
    @stack[-1][3]=value
  end
  def _z
    @stack[-1][3]
  end
  
  
#   def set_stackvalue(obj,value)
#     i=case obj
#       when :w then 0
#       when :x then 1
#       when :y then 2
#       when :z then 3
#       end
#     @stack[-1][i]=value
#   end
  def get_byte(i=nil)
    global = i==nil
    i = @index if global
    r=@data[i]
    @index += 1  if global
    r
  end
  # 16 bit integer
  def get_dbyte(i=nil)
    global = i == nil
    i = @index if global
    r = (@data[i] << 8) + @data[i + 1]
    @index += 2 if global
    r
  end
  # 24 bit int
  def get_tbyte(i=nil)
    global = i == nil
    i = @index if global
    r = (@data[i] << 16) + (@data[i] << 8) + @data[i + 1]
    @index += 3 if global
    r
  end
  # signed 24 bit int
  def get_stbyte(i=nil)
    global = i == nil
    i = @index if global
    r = if @data[i] < 128
          (@data[i] << 16) + (@data[i] << 8) + @data[i + 1]
        else
          ((256 - @data[i]) << 16) + (@data[i] << 8) + @data[i + 1]
        end
    @index += 3 if global
    r
  end

  # 32 bit integer
  def get_qbyte
    r = (@data[@index] << 24) + (@data[@index+1] << 16) + (@data[@index+2] << 8) + @data[@index+3]
    @index += 4
    r
  end
  # Read a string with at most count bytes. Does not add \0 to the string.
  def get_chars(count,i=nil)
    ret=""
    global = i==nil
    i = @index if global
   
    count.times { |coumt|
      c=@data[i + coumt]
      ret << c.chr if c > 0
    }
    @index += count if global
    return ret.size==0  ? nil : ret 
  end
  def get_bytes(count,signed,i=nil)
    global = i==nil 
    i=@index if global
    a=@data[i]
    if (count==4) or signed
      if a >= 128
        a -= 256
      end
    end
    i +=1
    while count > 1
      a = a * 256 + @data[i]
      i +=1
      count -=1
    end
    @index += count if global
    return a
  end
  def out_as_fix(x)
    raise VFError if x.abs >= 0100000000
    # let's misuse @data -> change
    if x>=0 then @data[0]=0
    else
      @data[0]=255
      x += 0100000000
    end
    3.downto(1) { |k|
      @data[k]=x % 256
      x = x.div(256)
    }
    get_fix_word(0)      
  end
  def get_fix_word(i=nil)
    global = i==nil
    i = @index if global
    b=@data[(i..i+3)]
    @index += 4 if global
    a= (b[0] * 16) + (b[1].div 16)
    f= ((b[1] % 16) * 0400 + b[2] ) * 0400 + b[3]

    str = ""
    if a > 03777
      str << "-"
      a = 010000 - a
      if f > 0
        f = 04000000 - f
        a -= 1
      end
    end
    # Knuth, TFtoPL §42

    delta = 10
    f=10*f+5
    
    str << a.to_s + "."
    begin 
      if delta > 04000000
        f = f + 02000000 - ( delta / 2 )
      end
      str << (f / 04000000).to_s
      f = 10 * ( f % 04000000)
      delta *= 10
    end until f <= delta 
    str.to_f
  end

end
