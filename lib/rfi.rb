# rfi.rb -- general use classes
#
# Last Change: Thu Jul  7 20:37:27 2005


# This class contains methods and other classes that are pretty much
# useless of their own or are accessed in different classes.


class RFI

  # Some instructions to remove kerning information from digits and
  # other things. -> sort this out 
  STDLIGKERN = ["space l =: lslash",
    "space L =: Lslash", "question quoteleft =: questiondown",
    "exclam quoteleft =: exclamdown", "hyphen hyphen =: endash",
    "endash hyphen =: emdash", "quoteleft quoteleft =: quotedblleft",
    "quoteright quoteright =: quotedblright", "space {} *", "* {} space",
    "zero {} *", "* {} zero",
    "one {} *",  "* {} one",
    "two {} *",  "* {} two", 
    "three {} *","* {} three",
    "four {} *", "* {} four",
    "five {} *", "* {} five",
    "six {} *",  "* {} six",
    "seven {} *", "* {} seven",
    "eight {} *", "* {} eight",
    "nine {} *", "* {} nine",
    "comma comma =: quotedblbase",
    "less less =: guillemotleft",
    "greater greater =: guillemotright"]
  
  # Metric information about a glyph. Does not contain the glyph
  # (outlines) itself.
  class Char
    # Glyphname
    attr_accessor :name

    # Advance with
    attr_accessor :wx

    # Standard code slot (0-255 or -1 for unencoded)
    attr_accessor :c

    # bounding box (llx, lly, urx, ury). Array of size 4.
    # You should use the methods llx, lly, urx, ury to access the
    # bounding box.
    attr_accessor :b

    # Kern_data (Hash). The key is the glyph name, the entries are
    # _[x,y]_ arrays. For ltr and rtl typesetting only the x entry
    # should be interesting.
    attr_accessor :kern_data

    # Information about ligatures - unknown datatype yet
    attr_accessor :lig_data

    # Composite characters. Array [['glyph1',xshift,yshift],...]
    attr_accessor :pcc_data

    # Upper right x value of glyph.
    attr_accessor :urx
    
    # Upper right y value of glyph.
    attr_accessor :ury

    # Lower left x value of glyph.
    attr_accessor :llx

    # Lower left y value of glyph.
    attr_accessor :lly

    # fontnumber is used in Font class
    attr_accessor :fontnumber

    # mapto is glyphname that should be used instead of this one
    attr_accessor :mapto
    
    # the name of the uppercase glyph (nil if there is no uppercase glyph)
    attr_accessor :uc

    # the name of the lowercase glyph (nil if there is no lowercase glyph)
    attr_accessor :lc
    
    # Optional argument sets the name of the glyph.
    def initialize (glyphname=nil)
      @name=glyphname
      @lig_data={}
      @kern_data={}
      @wx=0
      @b=[0,0,0,0]
    end
    
    # Lower left x position of glyph.
    def llx            # :nodoc:
      @b[0]
    end                  
    def llx=(value)    # :nodoc:
      @b[0]=value
    end 

    # Lower left y position of glyph.
    def lly            # :nodoc:
      @b[1]
    end
    def lly=(value)    # :nodoc:
      @b[1]=value
    end 
    # Upper right x position of glyph.
    def urx            # :nodoc:
      @b[2]
    end
    def urx=(value)    # :nodoc:
      @b[2]=value
    end

    # Upper right y position of glyph.
    def ury            # :nodoc:
      @b[3]
    end
    def ury=(value)    # :nodoc:
      @b[3]=value
    end
    
    # Return height of the char used for tfm file.
    def charht
      ury
    end
    
    # Return width of the char used for tfm file.
    def charwd
      wx
    end
    
    # Return depth of the char used for tfm file.
    def chardp
      lly >= 0 ? 0 : -lly
    end
    
    # Return italic correction of the char used for tfm file.
    def charic
      (urx - wx) > 0 ? (urx - wx) : 0
    end
    # Return an array with all kerning information (x-direction only)
    # of this glyph. Kerning information is an Array where first
    # element is the destchar, the second element is the kerning amount.
    def x_kerns
      ret=[]
      @kern_data.each  { |destchar,kern|
        ret.push([destchar,kern[0]])
      }
      ret
    end
    
    # Return an array with all ligature information (LIG objects) of
    # this glyph.
    def ligs
      ret=[]
      @lig_data.each  { |destchar,lig|
        ret.push(lig)
      }
      ret
    end
    
    # Return true if this char has ligature or kerning information. If
    # glyphindex is supplied, only return true if relevant. This means
    # that the second parameter of a kerning information or the second
    # parameter and the result of a ligature information must be in
    # the glyphindex. glyphindex must respond to _include?_.
    def has_ligkern?(glyphindex=nil)
      if glyphindex and not glyphindex.respond_to? :include?
        raise ArgumentError, "glyphindex does not respod to include?"
      end
      return false if (lig_data == {} and kern_data=={})
      # this one is easy, just look at lig_data and kern_data
      # more complicated, we have to take glyphindex into account
      if glyphindex
        return false unless glyphindex.include? self.name
        # right kerningpair not in glyphindex? -> false
        # right lig not in glyphindex? -> false
        # result lig not in glyphindex? -> false
        if lig_data
          lig_data.each { |otherchar,lig|
            if (glyphindex.include?(lig.right) and glyphindex.include?(lig.result))
              return true
            end
          }
        end
        if kern_data
          kern_data.each { |otherchar,krn|
            return true if glyphindex.include?(otherchar)
          }
        end
        return false
      else
        # no glyphindex
        return true
      end
      raise "never reached"
    end # has_ligkern?

    # Return true if glyph is an uppercase char, such as AE. 
    def is_uppercase?
      return @lc != nil
    end

    # Return true if glyph is a lowercase char, such as germandbls,
    # but not hyphen.
    def is_lowercase?
      return @uc != nil
    end
    
    # Return the uppercase variant of the glyph. Undefined behaviour if
    # glyph cannot be uppercased. 
    def capitalize
      @uc
    end

    # Return the lowercase variant of the glyph. Undefined behaviour if
    # glyph cannot be lowercased.
    def downcase
      @lc
    end
  end # class Char


  # Represent the different ligatures possible in tfm.
  class LIG
    # First glyph of a two glyph sequence before it is turned into a
    # ligature.
    attr_accessor :left

    # Second glyph of a two glyph sequence before it is turned into a
    # ligature.
    attr_accessor :right

    # The ligature that gets inserterd instead of the left and right glyph.
    attr_accessor :result
    
    # <tt>[0,   1,    2,     3,    4,     5,     6,      7 ]</tt>
    #
    # <tt>[=: , |=: , |=:> , =:| , =:|>,  |=:|,  |=:|>,  |=:|>> ]</tt>
    #
    # <tt>[LIG, /LIG, /LIG>, LIG/, LIG/>, /LIG/, /LIG/>, /LIG/>>]</tt>
    attr_accessor :type

    def initialize(left,right,result,type)
      @left=left
      @right=right
      @result=result
      @type=type
    end
    def ==(lig)
      @left=lig.left and
        @right=lig.right and
        @result=lig.result and
        @type=lig.type
    end
    def inspect
      "(#{@type.to_s.upcase} #@right #@result)"
    end
  end

  

  # The Glyphlist is a actually a Hash with some special methods
  # attached.
  class Glyphlist < Hash
    @@encligops = ["=:", "|=:", "|=:>", "=:|", "=:|>", "|=:|", "|=:|>", "|=:|>>"]
    @@vpligops = ["LIG", "/LIG", "/LIG>", "LIG/", "LIG/>", "/LIG/",
      "/LIG/>", "/LIG/>>"]

    # return an array with name of glyphs that are represented by the
    # symbol _glyphlist_. Since I cannot think of a clever name,
    # please excuse this incredibly stupid name. If you have a
    # sensible name, just change it (and all references, of course).
    #
    # These symbols are defined: :lowercase, :uppercase, :digits
    def foo(glyphlist)
      ret=[]
      unless glyphlist.instance_of? Symbol
          raise ArgumentError, "glyphlist must be a symbol" 
      end
      case glyphlist
      when :lowercase
        update_uc_lc_list
        
        self.each { |glyphname,char|
          if char.uc != nil
            ret.push glyphname
          end
        }
      when :uppercase
        update_uc_lc_list
        
        self.each { |glyphname,char|
          if char.lc != nil
            ret.push glyphname
          end
        }
      when :digits
        ret=%w(one two three four five six seven eight nine zero)
      end
      ret
    end
    # instructions.each must yield string objects (i.e. an array of
    # strings, an IO object, a single string, ...). Instruction is like:
    # "space l =: lslash" or "two {} *"
    def apply_ligkern_instructions (instructions)
      instructions.each { |instr|
        s = instr.split(' ')
        if @@encligops.member?(s[2]) # one of =:, |=: |=:> ...
          self[s[0]].lig_data[s[1]]=LIG.new(s[0],s[1],s[3],@@encligops.index(s[2]))
        elsif s[1] == "{}"
          remove_kern(s[0],s[2])
        end
      }
    end
    # _left_ and _right_ must be either a glyphname or a '*'
    # (asterisk) which acts like a wildcard. So ('one','*') would
    # remove all kerns of glyph 'one' where 'one' is the left glyph in
    # a kerning pair.
    def remove_kern(left,right)
      raise ArgumentError, "Only one operand may be '*'" if left=='*' and right=='*'
      if right == "*"
        self[left].kern_data={}
      elsif left == "*"
        self.each { |name,chardata|
          chardata.kern_data.delete(right)
        }
      else
        self[left].kern_data.delete(right)
      end
    end
    
    # update all glyph entries to see what the uppercase or the
    # lowercase variants are
    def update_uc_lc_list
      # we need this list only when faking small caps (which will, of
      # course, never happen!)
      
      # make a list of all uppercase and lowercase glyphs. Be aware of
      # ae<->AE, oe<->OE, germandbls<-->SS, dotlessi->I, dotlessj->J
      # do the
      #      @upper_lower={}
      # @lower_upper={}
      self.each_key {|glyphname|
        thischar=self[glyphname]
        if glyphname =~ /^[a-z]/
          if glyphname =~ /^(a|o)e$/ and self[glyphname.upcase]
            thischar.uc = glyphname.upcase
          elsif glyphname =~ /^dotless(i|j)$/
            thischar.uc = glyphname[-1].chr.upcase
          elsif self[glyphname.capitalize]
            thischar.uc = glyphname.capitalize
          end
        else
          if glyphname =~ /^(A|O)e$/ and self[glyphname.dowcase]
            thischar.lc = glyphname.downcase
          elsif self[glyphname.downcase]
            thischar.lc = glyphname.downcase
          end
        end
      }
      if self['germandbls']
        c=RFI::Char.new('SS')
        c.fontnumber=0
        # metrics here!
        self['SS']=c
        self['germandbls'].uc='SS'
      end
    end

    # Modify the charmetrics and the kerning/ligatures so that the
    # lowercase chars are made from scaling uppercase chars.
    def fake_caps (factor)
      update_uc_lc_list
      # we need to do the following
      # 1. adapt kerning pairs
      # 2. change font metrics (wd)
      # 3. remove ligatures from sc
      @fake_caps=true
      @capheight=factor
      self.each { |glyphname,char|
        if char.is_lowercase?
          
          # remove ligatures from sc
          char.lig_data={}
          char.kern_data={}
          char.mapto=char.capitalize
          self[char.uc].kern_data.each { |destglyph,kerndata|
            unless self[destglyph].is_lowercase?
              char.kern_data[destglyph.downcase]=[kerndata[0] * factor,0]
            end
          }
          char.b = self[char.capitalize].b.clone
          char.wx = self[char.capitalize].wx * @capheight
          char.lly *= @capheight
          char.urx *= @capheight
          char.ury *= @capheight

        else # char is something like Aring, semicolon, ...
          # if destchar is uppercase letter (A, Aring, ...)
          # 1. delete all kerns to lowercase letters (not e.g. semicolon)
          # 2. duplicate all uc kerns, multiply by factor and insert this
          #    as lc kern
          char.kern_data.delete_if { |destglyph,kerndata|
            self[destglyph].is_lowercase?
          }

          new_kern_data={}
          char.kern_data.each { |destglyph,kerndata|
            if self[destglyph].is_uppercase?
              new_kern_data[self[destglyph].downcase]=[kerndata[0]*factor,kerndata[1]]
            end
            new_kern_data[destglyph]=kerndata
          }
          char.kern_data=new_kern_data
        end
        # 2.  
      }
      if self['germandbls']
        s=self['S']
        d=self['germandbls']
        d.b = s.b.dup
        d.wx = s.wx * 2 * @capheight
        d.urx += s.wx
        d.kern_data={}
        s.kern_data.each { |destglyph,kerndata|
          unless self[destglyph].is_lowercase?
            d.kern_data[self[destglyph].downcase]=[kerndata[0] * @capheight,0]
          end
        }
        
        # d.kern_data = s.kern_data.dup
        d.pcc_data=[['S',0,0],['S',s.wx,0]]
        d.lly *= @capheight
        d.urx *= @capheight
      end
    end # fake_caps

    def fix_height(xheight)
      # this is what afm2tfm does. I am not sure if it is clever.
      self.each { |name,data|
        
        # xheight <= 50  -> @chars[char].ury
        # char.size > 1  -> @chars[char].ury
        # char+accentname (ntilde, udieresis,...) exists?
        #   then calculate else @chars[char].ury
        # calculate := ntilde.ury - tilde.ury + xheight
        # same as texheight in afm2tfm source
        unless name.size>1 or xheight < 50
          %w(acute tilde caron dieresis).each {|accent|
            naccent=name + accent
            next unless self[naccent]
            data.ury = self[naccent].ury - self[accent].ury + xheight
            break
          }
        end
      }
    end # fix_height

  end # class Glyphlist
end


__END__
    # Return true if the char has ligature or kerning information
    # attached to it.
    # (It looks as if this method is not used. --> *REMOVE*!)
    def has_ligkern? (char)
      raise "Unknown glyph:" + char unless self[char]
      not (self[char].lig_data == {} and self[char].kern_data=={})
    end
    
