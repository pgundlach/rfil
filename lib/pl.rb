# pl.rb - TeX Property List accessor class
#
# Last Change: Thu Jul  7 21:57:08 2005

require 'rfi'

FARRAY = ['MRR','MIR','BRR','BIR','LRR','LIR','MRC','MIC','BRC','BIC',
  'LRC','LIC','MRE','MIE','BRE','BIE','LRE','LIE'] 

# Represents a property list. You can get a nicely formatted property
# list with the to_s method. 
#
# There are entries that may appear only once in a pl file, such as
# _vtitle_ or _fontdimen_ and there are others that can appear
# anywhere, such as _comment_. The << method adds an entry that may
# appear in any place, while methods such as fontdimen= replace old
# entries if necessary (not implemented yet). Class methods create a
# Node that may be used by the << method. Example:
#
#  pl = Plist.new
#  pl << PL.comment("this is a comment")
#
# adds a comment at the top of the plist.

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
          # puts value.to_s
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


  # The top plist of the property list. 
  attr_accessor :plist

  # The family entry for the vf (used??)
  attr_accessor :family

  # The vtitle entry for the vf 
  attr_accessor :vtitle

  # the codingscheme of the pl
  attr_accessor :codingscheme

  # the designsize
  attr_accessor :designsize

  # A hash where each key is the index of the glyph (encoding
  # specific!) and the value is an array of two arrays: a kern and a
  # lig array. The kern array looks like: [[17, 24],[18, 24],[12,
  # 15]], so the first element is the destination slot and the second
  # element is the kern amount. The lig array looks similar, where the
  # first element denotes the next glyph and the second the
  # resulting glyph. Note that the lig array will change and use LIG
  # elements to handle more complex ligatures.
  attr_accessor :ligtable
  
  # Return a new Node representing a comment with contents of _comment_.
  def PL.comment (comment)
    Node.new(:comment,comment)
  end

  # Return a new Node <tt>(STOP)</tt>
  def self.stop
    Node.new(:stop)
  end
  
  # Return a new Node <tt>(LABEL </tt> _num_<tt>)</tt>
  def PL.label (num)
    PL::Node.new(:label,PL::Num.new(num,"D"))
  end
  
  # Return a new Node <tt>(LIG </tt> _i_ _result_<tt>)</tt>, where _i_
  # is the slot of the second glyph in the ligature and _result_ is
  # the slot of the resulting ligature. *warning:* this method will
  # change to reflect the 8 different kind of ligatures possible in
  # TeX. 
  def PL.lignode(i,result)
    PL::Node.new(:lig,PL::Num.new(i,"CO"),PL::Num.new(result,"CO"))
  end

  # Return a new Node <tt>(KRN </tt> _slot_ _value_<tt>)</tt>, where
  # _slot_ is the slot of the second glyph in the kerning pair and
  # _value_ is the amount of adjustment (0=no adjustment).
  def PL.kernnode (slot,value)
    PL::Node.new(:krn,PL::Num.new(slot,"D"),PL::Num.new(value))
  end

  # If <em>is_vpl</em> is set to true, we assume that a virtual
  # property list for a virtual font should be generated.
  def initialize(is_vpl=false)
    @is_vpl=is_vpl
    @plist=Plist.new
    @co="CO"
  end
  # Sets the charentry and the ligtable according to the information
  # in _value_. _value_ is a hash, with the following keys:
  # [:comment] is a ignored additional information
  # [:charwd] one value allowed: the width of the char
  # [:charht] one value allowed: the height of the char
  # [:chardp] one value allowed: the depth of the char
  # [:charic] one value allowed: the italic correction of the char
  # [:lig] an array of LIG objects.
  # [:krn] an array of arrays like [destchar, amount].
  def []= (charnumber,value)
    lt=ligtable
    lt[charnumber]=[value[:krn],value[:lig]]
    # why do I need self here?
    self.ligtable=(lt)
    # build node
    n = @plist.find {|node|
      node.type==:character and node.contents[0].value==charnumber
    }
    unless n
      n = Node.new(:character)
      # todo: find the correct place to insert the char
      @plist << n
    end
    n.value=Num.new(charnumber,"CO")
    subplist=Plist.new
    [:charwd, :charht, :chardp, :charic].each { |sym|
      if value[sym]
        subplist << Node.new(sym, Num.new(value[sym]))
      end
    }
    n.push subplist
    value
  end

  # Return a hash 
  def [] (charnumber)
    a = @plist.find {|node|
      node.type==:character and node.contents[0].value==charnumber
    }
    return nil unless a
    a=a.contents[1]
    ret={}
    comment=""
    a.each { |node|
      case node.type
      when :comment
        comment << node.contents[0]
        ret[:comment]=comment
      when :charwd,:charht,:charic,:chardp
        ret[node.type]=node.contents[0].value
      end
    }
    lt=ligtable[charnumber]
    if lt
      ret[:krn]=lt[0]
      ret[:lig]=lt[1]
    end
    ret
  end
  
  # Add Node _node_ to the top property list.
  def <<(node)
    @plist << node
  end


  # Nice (+vptovf+ and +pltotf+ compatible) output of the complete
  # property list.
  def to_s
    @plist.to_s
  end

  
  def fontat (num)
    PL::Node.new(:fontat,PL::Num.new(num))
  end

  
  def designunits=(du)
    @pl_designunits=du
    @pl_factor=(du/1000.0)
    # is the following correct?
    if du != 1
      @plist.push Node.new(:designunits,PL::Num.new(@pl_designunits,"R"))
    end
  end
  
  def fontdimen
    n = @plist.find { |node|
      node.type==:fontdimen
    }
    ret={}
    n.contents[0].each { |fd|
      ret[fd.type]=fd.contents[0].value
    }
    ret
  end
  def fontdimen=(fm)
    # incorrect. use global data in Font
    subplist=Plist.new
    # slant
    n = fm.slantfactor - fm.efactor * Math::tan(fm.italicangle * Math::PI / 180.0)
    subplist.push Node.new(:slant,Num.new(n)) if n != 0

    # space
    space = _round(fm.chars['space'].wx * @pl_factor)
    subplist.push Node.new(:space,Num.new(space))

    # stretch
    s = @is_vpl ?  fm.transform(200,0) : 300
    n=_round(fm.isfixedpitch ? 0 : s * @pl_factor )
    subplist.push Node.new(:stretch,Num.new(n))

    # shrink
    s = @is_vpl ? 100 : fm.transform(100,0)
    n=_round(fm.isfixedpitch ? 0 : fm.transform(100,0) * @pl_factor )
    subplist.push Node.new(:shrink,Num.new(n))

    # xheight
    n=_round(fm.xheight * @pl_factor)
    subplist.push Node.new(:xheight,Num.new(n))

    # quad
    n=_round(fm.transform(1000,0) * @pl_factor)
    subplist.push Node.new(:quad,Num.new(n))

    # extraspace
    if @is_vpl
      n=_round(fm.isfixedpitch ? space : @pl_factor * fm.transform(111,0))
      subplist.push Node.new(:extraspace,Num.new(n))
    end
    @plist.push(Node.new(:fontdimen,subplist))
  end

  # Create a slot that describes the metrics (and additional
  # information) of a glyph. _glyphname_ should be clear, _slot_ is
  # the position it maps to, _glyph_index_ is to check if a mapping is
  # needed, _allglyphs_ is a Glyphlist. _variants_ is an array with
  # all variants used, for example [0,1,3].
  def add_charentry (glyphname,slot,glyph_index,allglyphs)
    thisglyph=allglyphs[glyphname]
    mapnum=if thisglyph.mapto != nil
             glyph_index[thisglyph.mapto][0]
           else
             glyph_index[glyphname][0]
           end
    
    subplist=Plist.new
    fontnumber = @is_vpl ? @fontmapping.index(thisglyph.fontnumber) : 0

    # do I need a (MAP (...))?
    map_needed=((fontnumber != 0) or
                      (not glyph_index[glyphname].member?(slot))==true)

    subplist.push Node.new(:comment,glyphname)

    # charwd
    n=_round(thisglyph.charwd * @pl_factor)
    subplist.push Node.new(:charwd,Num.new(n,"R")) if n != 0

    # charht
    n=_round(thisglyph.charht * @pl_factor)
    subplist.push Node.new(:charht,Num.new(n,"R")) if n != 0
  
    # chardp
    n = _round(thisglyph.chardp * @pl_factor )
    subplist.push Node.new(:chardp,Num.new(n,"R")) if n != 0
  
    # charic
    n= _round(thisglyph.charic * @pl_factor)
    subplist.push Node.new(:charic,Num.new(n,"R")) if n != 0

    # p @variants[fontnumber].index(fontnumber)
    if map_needed
      mapplist=Plist.new
      if fontnumber != 0
        mapplist.push Node.new(:selectfont,Num.new(fontnumber))
      end
      mapplist.push Node.new(:setchar,Num.new(mapnum,"D"))
      subplist.push Node.new(:map,mapplist)
    end
    @plist.push(Node.new(:character,Num.new(slot,"D"),subplist))
  end
  
  def get_charentries
    ret=[]
    n = @plist.find_all { |node|
      node.type==:character
    }
    n.each { |node|
      h={}
      ret.push h
      h[:slot]=node.contents[0].value
      node.contents[1].each { |entry|
        # entry is Node of type charwd, ...
        case entry.type
        when :charwd, :charht, :chardp, :charic
          h[entry.type]=entry.contents[0].value
        when :map
          map=[]
          h[:map]=map
          subplist=entry.contents[0]
          subplist.each { |subnode|
            case subnode.type
            when :setchar
              map.push [:setchar,subnode.contents[0].value]
            end
          }
        else
          # unknown
        end
      }
    }
    ret
  end

  # Variants is an array like [FontMetric0,nil,FontMetric2]
  def mapfont=(variants)
    @variants=variants
    # fontmapping would look like this in the example above: [0,2]. So
    # you can say @variants[2] to get the font that maps to fontnumber
    # 1. Stupid, isn't it?
    @fontmapping=[]
    @variants.each_with_index { |variant,index|
      next if variant == nil
      @fontmapping.push index
      
      subplist=Plist.new
      subplist.push(Node.new(:fontname,variant.mapto))
      if variant.fontat != 1
        fa = _round(variant.fontat * @pl_factor * 1000)
        subplist.push(Node.new(:fontat,Num.new(fa)))
      end
      @plist.push(Node.new(:mapfont,Num.new(index),subplist))
    }
  end

  # Return the mapfont section of the vpl. 
  def mapfont
    ret={}
    n = @plist.find_all { |node|
      node.type==:mapfont
    }
    n.each { |mapfontnode|
      mapfonth={}
      # fontnumber
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

  # Set the ligtable to _plist_. 
  def set_ligtable(plist)
    # @plist.push(Node.new(:ligtable,plist))
    insert_or_change(:ligtable,plist)
  end

  def ligtable  # :nodoc:
    ret = @plist.find { |node|
      node.type==:ligtable
    }
    return {} unless ret
    plist=ret.contents[0]
    # puts plist.to_s
    ret={}
    current_slots=[]
    krn=[]
    lig=[]
    current_charno=nil
    plist.each{ |node|
      case node.type
      when :label
        current_charno=node.contents[0].value
        current_slots.push current_charno
      when :krn
        krn.push [node.contents[0].value,node.contents[1].value]
      when :lig
        lig.push RFI::LIG.new(current_charno,
                              node.contents[0].value,
                              node.contents[1].value,
                              node.type)
      when :stop
        current_slots.each { |slot|
          ret[slot]=[krn,lig]
        }
        krn=[]
        lig=[]
        current_slots=[]
        current_charno=nil
      when :comment
        # ignore
      else
        raise "unknown type: #{node.type}"
      end
    }
    ret
  end

  # Set the ligtable to the _lighash_. _lighash_ has the same format
  # that results from ligtable.
  def ligtable=(lighash) # :nodoc:
    ligplist=Plist.new
    lighash.sort.each {|slot,ligentry|
      ligplist << PL.label(slot)
      krn,lig=ligentry
      #lig.sort {|a,b| a[0] <=> b[0] }.each { |other,result|
        # puts "kernnode: #{other}, #{amount}"
       # ligplist << PL.lignode(other,result)
     # }
      lig.each { |lig|
        ligplist << PL.lignode(lig.right,lig.result)
      }
      krn.sort {|a,b| a[0] <=> b[0] }.each { |other,amount|
        # puts "kernnode: #{other}, #{amount}"
        ligplist << PL.kernnode(other,amount)
      }
      ligplist << PL.stop
    }
    # puts ligplist.to_s
    set_ligtable(ligplist)
    lighash
  end
  
  # Write out a tfm-file for the current pl. _tfmlocation_ is a full
  # path to the to be created tfm file. The directory must be
  # writable.
  def write_tfm(location)
    require 'tempfile'
    tmpfile = Tempfile.new("afm2tfm.rb")
    tmpfile << plist.to_s
    tmpfile.close
    system("pltotf #{tmpfile.path} #{location} > /dev/null")
    raise ScriptError unless $?.success?
  end

  # Write out a tfm-file and a vf file for the current vpl.
  # _vflocation_ and _tfmlocation_ are full paths to the to be created
  # vf file and tfm file. The directories must be writable.
  def write_vf(vflocation,tfmlocation)
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

  private

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
