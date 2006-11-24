# rfi.rb -- general use classes
#--
# Last Change: Tue May 16 19:21:51 2006
#++

require 'rfil/font/glyph'

module RFIL # :nodoc: 

  # = RFI
  # Everything that does not fit somewhere else gets included in the
  # wrapper class RFI.
  
  # This class contains methods and other classes that are pretty much
  # useless of their own or are accessed in different classes.
  
  class RFI # :nodoc:
    
    # Super class for plugins. Just subclass this Plugin, set the name
    # when calling Plugin#new and implement run_plugin.
    class Plugin
      # Name of the plugin. A Symbol or a String.
      attr_reader :name

      attr_reader :filetypes
      
      # Create a new plugin. _name_ is the name of the plugin (it must
      # be a Symbol or a String). _filetypes_ is a list of symbols, of
      # what files the plugin is capable of writing.
      def initialize(name,*filetypes)
        @name=name
        @filetypes=filetypes
      end
      
      # Return an Array of files that should be written on the user's
      # harddrive. The Hash entries are
      # [<tt>:type</tt>] Type of the file (<tt>:fd</tt>, <tt>:typescript</tt> etc.)
      # [<tt>:filename</tt>] The filename (without a path) of the file.
      # [<tt>:contents</tt>] The contents of the file.
      def run_plugin
        #dummy
      end
    end
    
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
    class Char < Font::Glyph
      
      # fontnumber is used in Font class
      attr_accessor :fontnumber

      # If not nil, _mapto_ is the glyphname that should be used instead
      # of the current one.
      attr_accessor :mapto
      
      # Sets the extension factor. This is used by calculations of _wx_,
      # _llx_ and _urx_.
      attr_accessor :efactor

      # Sets the slant factor. This is used by calculations of _wx_,
      # _llx_ and _urx_.
      attr_accessor :slant

      def wx       # :nodoc:
        transform(@wx,0)
      end
      def wx=(obj) # :nodoc:
        @wx=obj
      end
      # Lower left x position of glyph.
      def llx            # :nodoc:
        transform(@b[0],b[1])
      end                  

      # Upper right x position of glyph.
      def urx            # :nodoc:
        transform(@b[2],ury)
      end
      
      private

      def transform (x,y)
        (@efactor * x + @slant * y)
      end

    end # class Char

    
    # Represent the different ligatures possible in tfm.
    class LIG
      
      @@encligops = ["=:", "|=:", "|=:>", "=:|", "=:|>", "|=:|", "|=:|>", "|=:|>>"]
      @@vpligops = ["LIG", "/LIG", "/LIG>", "LIG/", "LIG/>", "/LIG/",
                    "/LIG/>", "/LIG/>>"]
      @@symligops = [:lig, :"lig/",  :"/lig",  :"/lig/", :"lig/>", :"/lig>", :"/lig/>", :"/lig/>>"]

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

      
      
      # call-seq:
      #   new
      #   new(left,[right,[result,[type]]])
      #   new(hash)
      #   new(otherlig)
      # 
      # When called with left, right, result or type parameters, take
      # these settings for the LIG object. When called with a hash as an
      # argument, the keys should look like: :left,:right,:result,:type.
      # When called with an existing LIG object, the values are taken
      # from the old object.
      def initialize(left=nil,right=nil,result=nil,type=nil)
        case left
        when Hash
          [:left,:right,:result,:type].each { |sym|
            if left.has_key?(sym)
              self.send((sym.to_s+"=").to_sym,left[sym])
            end
          }
        when LIG
          [:left,:right,:result,:type].each { |sym|
            self.send((sym.to_s+"=").to_sym,left.send(sym))
          }
          # warning!!!!! LIG accepts a String as well as Fixnum as
          # parameters, this might have side effects!?
        when Fixnum,nil,String
          @left=left
          @right=right
          @result=result
          @type=type
        else
          raise "unknown argument for new() in LIG: #{left}"
        end
        # test!
        #unless @type.instance_of?(Fixnum)
        #  raise "type must be a fixnum"
        #end
      end
      def ==(lig)
        @left=lig.left and
          @right=lig.right and
          @result=lig.result and
          @type=lig.type
      end

      def to_pl(encoding)
        encoding.glyph_index[@right].sort.collect { |rightslot|
          left=encoding.glyph_index[@left].min
          # right=encoding.glyph_index[@right].min
          result=encoding.glyph_index[@result].min
          type=@@vpligops[@type]
          LIG.new(:left=>left, :right=>rightslot, :result=>result, :type=>type)
        }
      end
      # Return an array that is suitable for tfm
      def to_tfminstr(encoding)
        encoding.glyph_index[@right].sort.collect { |rightslot|
          left=encoding.glyph_index[@left].min
          # right=encoding.glyph_index[@right].min
          result=encoding.glyph_index[@result].min
          type=@@symligops[@type]
          [type,rightslot,result]
        }
      end
      def inspect
        "[#{@type.to_s.upcase} #@left + #@right => #@result]"
      end
    end
    
    require 'forwardable'

    # Stores information about kerning and ligature information. Allows
    # deep copy of ligature and kerning information. Obsolete. Don't use.
    class LigKern
      extend Forwardable
      # Optional parameter initializes the new LigKern object.
      def initialize(h={})
        @h=h
      end
      
      def_delegators(:@h, :each, :[], :[]=,:each_key,:has_key?)
      
      def initialize_copy(obj) # :nodoc:
        tmp={}
        if obj[:lig]
          tmp[:lig]=Array.new
          obj[:lig].each { |elt|
            tmp[:lig].push(elt.dup)
          }
        end
        if obj[:krn]
          tmp[:krn]=Array.new
          obj[:krn].each { |elt|
            tmp[:krn].push(elt.dup)
          }
        end
        if obj[:alias]
          tmp[:alias]=obj[:alias].dup
        end
        @h=tmp
      end
      # Compare this object to another object of the same class.
      def ==(obj)
        return false unless obj.respond_to?(:each)
        # the krn needs to be compared one by one, because they are floats
        if obj.has_key?(:krn)
          obj[:krn].each { |destchar,value|
            return false unless @h[:krn].assoc(destchar)
            return false if (value - @h[:krn].assoc(destchar)[1]).abs > 0.01
          }
        end
        obj.each { |key,value|
          next if key==:krn
          return false unless @h[key]==value
        }
        true
      end
    end

    
    # The Glyphlist is a actually a Hash with some special methods
    # attached.
    class Glyphlist < Hash
      @@encligops = ["=:", "|=:", "|=:>", "=:|", "=:|>", "|=:|", "|=:|>", "|=:|>>"]
      @@vpligops = ["LIG", "/LIG", "/LIG>", "LIG/", "LIG/>", "/LIG/",
                    "/LIG/>", "/LIG/>>"]

      # Return an array with name of glyphs that are represented by the
      # symbol _glyphlist_.
      # These symbols are defined: :lowercase, :uppercase, :digits
      def get_glyphlist(glyphlist)
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
            if self[s[0]]
              self[s[0]].lig_data[s[1]]=LIG.new(s[0],s[1],s[3],@@encligops.index(s[2]))
            else
              # puts "glyphlist#apply_ligkern_instructions: char not found: #{s[0]}"
            end
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
          self[left].kern_data={} if self[left]
        elsif left == "*"
          if self[right]
            self.each { |name,chardata|
              chardata.kern_data.delete(right)
            }
          end
        else
          if self[right] and self[left]
            self[left].kern_data.delete(right)
          end
        end
      end
      
      # Update all glyph entries to see what the uppercase or the
      # lowercase variants are. Warning!! Tcaron <-> tquoteright in
      # non-unicode fonts.
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
          self['germandbls'].uc='S'
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
              # we are looking at non-lowercase chars. These might be
              # ones that are uppercase or are 'something else', e.g.
              # hyphen...
              # since we only replace the lc variants, keep the uc and
              # others intact.
              if self[destglyph].is_uppercase? 
                d.kern_data[self[destglyph].downcase]=[kerndata[0] * @capheight,0]

              else
                d.kern_data[destglyph]=[kerndata[0] * @capheight,0]
                
              end
            end
          }
          
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
              next unless self[accent] # they don't exist in all cases
              naccent=name + accent
              next unless self[naccent]
              data.ury = self[naccent].ury - self[accent].ury + xheight
              break
            }
          end
        }
      end # fix_height
    end # class Glyphlist
  end # class RFI
end
