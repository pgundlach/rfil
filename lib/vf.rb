# vf.rb -- Class that models TeX's virtual fonts.
#--
# Last Change: Mon Jul 25 18:20:39 2005
#++

require 'tfm'
require 'kpathsea'


class VF < TFM
  # fontlist is an array of Hashes with the following keys:
  # [<tt>:scale</tt>] Relative size of the font
  # [<tt>:designsize</tt>] Arbitrary 
  # [<tt>:name</tt>]    Filename of the font. Without path.
  # [<tt>:checksum</tt>] Checksum of that font.
  attr_accessor :fontlist
  def initialize
    super
    @fontlist=[]
  end
  def self.documented_as_accessor(*args) #:nodoc:
  end
  def self.documented_as_reader(*args) #:nodoc:
  end
  def filename=(obj)
    raise
  end
  def filename
    File.basename(@pathname)
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
    #puts "looking for tfm #{tfmpathname}"
    File.open(tfmpathname){ |f|
      t.parse(f.read)
    }
    return self
  end #read_file
end #class VF



class VFParser
  class VFError < Exception
  end

  def initialize(vfobj)
    @vfobj=vfobj
    @stack=[[0,0,0,0]]
    push
    @index=0
    @dviindex=nil
  end
  def parse(vfstring)
    raise ArgumentError, "I expect a string" unless vfstring.respond_to?(:unpack)
    @index=0
    @data=vfstring.unpack("C*")

    raise VFError, "This does not look like a vf to me" if 247 != get_byte
    raise VFError, "Unknown VF version" unless  202 == get_byte

    get_byte.times do
      # ignore comment
      get_byte
    end

    tfmcksum = get_qbyte
    tfmdsize = get_fix_word

    # assume for now we only have 1 font, this holds true for the ltd test case
    while b=get_byte
      case b
      when 0..241
        @index -= 1
        parse_char(:short)
      when 242
        parse_char(:long)
      when 243,244,245,246
        parse_font(4-(246 - b))  # length of k
      when 248
        parse_postamble
      else
        raise VFError, "unknown instruction number #{b.inspect}"
      end
    end
  end

  def parse_font(sizeof_k)
    k = case sizeof_k
        when 1
          get_byte
        when 2
          get_dbyte
        when 3
          get_tbyte
        when 4
          get_qbyte
        end
    # checksum
    c = get_qbyte
    # see dvitype §18
    # scale factor
    s = get_fix_word
    # design size
    d = get_fix_word
    # a=area/directory. if 0, use std
    a = get_byte
    # l=length of fontname
    l = get_byte
    n = @data[(@index..@index+a+l-1)].collect{ |b|
      b.chr
    }.join
    @index += a+l
    #puts "k=#{k} (fontnumber)"
    tmp={}
    @vfobj.fontlist[k]=tmp
    tmp[:checksum]=c
    tmp[:scale]=s
    tmp[:designsize]=d
    tmp[:name]=n
    #puts "checksum=#{c}"
    #puts "scale factor=#{s}"
    #puts "design_size=#{d}"
    #  puts "name=#{n}"
  end
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
        instructions << [:moveright, self._w]
        @dviindex +=1
      when 148..151
        c=4-(151-i)
        w=out_as_fix(get_bytes(c,true,@dviindex+1))
        self._w=w
        instructions << [:moveright,w]
        @dviindex += c+1
      when 152
        instructions << [:moveright, self._x]
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
        instructions << [:movedown, self._y]
        @dviindex +=1
      when 162..165
        c=4-(165-i)
        y = out_as_fix(get_bytes(c,true,@dviindex+1))
        self._y=y
        instructions << [:movedown,y]
        @dviindex += c+1
      when 166
        instructions << [:movedown, self._z]
        @dviindex +=1
      when 167..170
        c=i-167+1
        z = out_as_fix(get_bytes(c,true,@dviindex+1))
        self._z=z
        instructions << [:movedown,z]
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
  
  
  def set_stackvalue(obj,value)
    i=case obj
      when :w then 0
      when :x then 1
      when :y then 2
      when :z then 3
      end
    @stack[-1][i]=value
  end
  def get_byte(i=nil)
    global = i == nil
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
  def get_chars(count,i=nil)
    ret=""
    global = i==nil
    i = @index if global
    
    count.times { |count|
      c=@data[i + count]
      ret << c.chr if c > 0
    }
    @index += count if global
    ret
  end
  def get_bytes(count,signed,index=nil)
    raise "index == nil (sorry, not implemented)" unless index
    a=@data[index]
    if (count==4) or signed
      if a >= 128
        a -= 256
      end
    end
    index +=1
    while count > 1
      a = a * 256 + @data[index]
      index +=1
      count -=1
    end
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
