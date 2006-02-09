# vf.rb -- Class that models TeX's virtual fonts.
#--
# Last Change: Thu Feb  9 17:04:16 2006
#++

require 'tex/tfm'
require 'tex/kpathsea'

module TeX

  # The vf (virtual font) files are described in vftovp and vptovf. They
  # are always connected with a tfm file that hold the font metric. The
  # vf contain some redundant information copied from the tfm file.
  # Since the VF class is derived from the TFM class, there is no need
  # to duplicate these pieces of information.

  class VF < TFM
    # This class is not meant to be used directly by the programmer. It
    # is used in the VF class to read a virtual font from a file.

    class VFReader
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
        @kpse=Kpathsea.new
        @data=vfdata.unpack("C*")

        raise VFError, "This does not look like a vf to me" if 247 != get_byte
        raise VFError, "Unknown VF version" unless  202 == get_byte

        @vfobj.vtitle=get_chars(get_byte)

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
            # perhaps we should actually load the tfm instead of saving
            # the metadata?         
            @vfobj.fontlist[fontnumber]={}
            checksum=get_qbyte
            # @vfobj.fontlist[fontnumber][:checksum]=checksum
            scale=get_fix_word
            @vfobj.fontlist[fontnumber][:scale]=scale
            dsize = get_fix_word
            # @vfobj.fontlist[fontnumber][:designsize]=dsize
            a = get_byte   # length of area (directory?)
            l = get_byte   # length of fontname
            area=get_chars(a)
            name=get_chars(l)
            # @vfobj.fontlist[fontnumber][:name]=name
            @kpse.open_file(name,'tfm') { |file|
              @vfobj.fontlist[fontnumber][:tfm]=TFM.new.read_tfm(file)
            }
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
          when 128..131
            c=4-(131-i)
            instructions << [:setchar, get_bytes(c,false,@dviindex+1)]
            @dviindex += c
          when 132,137
            x=out_as_fix(get_bytes(4,true,@dviindex+1))
            y=out_as_fix(get_bytes(4,true,@dviindex+5))
            instructions << [:setrule,x,y]
            @dviindex += 8
          when 133..136
            # are these ever used?
            c=4-(136-i)
            instructions << [:setchar, get_bytes(c,false,@dviindex+1)]
            @dviindex += c
          when 138
            # nop
          when 139,140
            raise VFError, "illegal instruction in VF: #{i}"
          when 141
            instructions << [:push]
            push
          when 142 
            instructions << [:pop]
            pop
          when 143..146
            c=4-(146-i)
            b=out_as_fix(get_bytes(c,true,@dviindex+1))
            instructions << [:moveright, b]
            @dviindex += c
          when 147
            instructions << [:moveright, _w]
          when 148..151
            c=4-(151-i)
            self._w=out_as_fix(get_bytes(c,true,@dviindex+1))
            instructions << [:moveright,_w]
            @dviindex += c
          when 152
            instructions << [:moveright, _x]
          when 153..156
            c=4-(156-i)
            x=out_as_fix(get_bytes(c,true,@dviindex+1))
            self._x=x
            instructions << [:moveright,x]
            @dviindex += c
          when 157..160
            # are these really used?
            c=i-157+1
            v=out_as_fix(get_bytes(c,true,@dviindex+1))
            instructions << [:movedown,v]
            @dviindex += c
          when 161
            instructions << [:movedown, _y]
          when 162..165
            c=i-162+1
            self._y = out_as_fix(get_bytes(c,true,@dviindex+1))
            instructions << [:movedown,_y]
            @dviindex += c
            # puts "#{i} movedown y #{_y}"
          when 166
            instructions << [:movedown, _z]
          when 167..170
            c=i-167+1
            self._z = out_as_fix(get_bytes(c,true,@dviindex+1))
            instructions << [:movedown,_z]
            @dviindex += c
            # puts "#{i} movedown z #{_z}"
          when 171..234
            instructions << [:selectfont, 63-234+i]
          when 235..238
            c=i-235+1
            instructions << [:selectfont, get_bytes(c,true,@dviindex+1)]
            @dviindex += c
          when 239..242
            c=i-239+1
            k=get_bytes(c,true,@dviindex+1)
            if k < 0
              raise VFError, "length of special is negative"
            end
            instructions << [:special, get_chars(k,@dviindex+2)]
            @dviindex += 1+k
          when 243..255
            raise VFError, "illegal instruction in VF: #{i}"
          else
            raise "not implemented: #{i}"
          end
          @dviindex += 1
        end
        # puts "charcode=#{cc} (octal #{sprintf("%o",cc)})"
        tmp=if @vfobj.chars[cc]
              @vfobj.chars[cc]
            else
              Hash.new
            end
        @vfobj.chars[cc]=tmp
        tmp[:dvi]=instructions
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

    
    class VFWriter
      attr_accessor :verbose
      def initialize(vfobject)
        @vf=vfobject
      end

      def to_data
        # preamble
        @data=[247,202]
        @data += out_string(@vf.vtitle)
        @data += out_qbyte(@vf.checksum)
        @data += out_fix_word(@vf.designsize)

        # fonts
        @vf.fontlist.each_with_index { |f,i|
          count,*bytes=out_n_bytes(i)
          @data += [242+count]
          @data += bytes

          @data+=out_qbyte(f[:tfm].checksum)
          @data+=out_fix_word(f[:scale])
          @data+=out_fix_word(f[:tfm].designsize)
          @data+=[0]
          @data += out_string(f[:tfm].tfmfilename.chomp('.tfm'))
        }
        
        # now for the chars
        @vf.chars.each_with_index { |c,i|
          next unless c
          dvi=out_instructions(c[:dvi])
          pl=dvi.length
          tfm=c[:charwd]
          if  pl < 242 and tfm < 16.0 and tfm > 0 and i < 256
            @data << pl
            @data << i
            @data += out_fix_word(tfm,3)
          else
            @data << 242
            @data += out_qbyte(pl)
            @data += out_qbyte(i)
            @data += out_fix_word(tfm)
          end
          @data += dvi
        }
        @data << 248
        while @data.size % 4 != 0
          @data << 248
        end
        return @data.pack("C*")
      end

      #######
      private
      #######

      def out_instructions(instructionlist)
        ret=[]
        instructionlist.each { |i|
          case i[0]
          when :setchar
            charnum=i[1]
            if charnum < 128
              ret << charnum
            elsif charnum > 255
              raise VFError, "TeX does not know about chars > 8bit"
            else
              ret << 128
              ret << charnum
            end
          when :setrule
            ret << 132
            ret += out_fix_word(i[1])
            ret += out_fix_word(i[2])
          when :noop
            ret << 138
          when :push
            ret << 141
          when :pop
            ret << 142
          when :moveright
            # should we choose another moveright? --pg
            ret << 156
            ret += out_fix_word(i[1])
          when :movedown
            ret << 165
            ret += out_fix_word(i[1])
          when :special
            len,*data=out_string(i[1])
            blen,bytes = out_n_bytes(len)
            ret << blen+238
            ret << bytes
            ret += data
          else
            raise VFError, "not implemented"
          end
        }
        ret
      end

      def out_n_bytes(int)
        case 
        when (int < 0), (int >= 0100000000)
          [4] + out_sqbyte(int)
        when int >= 0200000
          [3] + out_tbyte(int)
        when int >= 0400
          [2] + out_dbyte(int)
        else
          [1,int]
        end
      end
      def out_dbyte(int)
        a1=int % 256
        a0=int / 256
        return [a0,a1]
      end
      def out_tbyte(int)
        a2 = int % 256
        int = int / 256
        a1=int % 256
        a0=int / 256
        return [a0,a1,a2]
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
      # signed four bytes
      def out_sqbyte(int)
        a3=int % 256
        int = int / 256
        a2 = int % 256
        int = int / 256
        a1=int % 256
        a0=int / 256
        if int < 0
          a0 = 256 + a0
        end
        return [a0,a1,a2,a3]
      end
      def out_fix_word(b,bytes=4)
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
        if bytes == 3
          [a1, a2, a3]
        else
          [a0,a1, a2, a3]
        end
      end

      def out_string(string)
        unless string
          return [0]
        end
        ret=[string.length]
        string.each_byte { |s|
          ret << s
        }
        return ret
      end
    end

    
    # Parse a vpl (virtual property list) file. See also TFM::PLParser.
    class VPLParser < PLParser
      # _vfobj_ is an initialized object of the VF class. Call
      # parse(fileobj) to fill the VF object.
      def initialize(vfobj)
        @vf=vfobj
        super
        @syntax["VTITLE"] =:get_vtitle
        @syntax["MAPFONT"]=:get_mapfont
      end

      #######
      private
      #######

      def get_vtitle
        @vf.vtitle=get_string
      end
      def get_mapfont
        @vf.fontlist=[]
        t = @vf.fontlist[get_num] = {}
        t[:tfm]=TFM.new
        thislevel=@level
        while @level >= thislevel
          case k=keyword
          when "FONTNAME"
            t[:tfm].tfmpathname=get_string
          when "FONTCHECKSUM"
            t[:tfm].checksum=get_num
          when "FONTAT"
            t[:scale]=get_num
          when "FONTDSIZE"
            t[:tfm].designsize=get_num
          else
            raise "Unknown property in MAPFONT section: #{k}"
          end
        end
      end # get_mapfont

      # we copy this from tfm.rb, because now MAP is also allowed
      def get_character
        thischar = @tfm.chars[get_num] ||= {}
        thislevel=@level
        while @level >= thislevel
          case k=keyword
          when "COMMENT"
            get_balanced
            eat_closing_paren
          when "CHARWD","CHARHT","CHARDP","CHARIC"
            thischar[k.downcase.to_sym]=get_num
          when "MAP"
            instr=thischar[:dvi]=[]
            maplevel=@level
            while @level >= maplevel
              case ik=keyword
              when "SELECTFONT"
                instr << [:selectfont, get_num]
              when "SETCHAR"
                instr << [:setchar, get_num]
              when "SETRULE"
                instr << [:setrule, get_num, get_num]
              when "MOVEDOWN"
                instr << [:movedown, get_num]
              when "MOVERIGHT"
                instr << [:moveright, get_num]
              when "PUSH"
                instr << [:push]
                eat_closing_paren
              when "POP"
                instr << [:pop]
                eat_closing_paren
              when "SPECIAL"
                instr << [:special, get_balanced]
                # puts "special, #{get_balanced}"
                eat_closing_paren
              else
                raise "Unknown instruction in character/map section: #{ik}"
              end
            end
          else
            raise "Unknown property in pl file/character section: #{k}"
          end
        end
      end # get_character
    end
    
    

    # VF class
    
    # Raise this exception if an error related to the virtual font is
    # encountered. Don't expect this library to be too clever at the beginning.
    class VFError < Exception
    end

    def self.documented_as_accessor(*args) #:nodoc:
    end
    def self.documented_as_reader(*args) #:nodoc:
    end

    # Filename sans path of the vf file. To change this attribute, set
    # vfpathname. 
    documented_as_reader :vffilename

    # Path to the vf file.
    attr_accessor :vfpathname


    # fontlist is an array of Hashes with the following keys:
    # [<tt>:scale</tt>] Relative size of the font
    # [<tt>:tfm</tt>] TFM object.
    attr_accessor :fontlist

    # This is the same Array as in TFM. Besides the keys <tt>:charwd</tt>,
    # <tt>:charht</tt>, <tt>:chardp</tt> and <tt>:charic</tt>, we now have a key
    # <tt>:dvi</tt> that holds all vf instructions.
    documented_as_accessor :chars

    # Comment at the beginning of the vf file. Must be < 256 chars.
    attr_accessor :vtitle

    # Return an empty VF object
    def initialize
      super
      @vtitle=""
      @fontlist=[]
    end

    def vffilename # :nodoc:
      File.basename(@vfpathname)
    end

    # _vplfile_ is a filename (String). (Future: File and String (pathname))
    def read_vpl(vplfilename)
      File.open(vplfilename) { |f|
        parse_vpl(f.read)
      }
      return self
    end
    def parse_vpl(vplstring)
      v=VPLParser.new(self)
      v.parse(vplstring)
      return self
    end

    # _file_ is either a string (pathname) of a File object (must
    # respond to read)
    def read_vf(file)
      p=VFReader.new(self)
      if file.respond_to? :read
        if file.respond_to? :path
          @vfpathname=file.path
        end
        p.parse(file.read)
      else
        # we assume it is a string
        @vfpathname=file
        case file
        when /\.vf$/
          File.open(file) { |f|
            p.parse(f.read)
          }
        else
          raise ArgumentError, "unknown Filetype: #{file}"
        end
      end
      t=TFMReader.new(self)
      @tfmpathname=@vfpathname.chomp(".vf")+".tfm"
      File.open(@tfmpathname){ |f|
        t.parse(f.read)
      }
      return self
    end #read_vf

    # If _overwrite_ is true, we will replace existing files without
    # raising Errno::EEXIST.
    def save(overwrite=false)
      # tfmpathname=@vfpathname.chomp(".vf")+".tfm"
      raise Errno::EEXIST if File.exists?(@vfpathname) and not overwrite
      raise Errno::EEXIST if File.exists?(@tfmpathname) and not overwrite
      puts "saving #{@vfpathname}..." if @verbose
      File.open(@vfpathname,"wb") { |f|
        write_vf_file(f)
      }
      puts "saving #{@vfpathname}...done" if @verbose
      puts "saving #{@tfmpathname}..." if @verbose
      File.open(@tfmpathname,"wb") { |f|
        write_tfm_file(f)
      }
      puts "saving #{@tfmpathname}...done" if @verbose

    end

    
    # _file_ is a File object (or something similar, it must
    # respond to <<). Will be moved.
    def write_vf_file(file)
      vfwriter=VFWriter.new(self)
      vfwriter.verbose=@verbose
      file << vfwriter.to_data
    end

    # _file_ is a File object (or something similar, it must
    # respond to <<). Will be moved.
    def write_tfm_file(file)
      tfmwriter=TFMWriter.new(self)
      tfmwriter.verbose=@verbose
      file << tfmwriter.to_data
    end
    # Return vptovf compatible output
    def to_s
      indent="   "
      str=""
      str << out_head(indent)
      str << "(VTITLE #{vtitle})\n"
      str << out_parameters(indent)
      str << out_mapfont(indent)
      str << out_ligtable(indent)
      str << out_chars(indent)
      str
    end

    #######
    private
    #######

    def out_chars(indent)
      str = ""
      chars.each_with_index { |c,i|
        next unless c
        # str << "(CHARACTER O #{sprintf("%o",i)}\n"
        str << "(CHARACTER D %d\n" % i
        [:charwd,:charht,:chardp,:charic].each { |dim|
          str << indent + "(#{dim.to_s.upcase} R #{c[dim]})\n" if c[dim]!=0.0
        }
        if c[:dvi]
          str << indent + "(MAP\n"
          c[:dvi].each { |instr,*rest|
            
            case instr
            when :setchar
              str << indent*2 + "(SETCHAR D %d)\n" % rest[0].to_i
            when :setrule
              str << indent*2 + "(SETRULE R #{rest[0]} R #{rest[1]})\n"
            when :noop
              # ignore
            when :push
              str << indent*2 + "(PUSH)\n"
            when :pop
              str << indent*2 + "(POP)\n"
            when :moveright
              str << indent*2 + "(MOVERIGHT R #{rest[0]})\n"
            when :movedown
              str << indent*2 + "(MOVEDOWN R #{rest[0]})\n"
            when :selectfont
              str << indent*2 + "(SELECTFONT D #{rest[0]})\n"
            when :special
              str << indent*2 + "(SPECIAL #{rest[0]})\n"
            else
              raise "unknown dvi instruction #{instr}"
            end
          }
          str << indent*2 + ")\n"
        end
        str << indent + ")\n"
      }
      str
    end

    def out_mapfont(indent)
      return "" if fontlist.size == 0
      str=""
      
      fontlist.each_with_index { |f,i|
        str << "(MAPFONT D %d\n" % i
        str << indent + "(FONTNAME %s)\n" % f[:tfm].tfmfilename
        str << indent + "(FONTCHECKSUM O %o)\n" % f[:tfm].checksum
        str << indent + "(FONTAT R %f)\n" % (f[:scale] ? f[:scale].to_f : 1.0)
        str << indent + "(FONTDSIZE R %f)\n" % f[:tfm].designsize
        str << indent + ")\n"
      }
      str
    end
  end #class VF

end #module TeX
