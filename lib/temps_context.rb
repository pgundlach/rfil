# Example Context plugin for FontCollection
#
# 'temps' = TeX macro package support :-)

class TempsWriterContext < RFI::TempsWriter
  
  def initialize(fontcollection)
    @fc=fontcollection
    super(:context)
  end

  def run_plugin
    ret=[]
    @fc.texenc.each { |e|
      h={}
      h[:type]=:typescript
      h[:filename],h[:contents]=typescript(e)
      ret.push(h)
    }
    ret
  end

  def find_fonts
    ret={}
    @fc.fonts.each { |font,other|
      ret[""]=font if other[:variant]==:regular and other[:weight]==:regular and font.style==:sans
      ret["Roman"]=font if other[:variant]==:regular and other[:weight]==:regular and font.style!=:sans
      ret["Bold"]=font if other[:variant]==:regular and other[:weight]==:bold
      ret["Italic"]=font if other[:variant]==:italic and other[:weight]==:regular
      ret["Caps"]=font if other[:variant]==:smallcaps and other[:weight]==:regular
    }
    ret
  end
  def typescript(e)
    contextenc=case e.encname
               when "ECEncoding"
                 "ec"
               when "TeXBase1Encoding"
                 "8r"
               else
                 raise "unknown context encoding: #{e.encname}"
               end
    # i know that this is crap, it's just a start
    contextstyle=case @fc.style
                 when :sans
                   "Sans"
                 when :roman
                   "Serif"
                 when :typewriter
                   "Typewriter"
                 else
                   raise "unknown style found: #{@fc.style}"
                 end
    tmp = ""

    tmp << "\\starttypescript[#{@fc.style}][#{@fc.fontname}][name]\n"
    find_fonts.sort{ |a,b| a[0] <=> b[0]}.each { |style,font|
      tmp << "\\definefontsynonym [#{contextstyle}"
      tmp << "#{style}" if style.length > 0
      tmp << "] [#{@fc.fontname}"
      tmp << "-#{style}" if style.length > 0
      tmp << "]\n"
    }
    tmp << "\\stoptypsescript\n\n"

    tmp << "\\starttypescript[#{@fc.style}][#{@fc.fontname}][#{contextenc}]\n"
    find_fonts.sort{ |a,b| a[0] <=> b[0]}.each { |style,font|
      tmp << "\\definefontsynonym [#{@fc.fontname}"
      tmp << "-#{style}" if style.length > 0
      tmp << "][#{font.tex_fontname(e)}]\n"
    }
    tmp << "\\stoptypsescript\n\n"

    return ["type-#{@fc.fontname}.tex",tmp]
    
  end
end
