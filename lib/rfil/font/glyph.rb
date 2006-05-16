
module RFIL
  module Font
    class Glyph
      
      # to make Rdoc and Ruby happy: [ruby-talk:147778]
      def self.documented_as_accessor(*args) #:nodoc:
      end
      
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
      # should be interesting. This is raw information from the font
      # metric file. Does not change when efactor et al. are set in any
      # way. 
      attr_accessor :kern_data

      # Information about ligatures - unknown datatype yet
      attr_accessor :lig_data

      # Composite characters. Array [['glyph1',xshift,yshift],...]
      attr_accessor :pcc_data

      # Upper right x value of glyph.
      documented_as_accessor :urx
      
      # Upper right y value of glyph.
      documented_as_accessor :ury

      # Lower left x value of glyph.
      documented_as_accessor :llx

      # Lower left y value of glyph.
      documented_as_accessor :lly

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
        @efactor=1.0
        @slant=0.0
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
      
      # Return depth of the char.
      def chardp
        lly >= 0 ? 0 : -lly
      end
      
      # Return italic correction of the char.
      def charic
        (urx - wx) > 0 ? (urx - wx) : 0
      end
      # Return an array with all kerning information (x-direction only)
      # of this glyph. Kerning information is an Array where first
      # element is the destchar, the second element is the kerning amount.
      def kerns_x
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
      # the glyphindex. glyphindex must respond to <em>include?</em>.
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
    end
  end
end
