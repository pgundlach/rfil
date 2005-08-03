
# Hold information about a TeX font metric file. 
class TFM
  NOTAG=0
  LIGTAG=1
  LISTTAG=2
  EXTTAG=3

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
  attr_accessor :slant
  attr_accessor :space
  attr_accessor :stretch
  attr_accessor :shrink
  attr_accessor :xheight
  attr_accessor :quad
  attr_accessor :extraspace
  
  # array of ligkern instructions (another array of arrays)
  attr_accessor :lig_kern
  
  def initialize
    @chars=[]
    @lig_kern=[]
    @params={}
    @fontfamily="UNSPECIFIED"
  end
  def filename # :nodoc:
    File.basename(@pathname)
  end

  # _file_ is either a File object (or something similar, it must
  # respond to :read) or a string containing the full pathname to the
  # tfm file. Returns the TFM object.
  def read_file(file)
    p=TFMParser.new(self)
    p.verbose=@verbose
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

  # If _overwrite_ is true, we will replace existing files without
  # raising Errno::EEXIST.
  def save(overwrite=false)
    raise Errno::EEXIST if File.exists?(@pathname) and not overwrite
    puts "saving #{@pathname}..." if @verbose
    File.open(@pathname,"w") { |f|
      write_file(f)
    }
    puts "saving #{@pathname}...done" if @verbose
  end
  
  # _file_ is a File object (or something similar, it must
  # respond to <<). 
  # it returns
  def write_file(file)
    tfmwriter=TFMWriter.new(self)
    tfmwriter.verbose=@verbose
    file << tfmwriter.to_data
  end
end # class TFM



class TFMWriter
  # More output to stdout
  attr_accessor :verbose
  
  WIDTH=1
  HEIGHT=2
  DEPTH=3
  ITALIC=4

  def initialize(tfmobject)
    @tfm=tfmobject
    @chars=[]
    @lig_kern=nil
    # for the sorting
    @memsize=1028 + 4
    # @memory=Array.new(@memsize)
    @memory=[]
    @whdi_index=[]
    @mem_ptr=nil
    @link=Array.new(@memsize)
    @index=[]
    @memory[0]=017777777777
    @memory[WIDTH]=0
    @memory[HEIGHT]=0
    @memory[DEPTH]=0
    @memory[ITALIC]=0
    @link[WIDTH]=0
    @link[HEIGHT]=0
    @link[DEPTH]=0
    @link[ITALIC]=0
    @mem_ptr = ITALIC
    @next_d=nil

    
    @bchar_label=077777

    @data=[]
    @lf = 0
    @lh = 0 # ok
    @bc = 0 # ok
    @ec = 0 # ok
    @nw = 0 # ok
    @nh = 0 # ok
    @nd = 0 # ok
    @ni = 0 # ok
    @nl = 0 # ok
    @nk = 0 # ok
    @ne = 0 # ingore
    @np = 0 # ok
  end
  def to_data
    update_bc_ec
    calculate_header
    # width,heigt,dp,ic index
    update_whdi_index
    # @widths, @heights, @depths, @italics finished
    update_lig_kern
    # @kerns finished
    update_parameters
    # @parameters finished
    @lf =  6 + @lh + (@ec - @bc + 1) + @nw + @nh + @nd + @ni + @nl + @nk + @ne + @np
    @data += out_dbyte(@lf)
    @data += out_dbyte(@lh)
    @data += out_dbyte(@bc)
    @data += out_dbyte(@ec)
    @data += out_dbyte(@nw)
    @data += out_dbyte(@nh)
    @data += out_dbyte(@nd)
    @data += out_dbyte(@ni)
    @data += out_dbyte(@nl)
    @data += out_dbyte(@nk)
    @data += out_dbyte(@ne)
    @data += out_dbyte(@np)
    @data += @header
    calculate_chars
    @data += @chars
    @data += @widths
    @data += @heights
    @data += @depths
    @data += @italics
    @data += @lig_kern
    @data += @kerns
    @data += @parameters
    
    @data.pack("C*")
  end

  def calculate_chars
    (@bc..@ec).each { |n|
      if  @tfm.chars[n]
        wd_idx=@index[@widths_orig[n]]
        ht_idx=@index[@heights_orig[n]]  ? @index[@heights_orig[n]]  << 4 : 0
        dp_idx=@index[@depths_orig[n]]   ? @index[@depths_orig[n]] : 0
        ic_idx= @index[@italics_orig[n]] ? (@index[@italics_orig[n]] << 2) : 0
        tag = @tfm.chars[n][:lig_kern] ? 1 : 0
        remainder= @tfm.chars[n][:lig_kern] ? @instr_index[@tfm.chars[n][:lig_kern]] : 0
        @chars += [wd_idx,ht_idx + dp_idx, ic_idx + tag, remainder]
      else
        @chars += [0,0,0,0]
      end
    }
  end
  def update_parameters
    @parameters=[]
    @parameters += out_fix_word(@tfm.slant)
    @parameters += out_fix_word(@tfm.space)
    @parameters += out_fix_word(@tfm.stretch)
    @parameters += out_fix_word(@tfm.shrink)
    @parameters += out_fix_word(@tfm.xheight)
    @parameters += out_fix_word(@tfm.quad)
    @parameters += out_fix_word(@tfm.extraspace)
    
    @np=@parameters.size / 4
  end
  def update_whdi_index
    @widths_orig=[]
    @heights_orig=[]
    @depths_orig=[]
    @italics_orig=[]
    
    (@bc..@ec).each { |c|
      if @tfm.chars[c]
        @widths_orig[c]= sort_in(WIDTH,@tfm.chars[c][:charwd])
        @heights_orig[c] = sort_in(HEIGHT,@tfm.chars[c][:charht])
        @depths_orig[c] = sort_in(DEPTH,@tfm.chars[c][:chardp])
        @italics_orig[c] = sort_in(ITALIC,@tfm.chars[c][:charic])
      else
        @widths_orig[c] = 0
        @depths_orig[c] =  0
        @heights_orig[c] = 0
        @italics_orig[c] = 0
      end
      
    }
    delta=shorten(WIDTH,200)
    set_indices(WIDTH,delta)
    delta=shorten(HEIGHT,15)
    set_indices(HEIGHT,delta)
    delta=shorten(DEPTH,15)
    set_indices(DEPTH,delta)
    delta=shorten(ITALIC,63)
    set_indices(ITALIC,delta)


    @widths =  fill_index(WIDTH)
    @heights = fill_index(HEIGHT)
    @depths =  fill_index(DEPTH)
    @italics = fill_index(ITALIC)
    @nw= @widths.size/4
    @nh= @heights.size/4
    @nd= @depths.size/4
    @ni= @italics.size/4
  end
  
  def update_lig_kern
    kerns=[]
    instructions=[]
    (@bc..@ec).each { |n|
      next unless @tfm.chars[n]
      next unless @tfm.chars[n][:lig_kern]
      # we can skip aliases
      next if instructions[@tfm.chars[n][:lig_kern]]
      newinstr=[]
      @tfm.lig_kern[@tfm.chars[n][:lig_kern]].each { |instr,*rest|
        skip=nextchar=op=remainder=0
        case instr
        when :kern
          i=nil
          unless i = kerns.index(rest[1])
            kerns << rest[1]
            i=kerns.size - 1
          end
          skip=0
          nextchar=rest[0]
          remainder=i % 256
          op = remainder / 256 + 128
          when :lig
          skip=0
          op,nextchar,remainder=rest
        when :skip
          # todo: test for incorrect situations
          newinstr[-4] = rest[0]
          next
        else
          raise "don't know instruction #{instr}"
        end
        newinstr += [skip,nextchar,op,remainder]
      }
      newinstr[-4] = 128
      instructions[@tfm.chars[n][:lig_kern]] = newinstr
    }

    # we have all instructions collected in an array. The problem now
    # is to fill the @lig_kern array so that all start of instruction
    # programs are within the first 256 words of @lig_kern. So we keep
    # filling the @lig_kern array until there would not be enough room
    # left for the indirect nodes for the remaining count of
    # instructions. Say, we have 50 instructions left to go and there
    # are 60 words free in the first 256 words of @lig_kern, but the
    # current instruction would take more then 10 words, we need to
    # stop and fill the @lig_kern array with the indirect nodes and
    # then continue with the instructions. The following
    # implementation seems to work, but I refuse to prove it and it is
    # definitely not the most beautiful piece of code I have written.
    
    @instr_index=[]
    @lig_kern=[]

    total_instr=instructions.size
    instr_left=total_instr
    thisinstr=instructions.shift

    while (256  - @lig_kern.size / 4) - instr_left - thisinstr.size / 4 > 0
      @instr_index[total_instr-instr_left]=@lig_kern.size / 4
      @lig_kern += thisinstr
      thisinstr=instructions.shift
      instr_left -= 1
    end

    # undo last changes, since these don't fit into the @lig_kern
    # array (first 256 elements) (yes, this is ugly)
    instructions.unshift thisinstr

    
    
    pos=@lig_kern.size / 4 + instr_left
    count=@instr_index.size

    # now fill the indirect nodes, calculate the starting points of
    # the instructions
    instructions.each { |i|
      @instr_index[count]=@lig_kern.size / 4
      count += 1
      @lig_kern += [ 129, 0, (pos / 256) , (pos % 256) ]
      pos += i.size / 4
    }

    # now we continue with the instructions
    instructions.each { |i|
      @lig_kern += i
    }
    @nl = @lig_kern.size / 4

    @kerns=[]
    kerns.each { |k|
      @kerns += out_fix_word(k)
    }
    @nk=@kerns.size / 4
  end

  
  def fill_index(start)
    i=start
    what=[0,0,0,0]
    while (i=@link[i]) > 0
      what += out_fix_word(@memory[i])
    end
    return what
  end

  def calculate_header
    @header=[]
    # checksum
    @header +=  checksum
    # dsize
    @header += out_fix_word(@tfm.designsize)
    # 2..11 coding scheme, bcpl
    out_bcpl(@tfm.codingscheme,40)
    # 12..16 font identifier
    out_bcpl(@tfm.fontfamily,20)
    # calculate 7bitflag!
    # 7bitflag, byte, byte, face
    if @tfm.sevenbitsafeflag
      @header << 128
    else
      @header << 0
    end
    @header << 0 
    @header << 0
    @header << @tfm.face
    @lh = @header.size / 4
  end
  def update_bc_ec
    @bc=nil
    @tfm.chars.each_with_index{ |elt,i|
      @bc=i if @bc==nil and elt!=nil
      @ec=i if elt
    }
  end
  def checksum
    return out_qbyte(@tfm.checksum)
  end

  def out_bcpl(string,len)
    str=string
    l = str.length
    if l > 39
      str=string[0..38]
    end
    l = str.length
    @header << l
    count=1
    str.each_byte { |x|
      count += 1
      @header << x
    }
    while len - count > 0
      @header << 0
      count += 1
    end
  end
  def out_dbyte(int)
    a1=int % 256
    a0=int / 256
    return [a0,a1]
  end
  def out_qbyte(int)
    a3=int % 256
    int = int / 256
    a2 = int % 256
    int = int / 256
    a1=int % 256
    a0=int / 256
    return [a0,a1,a2,a3]
  end
  
  # looks ok
  def out_fix_word(b)
    # a=int part, f=after dec point
    a=b.truncate
    f=b-a
    if b <  0
      f = 1 - f.abs
      a = a -1
    end
    x=(2**20.0*f).round
    a3=x.modulo(256)
    # x >>= 8
    x=x/256
    a2=x % 256
    # x >>= 8
    x = x >> 8
    a1=x % 16
    a1 += (a % 16) << 4
    a0=b < 0 ? 256 + a / 16 : a / 16
    [a0,a1, a2, a3]
  end

  def sort_in(h,d)
    if d==0 and h!=WIDTH
      return 0
    end
    p=h
    while d >= @memory[@link[p]]
      p=@link[p]
    end
    if d==@memory[p] and p!=h
      return p
    end
    raise "Memory overflow: more than 1028 widths etc." if @mem_ptr==@memsize
    @mem_ptr += 1
    @memory[@mem_ptr]=d
    @link[@mem_ptr]=@link[p]
    @link[p]=@mem_ptr
    @memory[h]+=1
    return @mem_ptr
  end
  
  # see PLtoTF, §75pp
  def min_cover(h,d)
    m=0
    p=@link[h]
    @next_d=@memory[0] # large value
    while p!=0
      m += 1
      l = @memory[p]
      while @memory[@link[p]]<=l+d
        p=@link[p]
      end
      p=@link[p]
      if @memory[p]-l < @next_d
        @next_d=@memory[p]-l
      end
    end
    return m
  end

  def shorten(h,m)
    if @memory[h] <= m
      return 0
    end
    @excess=@memory[h]-m
    if @excess > 0 and @verbose
      puts "We need to shorten the list by #@excess"
    end
    k=min_cover(h,0)
    d=@next_d
    begin
      d=d+d
      k=min_cover(h,d)
    end until k <= m
    d = d / 2
    k=min_cover(h,d)
    while k > m
      d=@next_d
      k=min_cover(h,d)
    end
    return d
  end

  def set_indices(h,d)
    q=h
    p=@link[q]
    m=0
    while p!=0
      m+=1
      l=@memory[p]
      @index[p]=m
      while @memory[@link[p]] <= l+d
        p=@link[p]
        @index[p]=m
        @excess -= 1
        if @excess == 0
          d=0
        end
      end
      @link[q]=p
      @memory[p] = l+(@memory[p]-l) / 2
      q=p
      p=@link[p]
    end
    @memory[h]=m
  end

end




class TFMParser
  # reading a tfm file is about 10 times faster than doing
  # `tftop xyz.pl` and using PL#parse. And only a bit slower than
  # `tftop xyz.pl > /dev/null` alone. (1.3 secs. vs. 0.9 secs. - 10 times)

  # Output more information
  attr_accessor :verbose
  
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

    if @verbose
      puts "lf=#{@lf}"
      puts "lh=#{@lh}"
      puts "bc=#{@bc}"
      puts "ec=#{@ec}"
      puts "nw=#{@nw}"
      puts "nh=#{@nh}"
      puts "nd=#{@nd}"
      puts "ni=#{@ni}"
      puts "nl=#{@nl}"
      puts "nk=#{@nk}"
      puts "ne=#{@ne}"
      puts "np=#{@np}"
    end
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
      count = get_byte
      @tfm.fontfamily=get_chars(count)
    end
    @index = (@header_base + 17 ) * 4
    if @lh >= 17
      @tfm.sevenbitsafeflag=get_byte > 127
      # two bytes ignored
      get_byte ; get_byte
      @tfm.face=get_byte
    end
    # let us ignore the rest of the header (TeX ignores it, so we may
    # do the same)
  end # parse_header

  def parse_params
    @index=@param_base * 4
    @tfm.slant=get_fix_word
    @tfm.space=get_fix_word
    @tfm.stretch=get_fix_word
    @tfm.shrink=get_fix_word
    @tfm.xheight=get_fix_word
    @tfm.quad=get_fix_word
    @tfm.extraspace=get_fix_word
    if @font_type != :vanilla
      raise ScriptError, "I need to get more parameters, but nobody told me how to do this :-("
    end
  end # parse_params
  
  # §78 TFtoPL
  def parse_char_info
    @index=@char_base *4
    (@bc..@ec).each { |n|
      # p "looking at char #{sprintf("%o",n)}, index is at #{@index / 4}"
      tmp=if @tfm.chars[n]
            @tfm.chars[n]
          else
            Hash.new
          end
      index=get_byte
      tmp[:charwd]=get_fix_word((@width_base + index)*4)
      b=get_byte
      tmp[:charht]=get_fix_word((@height_base + (b >> 4))*4)
      tmp[:chardp]=get_fix_word((@depth_base + (b % 16))*4)
      tmp[:charic]=get_fix_word((@italic_base + (get_byte >> 2))*4)
      # we ignore the remainder and look it up on demand
      get_byte
      if index == 0
        @tfm.chars[n]=nil
      else
        @tfm.chars[n]=tmp
      end
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
      next unless @tfm.chars[c]
      if char_tag(c) == LIGTAG
        # p sprintf("%o",c)
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
    f= ((b[1] % 16) * 256 + b[2] ) * 256 + b[3]

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
