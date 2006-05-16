=begin rdoc
Plugin for RFIL to create a typescript usable for ConTeXt.
=end

# :enddoc:

class TypescriptWriterConTeXt < RFIL::RFI::Plugin
  
  def initialize(fontcollection)
    @fc=fontcollection
    super(:context,:typescript)
  end

  STOPTYPESCRIPT="\\stoptypescript\n\n"
  
  def run_plugin
    ret=[]
    str=""
    puts "running context plugin" if @fc.options[:verbose]
    @fc.texenc.each { |e|
      str << typescript(e)
      str << "\n"
    }
    h={}
    h[:type]=:typescript
    h[:filename],h[:contents]=["type-#{@fc.name}.tex",str]
    ret.push(h)
    ret
  end

  # Returns hash: Style, font
  def find_fonts
    ret={}
    @fc.fonts.each { |font|
      ret[""]=font if font.variant==:regular and font.weight==:regular 
#      ret[""]=font if font.variant==:regular and font.weight==:regular and font.style!=:sans
      ret["Bold"]=font if font.variant==:regular and font.weight==:bold
      ret["Italic"]=font if font.variant==:italic and font.weight==:regular
      ret["Caps"]=font if font.variant==:smallcaps and font.weight==:regular
    }
    ret
  end
  def typescript(e)
    contextenc=case e.encname
               when "ECEncoding"
                 "ec"
               when "TS1Encoding"
                 "ts1"
               when "T1Encoding"
                 "tex256"
               when "TeXBase1Encoding"
                 "8r"
               else
                 raise "unknown context encoding: #{e.encname}"
               end
    # i know that this is crap, it's just a start
    contextstyle=case @fc.style
                 when :sans
                   "Sans"
                 when :roman, :serif
                   "Serif"
                 when :typewriter
                   "Typewriter"
                 else
                   raise "unknown style found: #{@fc.style}"
                 end
    tmp = ""
    fontname=@fc.name
    tmp << "\\starttypescript[#{@fc.style}][#{fontname}][name]\n"
    find_fonts.sort{ |a,b| a[0] <=> b[0]}.each { |style,font|
      tmp << "\\definefontsynonym [#{contextstyle}"
      p style
      tmp << "#{style}" if style.length > 0
      tmp << "] [#{fontname}"
      tmp << "-#{style}" if style.length > 0
      tmp << "]\n"
    }
    tmp << STOPTYPESCRIPT

    tmp << "\\starttypescript[#{@fc.style}][#{fontname}][#{contextenc}]\n"
    find_fonts.sort{ |a,b| a[0] <=> b[0]}.each { |style,font|
      tmp << "\\definefontsynonym [#{fontname}"
      tmp << "-#{style}" if style.length > 0
      tmp << "][#{font.tex_fontname(e)}]\n"
    }
    tmp << STOPTYPESCRIPT

    return tmp
  end
end
