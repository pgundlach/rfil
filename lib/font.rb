# font.rb - Implements Font. See that class for documentaton.
#-- 
# Last Change: Tue Jul 12 00:48:27 2005
#++
require 'set'

require 'helper'
require 'afm'
require 'enc'
require 'kpathsea'
require 'pl'

# Main class to manipulate and combine font metrics.
class Font
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
  attr_accessor :mapenc

  # Array of encodings that TeX spits out. If it is not set, take
  # the settings from the fontcollection.
  attr_accessor :texenc

  # The fontmetric of the default font
  attr_accessor :defaultfm
  
  # If fontcollection is supplied, we are now part as the
  # fontcollection. You can set mapenc and texenc in the fontcollection
  # and don't bother about it here. Settings in a Font object will
  # override settings in the fontcollection.

  

  def initialize (fontcollection=nil)
    # we are part of a fontcollection
    @fontcollection=fontcollection
    # @defaultfm=FontMetric.new
    @variants=[]
    @dirs={}
    @origsuffix="-orig"
    @kpse=Kpathsea.new
    if fontcollection
      unless @fontcollection.respond_to?(:register_font)
        raise ArgumentError, "parameter does not look like a fontcollection"
      end
      @fontcollection.register_font(self)
    else
      # the default dirs
      set_dirs(Dir.getwd)
    end
  end
  

  # Read a font(metric file). Return a number that identifies the font.
  # The first font read is the default font. 
  def load_variant(fontname)
    fm=nil
    
    if fontname.instance_of? String
      case File.extname(fontname)
      when ".afm"
        fm=AFM.new
        fm.read(fontname)
      else
        raise ArgumentError, "Unknown filetype: #{File.basename(fontname)}"
      end
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
    
    fm.fontat=1   # default scale factor
    
    fontnumber
  end


  # change the metrics (and glyphs) of the default font so that
  # uppercase variants are mapped onto the lowercase variants.
  def fake_caps(fontnumber,capheight)
    raise ScriptError, "no font loaded" unless @defaultfm
    # first, make a list of uppercase and lowercase glyphs
    @defaultfm.chars.update_uc_lc_list
    v=@variants[fontnumber]
    v.fontat=capheight
    v.chars.fake_caps(capheight)
  end

  
  # Return PL (property list) object that represents the tfm file of
  # the font. enc is the encoding of the tfm file, which must be an
  # ENC object.
  def pl(enc)
    pl=PL.new(false)
    pl.family=@defaultfm.familyname
    pl.codingscheme=enc.encname
    pl.designsize=10.0
    pl.designunits=1000

    fd={}
    fd[:slant]=@defaultfm.slantfactor - @defaultfm.efactor * Math::tan(@defaultfm.italicangle * Math::PI / 180.0)
    fd[:space]=@defaultfm.space
    fd[:stretch]=@defaultfm.isfixedpitch ? 0 : 300
    fd[:shrink]=@defaultfm.isfixedpitch ? 0 : @defaultfm.transform(100,0)
    fd[:xheight]=@defaultfm.xheight
    fd[:quad]=@defaultfm.transform(1000,0)

    pl.fontdimen=fd
    enc.each_with_index{ |char,i|
      next if char==".notdef"
      thisglyph=@defaultfm.chars[char]
      next unless thisglyph
      glyphhash={}
      glyphhash[:comment]=char
      [:charwd, :charht, :chardp, :charic].each { |sym|
        glyphhash[sym]=thisglyph.send(sym)
      }
      pl[i]=glyphhash
    }
    pl
  end
  
  # Return a PL (virtual property list) object that represents a vf
  # file of the font. _mapenc_ and _texenc_ must be an ENC object.
  # _mapenc_ is the destination encoding (of the fonts in the mapfile)
  # and _texenc_ is is the encoding of the resulting tfm file. They
  # may be the same.
  
  def vpl(mapenc,texenc)
    
    raise ArgumentError, "mapenc must be an ENC object" unless mapenc.respond_to? :encname
    raise ArgumentError, "texenc must be an ENC object" unless texenc.respond_to? :encname
    @defaultfm.chars.fix_height(@defaultfm.xheight)
    
    vpl=PL.new(true)
    vpl.vtitle="Installed with rfi library"
    vpl.add_comment(" Please edit that VTITLE if you edit this file")
    vpl.family=@defaultfm.familyname
    vpl.codingscheme=mapenc.encname + " + " + texenc.encname
    vpl.designsize=10.0
    vpl.designunits=1000
    fm=@defaultfm
    fd={}
    fd[:slant]=fm.slantfactor - fm.efactor * Math::tan(fm.italicangle * Math::PI / 180.0)
    
    fd[:space]=fm.space
    fd[:stretch]=fm.isfixedpitch ? 0 : fm.transform(200,0)
    fd[:shrink]=fm.isfixedpitch ? 0 : fm.transform(100,0)
    fd[:xheight]=fm.xheight
    fd[:quad]=fm.transform(1000,0)
    fd[:extraspace]=fm.isfixedpitch ? fm.space : fm.transform(111,0)
    vpl.fontdimen=fd

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
    vpl.mapfont=map
    
    # now for the ligatures
    # we should ignore duplicate ligature/kern entries in the future!
    texenc.each_with_index  { |char,i|
      next if char == ".notdef"
      
      # ignore those not in dest 
      # next unless mapenc.glyph_index[char]
      next unless mapenc.glyph_index.include?(char)

      # next if this glyph is unknown
      next unless @defaultfm.chars[char]

      thischar=@defaultfm.chars[char]
      charentry={}

      # lig
      ligkern=PL::LigKern.new
      
      
      thischar.lig_data.each_value { |lig|
        if (texenc.glyph_index.has_key? lig.right) and
            (texenc.glyph_index.has_key? lig.result)
          if ligkern[:lig]
            ligkern[:lig].push lig
          else
            ligkern[:lig]=[lig]
          end
        end
      }

      # kern
      thischar.kern_data.each { |dest,kern|
        if (texenc.glyph_index.has_key? dest)
          texenc.glyph_index[dest].each { |slot|
            
            tmp=[slot,kern[0]]
            if ligkern[:krn]
              ligkern[:krn].push(tmp)
            else
              ligkern[:krn]=[tmp]
            end
          }
        end
      }

      if (ligkern[:krn] and ligkern[:krn].size!=0) or
          (ligkern[:lig] and ligkern[:lig].size!=0)
        charentry[:ligkern]=ligkern
      end
        
      
      # charinfo
      [:charwd, :charht, :chardp, :charic].each { |sym|
        charentry[sym]=thischar.send(sym)
      }

      # map
      mapneeded=(thischar.fontnumber != 0 or (mapenc.glyph_index[char].member?(i)==false))
      if mapneeded
        # destchar
        smallest = mapenc.glyph_index[char].inject { |memo,num|
          memo < num ? memo : num
        }
        charentry[:map]=[[:setchar,smallest]]
      end
      vpl[i]=charentry
    }
    
    return vpl
  end

  # Return a string or an array of strings that should be put in a mapfile.
  def maplines(options={})
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
        str << " #{@variants[f].fontname}"
        str << " <#{te.filename}" unless te.filename == "8a.enc"
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
  # shortcut if you are too lazy to program.
  
  def write_files(options={})

    
    tfmdir=get_dir(:tfm); ensure_dir(tfmdir)
    vfdir= get_dir(:vf) ; ensure_dir(vfdir)
    unless options[:mapfile]==false
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
          puts "writing tfm: #{tfmfilename}" 
        end
        unless options[:dryrun]==true
          pl(enc).write_tfm(tfmfilename)
        end
      }
    }

    # vf
    encodings=Set.new
    texenc.each { |te|
      encodings.add mapenc ? mapenc : te
    }
    texenc.each { |te|
      outenc = mapenc ? mapenc : te
      # vplfilename=File.join(vpldir,tex_fontname(te) + ".vpl")
      vffilename= File.join(vfdir, tex_fontname(te) + ".vf")
      tfmfilename=File.join(tfmdir,tex_fontname(te) + ".tfm")
      if options[:verbose]==true
        puts "vf: writing tfm: #{tfmfilename}"
        puts "vf: writing vf: #{vffilename}"
      end
      unless options[:dryrun]==true
        vpl(outenc,te).write_vf(vffilename,tfmfilename)
      end
    }

    unless options[:mapfile]==false
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

  def texenc=(enc) # :nodoc:
    @texenc=[]
    if enc
      set_encarray(enc,@texenc)
    end
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
        ret
      end
    end
  end

  # Return the full path to the mapfile.
  def mapfilename
    File.join(get_dir(:map),@defaultfm.name + ".map")
  end

  # Copy glyphs from one font to the default font. _fontnumber_ is the
  # number that is returned from load_variant, _glyphlist_ is whatever
  # you want to copy.
  # *needs testing*
  def copy(fontnumber,glyphlist)
    tocopy=[]
    case glyphlist
    when Symbol
      tocopy=@defaultfm.chars.foo(glyphlist)
    when Array
      tocopy=glyphlist
    end

    tocopy.each { |glyphname|
      # puts "copy #{glyphname}, fontnumberis #{fontnumber}"
      @defaultfm.chars[glyphname]=@variants[fontnumber].chars[glyphname]
      @defaultfm.chars[glyphname].fontnumber=fontnumber
      # @defaultfm.chars[glyphname].mapto=@defaultfm.chars[glyphname].uc
      # puts "copying #{glyphname}"
    }
    @defaultfm.chars['germandbls'].mapto=nil
  end

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

  # Return the name of the font in the mapline. 
  def map_fontname (texenc,varnumber=0)
    mapenc_loc=mapenc
    if mapenc_loc
      # use the one in mapenc_loc
      tex_fontname(mapenc,varnumber) + @origsuffix 
    else
      tex_fontname(texenc,varnumber) + @origsuffix
    end
  end
  
  def tex_fontname (texenc,varnumber=0)
    texencname=if texenc.filename
                texenc.filename.chomp(".enc").downcase
              else
                texenc.encname
              end
    fontname=@variants[varnumber].name
    # default
    if texencname == "8a"
      "#{fontname}"
    else
      "#{texencname}-#{fontname}"
    end
  end 

end
