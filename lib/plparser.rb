# Last Change: Fri Jul  8 00:09:22 2005

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
  
  def parse (plstring)
    @source = plstring
    @len    = @source.length
    @plist=get_plist(0)
    self
  end

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
end
