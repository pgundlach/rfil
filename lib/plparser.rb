#--
# Last Change: Thu Jul 14 03:11:01 2005
#++
# == Accessing PL (property lists)
# The PL class and its subclasses are helpful if you want to read or
# write pl and vpl files. The pl files are the _source_ of the tfm
# files, that are used by TeX to get the metric information about a
# font. 
# == Example usage
# === Parsing an existing pl file
# You have to include +plparser+ and after creation of an instance of
# the PL class, you call the method #parse.
# Now you can access the nodes in the plist just as normal attributes.
# Some nodes might return a more complex data structure, such as
# +fontmetric+
# === Creating a property list
# After instantiating the PL class, you can fill the empty @plist with
# the class methods such as PL.comment and object methods such as
# #ligtable. After you are done, either write out the pl file with
# #write_tfm or #write_vf, or get a +pltotf+ and +vpltovf+ compatible
# string representation with #to_s.
# 

class PL
  @@syntax = { 
    :comment => [:string ],
    :codingscheme => [:string ],
    :sevenbitsafeflag => [:string ],
    :checksum  => [:num ],
    :designsize => [:num ],
    :designunits => [:num ],
    :family  => [:string ],
    :fontdimen  => [:plist ],
    :face    => [:num],
    :ligtable => [:plist],
    :label   =>  [:num],
    :lig      => [:num, :num],
    "/lig".to_sym     => [:num, :num],
    "/lig>".to_sym    => [:num, :num],
    "lig/".to_sym     => [:num, :num],
    "lig/>".to_sym    => [:num, :num],
    "/lig/".to_sym    => [:num, :num],
    "/lig/>".to_sym   => [:num, :num],
    "/lig/>>".to_sym  => [:num, :num],
    :krn      => [:num, :num],
    :stop    => [],
    :slant   => [:num],
    :space   => [:num],
    :stretch => [:num],
    :shrink   => [:num],
    :xheight   => [:num],
    :quad   => [:num],
    :extraspace   => [:num],
    :parameter => [:num, :num],
    :character => [:num, :plist],
    :charwd    => [:num],
    :chardp    => [:num],
    :charht    => [:num],
    :charic    => [:num],
    :vtitle     => [:string ],
    :mapfont    => [:num,:plist],
    :fontname   => [:string],
    :fontchecksum => [:num],
    :fontat     => [:num],
    :fontdsize  => [:num],
    :map        => [:plist],
    :setchar    => [:num],
    :selectfont => [:num],
    :setrule    => [:num,:num],
    :special    => [:string],
    :specialhex => [:string],
    :moveup     => [:num],
    :movedown   => [:num],
    :moveright  => [:num],
    :moveleft   => [:num],
    :push       => [],
    :pop        => [],
  }

  # Read _plstring_ that contains a property list as output by
  # +tftopl+ or +vftovp+. The result is stored in @plist. Returns self.
  def parse (plstring)
    @source = plstring
    @len    = @source.length
    @plist=get_plist(0)
    update_cache
    self
  end

  private
  
  def get_num (pos)
    lookingat =  @source[pos,pos+100] 
    m = lookingat.match(/\A\s*(?:(C)\s+(\S)|(D)\s+([+-]?\d+)|(F)\s+([A-Z]+)|(O)\s+(\d+)|(H)\s+([:xdigit:]+)|(R)\s+([+-]?[0-9.]+))/)
    # puts "m=#{m}"
    num=Num.new
    letter, value= (m.captures.partition { |x| x==nil})[1]
    num.type=letter
    case letter
    when "C"
      num.value = value[0]
    when "D"
      num.value = value.to_i
    when "F"
      num.value= FARRAY.index(value)
    when "O"
      num.value= value.to_i(8)
    when "H"
      puts "H"
      raise "not implemented"
    when "R"
      num.value = value.to_f
    end
    return num,pos + $&.length 
  end
  
  def get_string (pos)
    # when reading comments that start with \n, we want to preserve
    # that \n. It is not really necessary, but perhaps nice to have?
    pos +=1 unless @source[pos].chr =="\n"
    bpos=pos
    level=0
    while a=@source[pos].chr
      case a
      when "("
        level += 1
      when ")"
        if level == 0
          return @source [bpos..pos-1],pos
        else
          level -= 1
        end
      end
      pos += 1
    end
  end
  
  def get_plist (pos)
    plist=Plist.new
    while (pos < @len)
      nextchar=@source[pos].chr
      case nextchar
      when "("
        node,pos = get_node(pos)
        plist.push node
      when ")"
        return plist,pos -1
      else 
        pos += 1
      end
    end
    # top plist only
    return plist
  end
  
  def get_node (pos)
    # we are right after '(', lets read the command and the rest
    lookingat = @source[pos,pos+100]
    lookingat.match(/\A\s*\(([\/A-Za-z>]+)/)
    node=Node.new($1.downcase.to_sym)
    pos += $&.length
    params = @@syntax[node.type]
    raise "unknown property: " + node.type.to_s unless params
    params.each { |param|
      case param
      when :string
        string,pos = get_string(pos)
        node.push string
      when :num
        num,pos = get_num(pos)
        node.push num
      when :plist
        plist,pos = get_plist(pos)
        node.push plist
      else 
        raise "unknown parameter: " + param.to_s
      end
    }
    while (nextchar=@source[pos].chr) != ")"
      pos +=1
    end
    pos +=1 
    return node,pos
  end # get_node (pos)

  def update_cache
    # plist just filled with contents, by parse()
    # we need to update the @ligs ligtable and the @chars char array
    # puts @plist.to_s
    n = @plist.find {|node|
      node.type==:ligtable
    }
    if n
      # analyze ligtable
      lig=[]
      krn=[]
      comment=""
      currentchar=[]
      n.contents[0].each { |node|
        case node.type
        when :label
          currentchar.push(node.contents[0].value)
        when :krn
          krn.push([node.contents[0].value,node.contents[1].value])
        when :lig
          # warning: for multiple :labels, we only store the first
          # value in the LIG obj
          lig.push(RFI::LIG.new(currentchar[0],
                                node.contents[0].value,
                                node.contents[1].value,
                                node.type))
        when :comment
          comment << node.contents[0]
        when :stop
          pos=currentchar.shift
          @ligs[pos]=LigKern.new
          @ligs[pos][:comment]=comment
          @ligs[pos][:krn]=krn.sort if krn.size > 0
          @ligs[pos][:lig]=lig if lig.size > 0

          currentchar.each { |otherpos|
            if @ligs[pos][:alias]
              @ligs[pos][:alias].add(otherpos)
            else
              @ligs[pos][:alias] = Set.new([otherpos])
            end
            @ligs[otherpos]=pos
          }
          lig=[]
          krn=[]
          comment=""
          currentchar=[]
        else
          raise "Unknown entry in LIGTABLE: #{node.type}" 
        end
      }

    end

    n = @plist.find_all { |node|
      node.type==:character
    }
    
    n.each { |charnode|
      charnum=charnode.contents[0].value
      ret={}
      @chars[charnum]=ret
      comment=""
   
      charnode.contents[1].each { |node|
        case node.type
        when :comment
          comment << node.contents[0]
          ret[:comment]=comment
        when :charwd,:charht,:charic,:chardp
          ret[node.type]=node.contents[0].value
        when :map
          map=[]
          ret[:map]=map
          node.contents[0].each { |node|
            case node.type
            when :selectfont, :setchar
              map.push [node.type, node.contents[0].value]
            else
              raise "unknown instruction: #{node.type}"
            end
          }        
        end
      }
    }
    # Now @ligs and @chars represent the state in @plist.
  end # update_cache

end
