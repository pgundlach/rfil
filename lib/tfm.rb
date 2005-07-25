
# Hold information about a TeX font metric file. 
class TFM
  def self.documented_as_accessor(*args) #:nodoc:
  end
  def self.documented_as_reader(*args) #:nodoc:
  end

  # Print diagnostics
  attr_accessor :verbose

  # Filename sans path of the tfm file. To change this attribute, set
  # pathname. 
  documented_as_reader :filename

  # Path to the tfm file.
  attr_accessor :pathname

  # Checksum of the tfm file
  attr_accessor :checksum

  # The designsize (Float). Must be >= 1.0.
  attr_accessor :designsize

  # Coding scheme of the font. One of "TeX math symbols", "TeX math
  # extension" or anything else. The two have special meaning (more
  # parameters).
  attr_accessor :codingscheme

  # Font family is an arbitrary String. Default is "UNSPECIFIED"
  attr_accessor :fontfamily
  
  # Just a flag. (More doc here)
  attr_accessor :sevenbitsafeflag

  # Some strange code
  attr_accessor :face

  # array of chars (to be documented)
  attr_accessor :chars

  # the font parameters (as we know: slant, stretch...)
  attr_accessor :params
  
  # array of ligkern instructions (another array of arrays)
  attr_accessor :lig_kern
  
  def initialize
    @chars=[]
    @lig_kern=[]
    @params={}
    @fontfamily="UNSPECIFIED"
  end
  def filename=(obj)
    raise
  end
  def filename
    File.basename(@pathname)
  end
  
  def read_file(file)
    p=TFMParser.new(self)
    if file.respond_to? :read
      if file.respond_to? :path
        @pathname=file.path
      end
      p.parse(file.read)
    else
      # we assume it is a string
      @pathname=file
      case file
      when /\.tfm$/
        File.open(file) { |f|
          p.parse(f.read)
        }
      else
        raise ArgumentError, "unknown Filetype: #{file}"
      end
    end
    return self
  end # read_file
end # class TFM




class TFMParser
  # reading a tfm file is about 10 times faster than doing
  # `tftop xyz.pl` and using PL#parse. And only a bit slower than
  # `tftop xyz.pl > /dev/null` alone. (1.3 secs. vs. 0.9 secs. - 10 times)
  LIGOPS = %w( LIG LIG/  /LIG  /LIG/
               x   LIG/> /LIG> /LIG/>
               x   x     x     /LIG/>> ) 
  LIGTAG=1
  STOPFLAG=128
  KERNFLAG=128
  LIGSIZE=5000
  class TFMError < Exception
  end

  def initialize(tfmobject=nil)
    # type of font: textfont (:vanilla), math symbols (:mathsy), math
    # extension (:mathex)
    @font_type=nil
    
    @perfect=true

    # this is where we store all our data
    @tfm=if tfmobject
           tfmobject
         else
           TFM.new
         end
  end # initialize
  
  # _tfmdata_ is a string with the contents of the tfm (binary) file.
  def parse(tfmdata)
    @tfmdata=tfmdata.unpack("C*")
    @index=0

    @lf=get_dbyte
    @lh=get_dbyte
    @bc=get_dbyte
    @ec=get_dbyte
    @nw=get_dbyte
    @nh=get_dbyte
    @nd=get_dbyte
    @ni=get_dbyte
    @nl=get_dbyte
    @nk=get_dbyte
    @ne=get_dbyte
    @np=get_dbyte

    raise TFMError, "The following condition is not true: bc-1 <= ec and ec <= 255" unless @bc-1 <= @ec and @ec <= 255
    raise TFMError, "The following condition is not true: ne <= 256" unless @ne <= 256
    raise TFMError, "The following condition is not true: lf == 6+lh+(ec-bc+1)+nw+nh+nd+ni+nl+nk+ne+np" unless @lf == 6+@lh+(@ec-@bc+1)+@nw+@nh+@nd+@ni+@nl+@nk+@ne+@np

    # § 23
    @header_base = 6
    @char_base = @header_base + @lh 
    @width_base = @char_base + (@ec - @bc) + 1
    @height_base = @width_base + @nw
    @depth_base = @height_base + @nh
    @italic_base = @depth_base + @nd
    @lig_kern_base = @italic_base + @ni
    @kern_base = @lig_kern_base + @nl
    @exten_base = @kern_base + @nk
    @param_base = @exten_base + @ne

    parse_header
    parse_params
    parse_char_info
    parse_lig_kern
    # exten?

#    ligtable
    return @tfm
  end # parse

  #######
  private
  #######
  
  def parse_header
    @index = @header_base * 4
    @tfm.checksum=get_qbyte
    @tfm.designsize=get_fix_word
    if @lh >= 3
      count = get_byte
      @tfm.codingscheme=get_chars(count)
      @font_type= case @tfm.codingscheme
                  when "TeX math symbols"
                    :mathsy
                  when "TeX math extension"
                    :mathex
                  else
                    :vanilla
                  end
    end
    @index = (@header_base + 12) * 4
    if @lh > 12
      # not documented! Bug in TFtoPL. See PLtoTF §70.
      count = get_byte
      @tfm.fontfamily=get_chars(count)
    end
    @index = (@header_base + 17 ) * 4
    if @lh >= 17
      @tfm.sevenbitsafeflag=get_byte
      # two bytes ignored
      get_byte ; get_byte
      @tfm.face=get_byte
    end
    # let us ignore the rest of the header (TeX ignores it, so we may
    # do the same)
  end # parse_header

  def parse_params
    @index=@param_base * 4
    @tfm.params[:slant]=get_fix_word
    @tfm.params[:space]=get_fix_word
    @tfm.params[:stretch]=get_fix_word
    @tfm.params[:shrink]=get_fix_word
    @tfm.params[:xheight]=get_fix_word
    @tfm.params[:quad]=get_fix_word
    @tfm.params[:extraspace]=get_fix_word
    if @font_type != :vanilla
      raise ScriptError, "I need to get more parameters, but nobody told me how to do this :-("
    end
  end # parse_params
  
  # §78 TFtoPL
  def parse_char_info
    @index=@char_base *4
    (@bc..@ec).each { |n|
      # p "looking at char #{n}, index is at #{@index / 4}"
      tmp=if @tfm.chars[n]
            @tfm.chars[n]
          else
            Hash.new
          end
      @tfm.chars[n]=tmp
      tmp[:charwd]=get_fix_word((@width_base + get_byte)*4)
      b=get_byte
      tmp[:charht]=get_fix_word((@height_base + (b >> 4))*4)
      tmp[:chardp]=get_fix_word((@depth_base + (b % 16))*4)
      tmp[:charic]=get_fix_word((@italic_base + (get_byte >> 2))*4)
      # we ignore the remainder and look it up on demand
      get_byte
    }
  end

  # now for the ugly part in the tfm, §63 pp
  # Hey, we do a more clever implementation: we do not check for any
  # errors. So coding is only a few lines instead of a few sections.
  # this one took me so much time (the original, not this
  # implementation), I am really frustrated.
  def parse_lig_kern
    # array that stores 'instruction that starts at x can be found in
    # @tfm.lig_kern at position y'
    start_instr=[]

    @bc.upto(@ec) { |c|
      if char_tag(c) == LIGTAG
        start=get_lig_starting_point(c)
        if start_instr[start] != nil
          # we have already stored this ligkern
          @tfm.chars[c][:lig_kern]=start_instr[start]
          next
        end
        tmp=[]
        
        start_instr[start]=@tfm.lig_kern.size
        @tfm.lig_kern.push tmp
        @tfm.chars[c][:lig_kern]=start_instr[start]
        
        begin
          s=get_byte(lig_step(start))
          puts "warning: skip > 128 (#{s}) I don't know what to do." if s  > 128
          n,op,rem=get_byte(lig_step(start)+1),get_byte(lig_step(start)+2),get_byte(lig_step(start)+3)

          if op >= 128
            # kern!
            kernamount=get_fix_word((@kern_base + (256 * (op-128) +rem)) *4)
            tmp.push [:kern, n, kernamount]
          else
            tmp.push [:lig, op, n, rem ]
          end
          tmp.push [:skip, s] if s > 0 and s < 128
          start += 1
        end until s >= 128
      end
    }
  end

  
  # --------------------------------------------------
  def char_tag(c)
    @tfmdata[((@char_base + c - @bc ) *4 + 2)] % 2
  end
  def char_remainder(c)
    @tfmdata[((@char_base + c - @bc ) *4 + 3)]
  end
  def get_lig_starting_point(char)
    # warning: had some wine
    return nil unless char_tag(char) == LIGTAG
    r = char_remainder(char)
    s=get_byte(lig_step(r))
    if s > 128
      # it does not start here, it starts somewhere else
      n,op,rem=get_byte(lig_step(r)+1),get_byte(lig_step(r)+2),get_byte(lig_step(r)+3)
      
      256*op+rem
    else
      r
    end
  end
      
  def get_byte(i=nil)
    global = i == nil
    i = @index if global
    r=@tfmdata[i]
    @index += 1  if global
    r
  end
  # 16 bit integer
  def get_dbyte
    r = (@tfmdata[@index] << 8) + @tfmdata[@index + 1]
    @index += 2
    r
  end
  # 32 bit integer
  def get_qbyte
    r = (@tfmdata[@index] << 24) + (@tfmdata[@index+1] << 16) + (@tfmdata[@index+2] << 8) + @tfmdata[@index+3]
    @index += 4
    r
  end
  def get_chars(count)
    ret=""
    count.times { |count|
      c=@tfmdata[@index + count]
      ret << c.chr if c > 0
    }
    @index += count
    ret
  end
  def get_fix_word(i=nil)
    global = i==nil
    i = @index if global
    # p i
    b=@tfmdata[(i..i+3)]
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
  def lig_step(num)
    (@lig_kern_base + num )*4
  end
  def ligtable
    # will be removed, just an example
    puts "ligtable"
    lk_char=[]
    # first appearance of a char is the index, all chars for the same
    # instructions is the value
    # e.g. firstchar_chars[8]=[8,9] if chars 8 and 9 point to the same instr.
    firstchar_chars=[]
    
    @tfm.chars.each_with_index {|c,i|
      next unless c
      next unless instr=c[:lig_kern]
      # we need to find duplicates
      # some chars point to the same instruction
      if lk_char[instr]
        lk_char[instr].push i
      else
        lk_char[instr] = [i]
      end
    }
    lk_char.each{ |a|
      firstchar_chars[a[0]]=a
    }
    firstchar_chars.each { |a|
      next unless a
      a.each { |l|
        puts "(label #{l})"
      }
      @tfm.lig_kern[@tfm.chars[a[0]][:lig_kern]].each {|la|
        case la[0]
        when :skip
          puts "(#{la[0]} #{la[1]})"
        when :kern
          puts "(#{la[0]} #{la[1]} #{la[2]})"
        when :lig
          puts "(#{LIGOPS[la[1]]} #{la[2]} #{sprintf("%o",la[3])})"
        end
      }
      puts "(stop)"
    }
  end
end
