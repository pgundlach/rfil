# font.rb - Implements Font. See that class for documentaton.
#-- 
# Last Change: Wed Jul 20 16:29:44 2005
#++
require 'set'

require 'helper'
require 'afm'
require 'truetype'
require 'enc'
require 'kpathsea'
require 'pl'

# Main class to manipulate and combine font metrics. This is mostly a
# convenience class, if you don't want to do the boring stuff
# yourself. You can 'load' a font, manipulate the data and create a pl
# and vpl file. It is used in conjunction with FontCollection, a class
# that contains several Font objects (perhaps a font family).
# The Font class relys on PL to write out the property lists, on the
# subclasses of RFI, especially on RFI::Glyphlist that knows about a
# lot of things about the char metrics, ENC for handling the encoding
# information and, of course, FontMetric and its subclasses to read a
# font. 

class Font
  def self.documented_as_accessor(*args) # :nodoc:
  end 

  include Helper
  
  # The encoding that the PDF/PS expects (what is put before
  # "ReEncodeFont" in the mapfile). If not set, use the setting from
  # the fontcollection. You can specify at most one encoding. If you
  # set it to an array of encodings, only the first item in the array
  # will be used. The assignment to _mapenc_ can be an Enc object or a
  # string that is a filename of the encoding. If unset, use all the
  # encoding mentioned in #texenc. In this case, a one to one mapping
  # will be done: 8r -> 8r, t1 -> t1 etc. (like the -T switch in
  # afm2tfm).
  documented_as_accessor :mapenc

  # Array of encodings that TeX spits out. If it is not set, take
  # the settings from the fontcollection.
  documented_as_accessor :texenc

  # The fontmetric of the default font
  attr_accessor :defaultfm

  # extend font with this factor
  attr_accessor :efactor

  # slantfactor
  attr_accessor :slant

  # Don't write out virtual fonts if write_vf is set to false here or
  # in the fontcollection.
  documented_as_accessor :write_vf

  documented_as_accessor :style

  # :dryrun, :verbose, see also fontcollection
  attr_accessor :options

  attr_accessor :variants
  # If fontcollection is supplied, we are now part as the
  # fontcollection. You can set mapenc and texenc in the fontcollection
  # and don't bother about it here. Settings in a Font object will
  # override settings in the fontcollection.
  
  def initialize (fontcollection=nil)
    # we are part of a fontcollection
    @fontcollection=fontcollection
    # @defaultfm=FontMetric.new
    @efactor=1.0
    @slant=0.0
    @capheight=nil
    @write_vf=true
    @texenc=nil
    @mapenc=nil
    @variants=[]
    @style=nil
    @dirs={}
    @origsuffix="-orig"
    @kpse=Kpathsea.new
    if fontcollection
      unless @fontcollection.respond_to?(:register_font)
        raise ArgumentError, "parameter does not look like a fontcollection"
      end
      @colnum=@fontcollection.register_font(self)
    else
      # the default dirs
      set_dirs(Dir.getwd)
    end
    @options=Options.new(fontcollection)
  end

  # hook run after font has been loaded by load_variant
  def after_load_hook (*args,&b)
  end
  # Read a font(metric file). Return a number that identifies the font.
  # The first font read is the default font. 
  def load_variant(fontname)
    fm=nil
    
    if fontname.instance_of? String
      if File.exists?(fontname)
        case File.extname(fontname)
        when ".afm"
          fm=AFM.new
        when ".ttf"
          fm=TrueType.new
        else
          raise ArgumentError, "Unknown filetype: #{File.basename(fontname)}"
        end
      else
        # let us guess the inputfile
        %w( .afm .ttf ).each { |ext|
          if File.exists?(fontname+ext)
            fontname += ext
            case ext
            when ".afm"
              fm=AFM.new
            when ".ttf"
              fm=TrueType.new
            end
            break
          end
        }
      end
      raise Errno::ENOENT unless fm
      fm.read(fontname)
      raise ScriptError, "Fontname is not set" unless fm.name
    elsif fontname.respond_to? :charwd
      # some kind of font metric
      fm=fontname
    end
    class << fm
      # scalefactor of font (1=don't scale)
      attr_accessor :fontat

      # auxiliary attribute to store the name of the 'original' font
      attr_accessor :mapto
    end

    
    @variants.push(fm)
    fontnumber=@variants.size - 1
    
    # the first font loaded is the default font
    if fontnumber == 0
      @defaultfm = fm
    end
    
    fm.chars.each { |name,chardata|
      chardata.fontnumber=fontnumber
    }

    fm.chars.fix_height(fm.xheight)
    fm.fontat=1   # default scale factor
    after_load_hook
    fontnumber
  end # load_variant


  # change the metrics (and glyphs) of the default font so that
  # uppercase variants are mapped onto the lowercase variants.
  def fake_caps(fontnumber,capheight)
    raise ScriptError, "no font loaded" unless @defaultfm
    # first, make a list of uppercase and lowercase glyphs
    @defaultfm.chars.update_uc_lc_list
    @capheight=capheight
    v=@variants[fontnumber]
    v.fontat=capheight
    v.chars.fake_caps(capheight)
  end

  
  # Return PL (property list) object that represents the tfm file of
  # the font. enc is the encoding of the tfm file, which must be an
  # ENC object. No ligature and or kerning information is put into the
  # pl file. *obsolete* -> use pl(enc,noligs=>true) instead.
  def pl_nolig(enc)
    pl=PL.new(false)
    pl.family=@defaultfm.familyname
    pl.codingscheme=enc.encname
    pl.designsize=10.0
    pl.designunits=1000

    fd={}
    fd[:slant]=@slant - @efactor * Math::tan(@defaultfm.italicangle * Math::PI / 180.0)
    fd[:space]=transform(@defaultfm.space,0)
    fd[:stretch]=@defaultfm.isfixedpitch ? 0 : transform(300,0)
    fd[:shrink]=@defaultfm.isfixedpitch ? 0 : transform(100,0)
    fd[:xheight]=@defaultfm.xheight
    fd[:quad]=transform(1000,0)

    # @defaultfm.chars.slant_extend(@slant,@efactor)

    pl.fontdimen=fd
    enc.each_with_index{ |char,i|
      next if char==".notdef"
      thisglyph=@defaultfm.chars[char]
      next unless thisglyph
      thisglyph.efactor=@efactor
      thisglyph.slant=@slant
      glyphhash={}
      glyphhash[:comment]=char
      [:charwd, :charht, :chardp, :charic].each { |sym|
        glyphhash[sym]=thisglyph.send(sym)
      }
      pl[i]=glyphhash
    }
    pl
  end

  # Return PL (property list) object that represents the tfm file of
  # the font. enc is the encoding of the tfm file, which must be an
  # ENC object. Ligature and kerning information is put into the pl
  # file unless <tt>:noligs</tt> is set to true in the opts.
  def pl(enc,opts={})
    # puts "font#pl called with encoding #{enc.encname}"
    plist=PL.new(false)
    plist.family=@defaultfm.familyname
    plist.codingscheme=enc.encname
    plist.designsize=10.0
    plist.designunits=1000

    fd={}
    fd[:slant]=@slant - @efactor * Math::tan(@defaultfm.italicangle * Math::PI / 180.0)
    fd[:space]=transform(@defaultfm.space,0)
    fd[:stretch]=@defaultfm.isfixedpitch ? 0 : transform(300,0)
    fd[:shrink]=@defaultfm.isfixedpitch ? 0 : transform(100,0)
    fd[:xheight]=@defaultfm.xheight
    fd[:quad]=transform(1000,0)
    plist.fontdimen=fd

    charhash=enc.glyph_index.dup
    
    enc.each_with_index{ |char,i|
      next if char==".notdef"

      thischar=@defaultfm.chars[char]
      next unless thischar

      # ignore those chars we have already encountered
      next unless charhash.has_key?(char)

      thischar.efactor=@efactor
      thischar.slant=@slant
      # puts "char=#{char}, charhash[char]=#{charhash[char].inspect}"
      allslots=charhash[char].sort
      firstslot=allslots.shift
      charhash.delete(char)
      
      ligkern=RFI::LigKern.new
      thischar.lig_data.each_value { |lig|
        if (enc.glyph_index.has_key? lig.right) and
            (enc.glyph_index.has_key? lig.result)
          # lig is like "hyphen ..." but needs to be in a format like
          # "45 .."
            ligkern[:lig] = lig.to_pl(enc)
        end
      }
      thischar.kern_data.each { |dest,kern|
        if (enc.glyph_index.has_key? dest)
          enc.glyph_index[dest].each { |slot|
            
            tmp=[slot,(kern[0]*@efactor)]
            if ligkern[:krn]
              ligkern[:krn].push(tmp)
            else
              ligkern[:krn]=[tmp]
            end
          }
        end
      }

      charentry={}
      if ( (ligkern[:krn] and ligkern[:krn].size!=0) or
             (ligkern[:lig] and ligkern[:lig].size!=0) ) and
          opts[:noligs] != true
        charentry[:ligkern]=ligkern
      end

      charentry[:comment]=char
      [:charwd, :charht, :chardp, :charic].each { |sym|
        charentry[sym]=thischar.send(sym)
      }
      plist[i]=charentry
      allslots.each { |otherslot|
        charentry[:ligkern]=firstslot
        plist[otherslot]=charentry
      }
    }
    plist
  end
  
  # Return a PL (virtual property list) object that represents a vf
  # file of the font. _mapenc_ and _texenc_ must be an ENC object.
  # _mapenc_ is the destination encoding (of the fonts in the mapfile)
  # and _texenc_ is is the encoding of the resulting tfm file. They
  # may be the same.
  
  def vpl(mapenc,texenc)
    
    raise ArgumentError, "mapenc must be an ENC object" unless mapenc.respond_to? :encname
    raise ArgumentError, "texenc must be an ENC object" unless texenc.respond_to? :encname
    
    vplplist=PL.new(true)
    vplplist.vtitle="Installed with rfi library"
    vplplist.add_comment(" Please edit that VTITLE if you edit this file")
    vplplist.family=@defaultfm.familyname
    vplplist.codingscheme= if mapenc.encname != texenc.encname
                        mapenc.encname + " + " + texenc.encname
                      else
                        mapenc.encname
                      end
    vplplist.designsize=10.0
    vplplist.designunits=1000
    fm=@defaultfm
    fd={}
    fd[:slant]=@slant - @efactor * Math::tan(fm.italicangle * Math::PI / 180.0)
    fd[:space]=transform(fm.space,0)
    #fd[:space]=fm.transform(fm.space,0)
    fd[:stretch]=fm.isfixedpitch ? 0 : transform(200,0)
    fd[:shrink]=fm.isfixedpitch ? 0 : transform(100,0)
    fd[:xheight]=fm.xheight
    fd[:quad]=transform(1000,0)
    fd[:extraspace]=fm.isfixedpitch ? fm.space : transform(111,0)
    vplplist.fontdimen=fd

    map=[]
    fontmapping=find_used_fonts()
    fontmapping.each_with_index { |fontnumber,i|
      maph={}
      maph[:fontname]=map_fontname(mapenc,fontnumber)
      if @variants[fontnumber].fontat != 1
        maph[:fontat]=@variants[fontnumber].fontat * 1000
      end
      map.push(maph)
    }
    vplplist.mapfont=map
    
    charhash=texenc.glyph_index.dup
    # now for the ligatures
    # we should ignore duplicate ligature/kern entries in the future!
    texenc.each_with_index  { |char,i|
      next if char == ".notdef"
      
      # ignore those not in dest 
      # next unless mapenc.glyph_index[char]
      next unless mapenc.glyph_index.include?(char)

      # next if this glyph is unknown
      thischar=@defaultfm.chars[char]
      next unless thischar

      # ignore those chars we have already encountered
      next unless charhash.has_key?(char)
      

      thischar.efactor=@efactor
      thischar.slant=@slant

      allslots=charhash[char].sort
      firstslot=allslots.shift
      charhash.delete(char)
      
      # (there might be some more slots left, but let's first do the lig)
      
        
      # lig
      ligkern=RFI::LigKern.new

      # right must be duplicated!
      #
      # 127: hyphen
      #   Difference in lig information
      #   | [LIG 127 + 45 => 21]
      #   | [LIG 127 + 127 => 21]
      #   vs.
      #   | [LIG 127 + 45 => 21]
      # 
      thischar.lig_data.each_value { |lig|
        if (texenc.glyph_index.has_key? lig.right) and
            (texenc.glyph_index.has_key? lig.result)
          # lig is like "hyphen ..." but needs to be in a format like
          # "45 .."
            ligkern[:lig] = lig.to_pl(texenc)
        end
      }

      # kern
      thischar.kern_data.each { |dest,kern|
        if (texenc.glyph_index.has_key? dest)
          texenc.glyph_index[dest].each { |slot|
            
            tmp=[slot,(kern[0]*@efactor)]
            if ligkern[:krn]
              ligkern[:krn].push(tmp)
            else
              ligkern[:krn]=[tmp]
            end
          }
        end
      }

      
      charentry={}
      if (ligkern[:krn] and ligkern[:krn].size!=0) or
          (ligkern[:lig] and ligkern[:lig].size!=0)
        charentry[:ligkern]=ligkern
      end
      
      # charinfo
      [:charwd, :charht, :chardp, :charic].each { |sym|
        charentry[sym]=thischar.send(sym)
      }

      # puts "looking at #{char}, mapenc[#{i}]=#{mapenc[i]}"
      # map
      mapneeded=(thischar.fontnumber != 0 or
                   (mapenc.glyph_index[char].member?(i)==false) or
                   (allslots.size > 0 ) or
                   thischar.pcc_data
                 )
      if mapneeded
        # puts "mapneeded: for #{char} (thischar.mapto=#{thischar.mapto})"
        # destchar

        # cleanup!!
        if thischar.pcc_data
          # (MAP
          #   (SELECTFONT D 1)
          #   (SETCHAR C S)
          #   (SETCHAR C S)
          #  )

          tmp=[]
          tmp.push [:selectfont, thischar.fontnumber]
          thischar.pcc_data.each { |d|
            smallest = mapenc.glyph_index[d[0]].min
            tmp.push [:setchar,smallest]
          }
          charentry[:map]=tmp
        else
          if thischar.fontnumber > 0
            lookat = if thischar.mapto==nil
                       char
                     else
                       thischar.mapto
                     end
            
            # just map it to another font
            smallest = mapenc.glyph_index[lookat].min
            charentry[:map]=[[:setchar,smallest]]
            charentry[:map].unshift([:selectfont,thischar.fontnumber])
          else
            # map it to the same font
            smallest = mapenc.glyph_index[char].min
            charentry[:map]=[[:setchar,smallest]]
            
          end
        end
      end
      vplplist[i]=charentry
      allslots.each { |otherslot|
        charentry[:ligkern]=firstslot
        vplplist[otherslot]=charentry
      }

    }
    return vplplist
  end

  # Todo: document and test!
  def apply_ligkern_instructions(what)
    @defaultfm.chars.apply_ligkern_instructions(what)
  end  

  # Return a string or an array of strings that should be put in a mapfile.
  def maplines(opts={})
    # "normally" (afm2tfm)
    # savorg__ Savoy-Regular " mapenc ReEncodeFont " <savorg__ <mapenc.enc

    # enc-fontname[-variant]*.tfm
        
    # or without the "ReEncodeFont" (check!)


    # we default to ase (Adobe Standard Encoding), on your TeX system
    # as 8a.enc
    
    # if mapenc (the encoding TeX writes to the dvi file) is not set
    texenc_loc = texenc
    unless texenc_loc
      f=@kpse.open_file("8a.enc","enc")
      texenc_loc=[ENC.new(f)]
      f.close
    end
    ret=[]
    encodings=Set.new
    texenc.each { |te|
      encodings.add mapenc ? mapenc : te
    }
    fontsused=find_used_fonts
    encodings.each { |te|
      fontsused.each { |f|
        str=map_fontname(te,f)
        str << " #{@variants[f].fontname} "
        instr=[]
        if @slant != 0.0
          instr << "#@slant SlantFont"
        end
        if @efactor != 1.0
          instr << "#@efactor ExtendFont"
        end
        unless te.filename == "8a.enc"
          instr << "#{te.encname} ReEncodeFont"
        end
        
        str << "\"" << instr.join(" ") << "\"" if instr.size > 0
        unless te.filename == "8a.enc"
          str << " <#{te.filename}"
        end
        str << " <#{@variants[f].fontfilename}"
        str << "\n"
        ret.push str 
      }
    }
    # FIXME: remove duplicate lines in a more sensible way
    # no fontname (first entry) should appear twice!
    ret.uniq
  end

  # Creates all the necessary files to use the font. This is mainly a
  # shortcut if you are too lazy to program. _opts_:
  # [:dryrun] true/false
  # [:verbose] true/false
  # [:mapfile] true/false
  
  def write_files(opts={})
      
    
    tfmdir=get_dir(:tfm); ensure_dir(tfmdir)
    vfdir= get_dir(:vf) ; ensure_dir(vfdir)
    unless opts[:mapfile]==false
      mapdir=get_dir(:map); ensure_dir(mapdir)
    end

    encodings=Set.new
    texenc.each { |te|
      encodings.add mapenc ? mapenc : te
    }
    encodings.each { |enc|
      find_used_fonts.each { |var|
        tfmfilename=File.join(tfmdir,map_fontname(enc,var) + ".tfm")

        if options[:verbose]==true
          puts "tfm: writing tfm: #{tfmfilename}" 
        end
        unless options[:dryrun]==true
          pl(enc).write_tfm(tfmfilename)
        end
      }
    }

    if write_vf
      # vf
      encodings=Set.new
      texenc.each { |te|
        encodings.add mapenc ? mapenc : te
      }
      texenc.each { |te|
        outenc = mapenc ? mapenc : te
        # vplfilename=File.join(vpldir,tex_fontname(te) + ".vpl")
        vffilename= File.join(vfdir, tex_fontname(te) + ".vf")
        vplfilename= File.join(vfdir, tex_fontname(te) + ".vpl")
        tfmfilename=File.join(tfmdir,tex_fontname(te) + ".tfm")
        if options[:verbose]==true
          puts "vf: writing tfm: #{tfmfilename}"
          puts "vf: writing vf: #{vffilename}"
        end
        unless options[:dryrun]==true
          vpl(outenc,te).write_vf(vffilename,tfmfilename)
          # vpl(outenc,te).write_vpl(vplfilename)
        end
      }
    end
    
    unless opts[:mapfile]==false
      # mapfile
      if options[:verbose]==true
        puts "writing #{mapfilename}"
      end
      unless options[:dryrun]==true
        File.open(mapfilename,"w") { |f|
          f << maplines
        }
      end
    end
  end
  
  # Return a directory where files of type _type_ will be placed in.
  # Default to current working directory.
  def get_dir(type)
    if @dirs.has_key?(type)
      @dirs[type]
    elsif @fontcollection and @fontcollection.dirs.has_key?(type)
      @fontcollection.dirs[type]
    else
      Dir.getwd
    end
  end

  def mapenc  # :nodoc:
    if @mapenc==nil and @fontcollection
      @fontcollection.mapenc
    else
      @mapenc
    end
  end
  def mapenc=(enc) # :nodoc:
    set_mapenc(enc)
  end

  def texenc  # :nodoc:
    if @texenc
      @texenc
    else
      # @texenc not set
      if @fontcollection
        @fontcollection.texenc
      else
        ret=nil
        @kpse.open_file("8a.enc","enc") { |f|
          ret = [ENC.new(f)]
        }
        # puts "returning #{ret}"
        return ret
      end
    end
  end
  def texenc=(enc) # :nodoc:
    @texenc=[]
    if enc
      set_encarray(enc,@texenc)
    end
  end

  # Return the full path to the mapfile.
  def mapfilename
    File.join(get_dir(:map),@defaultfm.name + ".map")
  end

  # untested, put in helper
  def style        # :nodoc:
    if @fontcollection
      @fontcollection.style
    else
      @style
    end
  end
  def style=(obj)         # :nodoc:
    @style=obj
  end
#   def options         # :nodoc:
#     if @fontcollection
#       @fontcollection.options
#     else
#       @options
#     end
#   end
  
  def write_vf        # :nodoc:
    if @fontcollection
      @fontcollection.write_vf
    else
      @write_vf
    end
  end
  def write_vf= (obj) # :nodoc:
    @write_vf=obj
  end
  
  # Copy glyphs from one font to the default font. _fontnumber_ is the
  # number that is returned from load_variant, _glyphlist_ is whatever
  # you want to copy. Overwrites existing chars. _opts_ is one of:
  # [:ligkern] copy the ligature and kerning information with the glyphs stated in glyphlist. This will remove all related existing ligature and kerning information the default font.
  # *needs testing*
  def copy(fontnumber,glyphlist,opts={})
    tocopy=[]
    case glyphlist
    when Symbol
      tocopy=@defaultfm.chars.foo(glyphlist)
    when Array
      tocopy=glyphlist
    end

    tocopy.each { |glyphname|
      @defaultfm.chars[glyphname]=@variants[fontnumber].chars[glyphname]
      @defaultfm.chars[glyphname].fontnumber=fontnumber
    }
    if opts[:ligkern]==true
      # assume: copying lowercase letters.
      # we need to copy *all* lowercase -> * data and replace all 
      # we need to remove all uppercase -> lowercase data first
      # we need to copy   all uppercase -> lowercase data
      @variants[fontnumber].chars.each { |glyphname,data|
        if tocopy.member?(glyphname)
          #puts "font#copy: using kern_data for #{glyphname}"
          @defaultfm.chars[glyphname].kern_data=data.kern_data.dup
        else
          # delete all references to the 'tocopy'
          @defaultfm.chars[glyphname].kern_data.each { |destchar,kern|
            if tocopy.member?(destchar)
              #puts "font#copy: removing kern_data for #{glyphname}->#{destchar}"
              @defaultfm.chars[glyphname].kern_data.delete(destchar)
            end
          }
          data.kern_data.each { |destchar,kern|
            if tocopy.member?(destchar)
              @defaultfm.chars[glyphname].kern_data[destchar]=kern
            end
          }
        end
      }
    end
  end  # copy
  
  # Return an array with all used fontnumbers loaded with
  # load_variant. If, for example, fontnubmer 0 and 3 are used,
  # find_used_fonts would return [0,3].
  def find_used_fonts
    fonts=Set.new
    @defaultfm.chars.each{ |glyph,data|
      fonts.add(data.fontnumber)
    }
    fonts.to_a.sort
  end
  
  
  # Return the name of the font in the mapline. If we don't write
  # virtual fonts, this is the name of the tfm file written. If we
  # write vf's, than this is the name used in the mapfont section of
  # the virtual font as well as the name of the tfm file, but both
  # with some marker that this font 'should' not be used directly. 
  def map_fontname (texenc,varnumber=0,opts={})
    mapenc_loc=mapenc
    suffix=""
    suffix << @origsuffix if write_vf
    if mapenc_loc
      # use the one in mapenc_loc
      construct_fontname(mapenc,varnumber) + suffix 
    else
      construct_fontname(texenc,varnumber) + suffix
    end
  end

  # Return the name 
  def tex_fontname (encoding)
    tf=construct_fontname(encoding)
    tf << "-capitalized-#{(@capheight*1000).round}" if @capheight
    tf
  end
 
  #######
  private
  #######
  def construct_fontname(encoding,varnumber=0)
    encodingname=if String === encoding
                   encoding
                 else
                   if encoding.filename
                     encoding.filename.chomp(".enc").downcase
                   else
                     encoding.encname
                   end
                 end
    
    fontname=@variants[varnumber].name
    # default
    tf=if encodingname == "8a"
         "#{fontname}"
       else
         "#{encodingname}-#{fontname}"
       end
    tf << "-slanted-#{(@slant*100).round}" if @slant != 0.0
    tf << "-extended-#{(@efactor*100).round}" if @efactor != 1.0
    
    tf

  end
  
  def transform (x,y)
    (@efactor * x + @slant * y).round
  end

end # class Font
