#--
# pl.rb - TeX Property List accessor class
# Last Change: Thu Jul 14 03:10:49 2005
#++
# See the PL class for a detailed description on its usage.

require 'set' 

require 'rfi'
FARRAY = ['MRR','MIR','BRR','BIR','LRR','LIR','MRC','MIC','BRC','BIC',
  'LRC','LIC','MRE','MIE','BRE','BIE','LRE','LIE'] 

#--
# @ligs
#   :comment
#   :krn
#   :lig
#   :alias
#++          

class PL
  include Enumerable

  # A plist contains Node objects.
  # An example Plist looks like this
  #  [#<PL::Node:0x2274ac @content=[""], @type=:vtitle>,
  #   #<PL::Node:0x2272cc @content=["UNSPECIFIED"], @type=:family>,
  #   #<PL::Node:0x226e58
  #   @content=[#<PL::Num:0x226d68 @type="F", @value=0>],
  #   @type=:face>
  #
  # and would look like when output by to_s:
  #  (VTITLE  )
  #  (FAMILY UNSPECIFIED)
  #  (FACE F MRR)
  class Plist < Array

    # Return a string representation of the plist with parenthesis, so
    # that the pltotf and vptovf programs can interpret the output.
    def to_s(level=0)
      tmp = level > 0 ? "\n" : ""
      self.each { |node|
        tmp << node.to_s(level)
      }
      tmp 
    end
  end



  # Number class for property lists. Numbers in pl are stored as 
  # _type_ _number_
  class Num
    # One of D,C,F,O,H,R,CO (decimal, char, ..., octal, hex, real)
    # CO means 'Char or Octal', if the value matches
    # <tt>/[[:alnum:]]/</tt> (a-z,A-Z,0-9), the value gets written out
    # as a character, else as an octal. Type only affects the
    # formatting when used with to_s
    attr_accessor :type

    # The numeric value 
    attr_accessor :value

    # You can supply the value or the type, or otherwise set them
    # later. If type is not set, try to guess.
    def initialize (value=nil,type=nil)
      if type
        @value=value
        # char or octal, depending on value
        if type == "CO"
          if value.chr =~ Regexp.new(/[[:alnum:]]/)
            @type="C"
          else
            @type="O"
          end
        else
          @type=type
          @value=value
        end
      else
        if value
          # guess type
          @value=value
          if value.instance_of? Float
            @type="R"
          elsif value.instance_of? Fixnum
            @type="D"
          end
        end
      end
    end

    # Format the value so that the standard TeX tools can parse them
    # Example: 'D 10' means decimal 10.
    def to_s
      raise "unknown type" unless @type
      @type + " " + 
        case @type
        when "D" 
          @value.to_s
        when "C"
          @value.chr
        when "F"
          FARRAY[@value]
        when "O"
          sprintf("%o",@value)
        when "H" 
          sprintf("%x",@value)
        when "R"
          @value.to_s
        else
          raise "unknown type in numeric"
        end
    end
  end


  
  # A node contains an array of plists, strings and/or numericals.
  # It is always part of a Plist.
  class Node
    # _type_ is the name of the node (e.g. :designsize)
    attr_accessor :type

    # _contents_ is an array 
    attr_accessor :contents

    def initialize (type,*contents)
      @type = type
      @contents=contents
    end
    
    # Set the contents of the Node. Allowed values are a Plist, a
    # String or a Num.
    def value= (value)
      @contents = [value]
    end
    
    # Add a Plist, a String or a Num to the node's contents
    def push (elt)
      @contents.push(elt)
    end
    
    # Iterator over the Node
    def each (&block)
      @contents.each(&block)
    end

    # Format the Node with _(_ and _)_ and indentation, so that the
    # pltotf and vptovf programs can interpret the output.
    def to_s(level=0)
      tmp = "   "*level + "("  + @type.to_s.upcase
      @contents.each { |elt| 
        if elt.kind_of? Plist
          tmp << elt.to_s(level+1)
          tmp << "   " * (level+1)
        else
          tmp << " " + elt.to_s
        end
      }
      tmp << ")\n"
      tmp
    end
  end # class node

  require 'forwardable'

  # Stores information about kerning and ligature information. Allows
  # deep copy of ligature and kerning information.
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
      obj.each { |key,value|
        return false unless @h[key]==value
      }
      true
    end
  end

  # to make Rdoc and Ruby happy: [ruby-talk:147778]
  def self.documented_as_accessor(*args)  #:nodoc:
  end
  
  # The scale factor for most of the numbers in the property list.
  # One em is divided into _designunits_ units.
  documented_as_accessor :designunits

  # The top plist of the property list. Do not use this in your
  # program, unless you know what you do. Messing with it will not
  # affect the internal cache.
  attr_accessor :plist

  # Internal ligkern cache. Dont't mess with it unless you know what
  # you are doing. 
  attr_reader :ligs

  # Internal char hash. Don't touch.
  attr_reader :chars
  
  # The family entry for the vf (used??)
  documented_as_accessor :family

  # The vtitle entry for the vf 
  documented_as_accessor :vtitle

  # the codingscheme of the pl
  documented_as_accessor :codingscheme

  # the designsize
  documented_as_accessor :designsize

  # Array of the mapfont section in the vpl. Each element is a hash
  # where key is :fontname and alike and each value is, guess what,
  # the value of that node.
  documented_as_accessor :mapfont

  # The fondimen section. This is a hash where the keys are one of
  # :slant,:space,:stretch,:shrink,:xheight,:quad,:extraspace. The
  # values are numbers.
  documented_as_accessor :fontdimen
  
  # A hash where each key is the index of the glyph (encoding
  # specific!) and the value is an array of two arrays: a kern and a
  # lig array. The kern array looks like: [[17, 24],[18, 24],[12,
  # 15]], so the first element is the destination slot and the second
  # element is the kern amount. The lig array looks similar, where the
  # first element denotes the next glyph and the second the
  # resulting glyph. Note that the lig array will change and use LIG
  # elements to handle more complex ligatures.
  documented_as_accessor :ligtable

  # If <em>is_vpl</em> is set to true, we assume that a virtual
  # property list for a virtual font should be generated.
  def initialize(is_vpl=false)
    @is_vpl=is_vpl
    @plist=Plist.new
    @chars=Array.new(256)
    @ligs=Array.new(256)
  end
  # Return a hash 
  def [] (i)
    
    return nil unless @chars[i]
    ret={}
    [:comment,:charwd,:charht,:charic,:chardp,:map].each { |sym|
      if @chars[i][sym]
        ret[sym] = @chars[i][sym]
      end
    }
    return ret unless @ligs[i]
    ret[:ligkern]=LigKern.new
    case @ligs[i]
    when Fixnum
      # n is now the slot where the real ligs are defined
      n=@ligs[i]

      # Tell the user that we give him some other ligkern informatio
      ret[:ligalias]=n

      # return the ligs and kern from the 'real' slot (if present)
      if @ligs[n][:lig]
        newligs=@ligs[n][:lig].collect { |lig|
          newlig=RFI::LIG.new(lig)
          newlig.left=i
          newlig
        }
        ret[:ligkern][:lig]=newligs
      end
      if @ligs[n][:krn]
        ret[:ligkern][:krn]=@ligs[n][:krn].dup
      end
    when LigKern
      ret[:ligkern]=@ligs[i].dup
    else
      raise "unknown class:" + @ligs[i].class.to_s
    end
    return ret
  end

  # Sets the charentry and the ligtable according to the information
  # in _value_. _value_ is a hash, with the following keys:
  # [:comment] is a ignored additional information
  # [:charwd] one value allowed: the width of the char
  # [:charht] one value allowed: the height of the char
  # [:chardp] one value allowed: the depth of the char
  # [:charic] one value allowed: the italic correction of the char
  # [:ligkern] Two arrays or a Fixnum. If Fixnum, then the ligkern
  # section in the ligtable is the same as the one denoted by the
  # Fixnum. If arrays:  the first array is the lig array (LIG objects),
  # the second array is the kern ([destchar, amount]) array.
  def []= (i,value)

    # if we nil out i, perhaps we have to remove all lig aliases? FIXME
    @chars[i]={}
    [:comment,:charwd,:charht,:charic,:chardp,:map].each { |sym|
      @chars[i][sym]=value[sym]
    }

    # defining an alias for ligkern: you can either set :ligalias to a
    # Fixnum or have :ligkern
#    puts "pl#[]= value[:ligalias]=#{value[:ligalias]}"
#    puts "pl#[]= value[:ligkern]=#{value[:ligkern]}"
    if n = (value[:ligalias] or 
              value[:ligkern].instance_of?(Fixnum) ? value[:ligkern] : nil)
#      puts "pl#[]= n=#{n}"

      # alias is fine, but an alias to nil is of no use
      return value if @ligs[n]==nil
      
      unless @ligs[n].instance_of? LigKern
        raise  "@ligs[#{n}] is of wrong class: #{@ligs[n].class}. Should be LigKern"
      end
      # set the alias in the @ligs table (current slot)
      @ligs[i]=n
      # now set it the alias slot
      unless @ligs[n].has_key?(:alias)
#        puts "pl#[]=: calling Set.new"
        @ligs[n][:alias]=Set.new()
      end
 #     puts "pl#[]=: calling add #{n}"
      @ligs[n][:alias].add(i)
      
    elsif lk=value[:ligkern]
      # no aliases found, use normal ligkern op
      unless @ligs[i]
        @ligs[i]=LigKern.new
      end
      @ligs[i]=lk.dup
    else
      # no alias and no :ligkern, do nothing
    end
    return value
  end

  


  # Nice (+vptovf+ and +pltotf+ compatible) output of the complete
  # property list.
  def to_s
    update_plist
    @plist.to_s
  end

  def add_comment(comment)
    @plist << Node.new(:comment,comment)
  end
  
  def designunits # :nodoc:
    if n=find_node(:designunits)
      n.contents[0].value
    else
      nil
    end
  end
  def designunits=(du) #:nodoc:
    # is the following correct?
    if du != 1
      @plist.push Node.new(:designunits,PL::Num.new(du,"R"))
    end
  end
  
  def fontdimen(raw=false) # :nodoc:
    n = @plist.find { |node|
      node.type==:fontdimen
    }
    return n if raw
    ret={}
    n.contents[0].each { |fd|
      ret[fd.type]=fd.contents[0].value
    }
    ret
  end
  def fontdimen=(fd)  # :nodoc:
    subplist=Plist.new
    [:slant,:space,:stretch,:shrink,:xheight,:quad,:extraspace].each {|sym|
      if fd[sym] and fd[sym] != 0
        subplist.push Node.new(sym,Num.new(fd[sym]))
      end
    }
    insert_or_change(:fontdimen,subplist)
  end

  # Return the mapfont section of the vpl. Array of mapfonts. If _raw_
  # is true, return the internal structure of the mapfont entries
  def mapfont(raw=false) # :nodoc:
    ret=[]
    n = @plist.find_all { |node|
      node.type==:mapfont
    }
    if raw
      return n
    end
    n.each { |mapfontnode|
      mapfonth={}
      # fontnumber:
      c=mapfontnode.contents
      ret[c[0].value]=mapfonth 
      subnodes=c[1]
      subnodes.each { |subnode|
        if subnode.contents[0].instance_of?(Num)
          mapfonth[subnode.type]=subnode.contents[0].value
        else
          mapfonth[subnode.type]=subnode.contents[0]
        end
      }
    }
    ret
  end
  # Input is an array of mapfont entries. For each element of the
  # array there will be a mapfont section in the vpl file. 
  def mapfont=(entries)  # :nodoc:
    nodes = @plist.find_all { |node|
      node.type == :mapfont
    }
    # remove all mapfont entries
    if nodes
      nodes.each { |node|
        @plist.delete(node)
      }
    end
    entries.each_with_index { |entry,i|
      subplist=Plist.new
      [:fontname].each {|sym|
        if entry[sym]
          subplist.push(Node.new(sym,entry[sym]))
        end
      }
      [:fontat].each { |sym|
        if entry[sym] and entry[sym] != 1000
          subplist.push(Node.new(sym,Num.new(entry[sym])))
        end
      }
      
      [:fontdsize, :fontchecksum].each { |sym|
        if entry[sym] and entry[sym] != 0
          subplist.push(Node.new(sym,Num.new(entry[sym])))
        end
      }
      @plist.push(Node.new(:mapfont,Num.new(i),subplist))
    }
  end

  def ligtable  # :nodoc:
    return nil unless @ligs
    ret={}
    @ligs.each_with_index{ |ligkern,i|
      next unless ligkern
      ret[i] = if ligkern.instance_of?(Fixnum)
                 @ligs[ligkern].dup
               else
                 ligkern
               end
      #ret[i] = ligkern.instance_of?(Fixnum) ? ligkern : ligkern.dup
    }
    return ret
  end

  # Set the ligtable to the _lighash_. _lighash_ has the same format
  # that results from ligtable.
  def ligtable=(lighash) # :nodoc:
    0.upto(255) { |i|
      if lighash[i]
        @ligs[i]= lighash[i].instance_of?(Fixnum) ? lighash[i] : lighash[i].dup
      else
        @ligs[i]=nil
      end
    }
    # Let's be nice and return something sensible.
    lighash
  end
  
  # Write out a tfm-file for the current pl. _tfmlocation_ is a full
  # path to the to be created tfm file. The directory must be
  # writable.
  def write_tfm(location)
    update_plist
    require 'tempfile'
    tmpfile = Tempfile.new("afm2tfm.rb")
    tmpfile << @plist.to_s
    tmpfile.close
    system("pltotf #{tmpfile.path} #{location} > /dev/null")
    raise ScriptError unless $?.success?
  end

  # Write out a tfm-file and a vf file for the current vpl.
  # _vflocation_ and _tfmlocation_ are full paths to the to be created
  # vf file and tfm file. The directories must be writable.
  def write_vf(vflocation,tfmlocation)
    update_plist
    require 'tempfile'
    tmpfile = Tempfile.new("afm2tfm.rb")
    tmpfile << @plist.to_s
    tmpfile.close
    system("vptovf #{tmpfile.path} #{vflocation} #{tfmlocation} > /dev/null")
    raise ScriptError, "error running vptovf" unless $?.success?
  end

  def vtitle=(title)       #:nodoc:
    insert_or_change(:vtitle,title)
  end
  def vtitle                #:nodoc:
    n=find_node(:vtitle)
    return nil unless n
    n.contents[0]
  end
  def family=(title)        #:nodoc:
    insert_or_change(:family,title)
  end
  def family                #:nodoc:
    n=find_node(:family)
    return nil unless n
    n.contents[0]
  end
  def codingscheme=(title)   #:nodoc:
    insert_or_change(:codingscheme,title)
  end
  def codingscheme           #:nodoc:
    n=find_node(:codingscheme)
    return nil unless n
    n.contents[0]
  end
  
  def designsize=(num)       #:nodoc: 
    insert_or_change(:designsize,designsize=PL::Num.new(num))
  end
  def designsize             #:nodoc:
    n = find_node(:designsize)
    return nil unless n
    n.contents[0].value
  end


  # Set the ligtable to _plist_. 
  def set_ligtable(plist)  # :nodoc:
    insert_or_change(:ligtable,plist)
  end
  # obsolete, at least for now :)
  def get_charentries # :nodoc:
    ret=Array.new
    @chars.each_with_index {|char,i|
      if char
        c=char.dup
        c[:slot]=i
        ret.push(c)
      end
    }
    return ret
  end
 

  private

  # there are two states we are in:
  # 1) @plist is up to date (just parsed) and the cache is not
  # 2) our cache is fine, but @plist is not updated

  # going from one state to the other is rather expensive, we should
  # not do this over and over again. So there are two ways to get from
  # 1) to 2) and back: update_cache (1->2) and update_plist (2->1).
  # Enjoy.
  

  # Before we use to_s or write_tfm/write_vpl, we have to make sure
  # that the plist is updated.
  def update_plist
    # first delete the ligtable and the char list
    @plist.delete_if { |node|
      node.type==:ligtable or node.type==:character
    }
    ligplist=Plist.new
    @ligs.each_with_index { |lighash,i|
      next unless lighash
      # ligentry is at some other position
      next if lighash.instance_of?(Fixnum)

      labels=[i]
      if lighash[:alias]
        lighash[:alias].each { |otherpos|
          labels.push(otherpos)
        }
      end
      labels.sort.each { |l|
        ligplist << PL::Node.new(:label,PL::Num.new(l,"CO"))
      }
      
      if lighash[:krn]
        lighash[:krn].each { |kern|
          ligplist << PL::Node.new(:krn,PL::Num.new(kern[0],"CO"),
                                   PL::Num.new(kern[1]))
        }
      end
      if lighash[:lig]
        lighash[:lig].each { |lig|
          ligplist << PL::Node.new(lig.type.to_s,PL::Num.new(lig.right,"CO"),
                                   PL::Num.new(lig.result,"CO"))
        }
      end
      ligplist << PL::Node.new(:stop)
    }
    @plist.push Node.new(:ligtable,ligplist)
    # and now for the charlist
    @chars.each_with_index {|char,i|
      next unless char
      subplist=Plist.new
      [:charwd, :charht, :chardp, :charic].each { |sym|
        if char[sym] and (char[sym] != 0)
          subplist << Node.new(sym, Num.new(char[sym]))
        end
      }
      if char[:map]
        mapplist=Plist.new
        char[:map].each { |instruction|
          sym=instruction[0]
          case sym
          when :setchar, :selectfont
            mapplist.push Node.new(sym,Num.new(instruction[1]))
          else
            raise "unknown instruction"
          end
        }
        subplist.push Node.new(:map,mapplist)
      end
      
      @plist.push Node.new(:character,Num.new(i,"CO"),subplist)
    }
    
  end

  # Find the first occurance of node of type _nodetype_ in main plist.
  # Returns a node.
  def find_node(nodetype)
    @plist.find { |node|
      node.type==nodetype
    }
  end

  def insert_or_change (type, value)
    n = @plist.find { |node|
      node.type==type
    }
    if n
      n.value=value
    else
      @plist.push Node.new(type,value)
    end
  end

  def _round(value) # should be named 'remove .0' or alike
    if value.round - value != 0
      value
    else
      value.round
    end
  end

end
__END__
