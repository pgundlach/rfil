=begin rdoc
Plugin for RFIL to create a fontdefinition file (<tt>.fd</tt>) for LaTeX
=end

# :enddoc:

class FDWriterLaTeX < RFIL::RFI::Plugin
  
  def initialize(fontcollection)
    @fc=fontcollection
    super(:latex,:sty)
  end

  def run_plugin
    ret=[]
    @fc.texenc.each { |e|
      h={}
      h[:type]=:fd
      h[:filename],h[:contents]=latex_fd(e)
      ret.push(h)
    }
    ret
  end

  
  # example, should be an extra plugin
  def latex_fd(e)
    raise ScriptError,"fontcollection: name not set" unless @fc.name
    latexenc=case e.encname
             when "ECEncoding","T1Encoding"
               "T1"
             when "TeXBase1Encoding"
               "8r"
             when "TS1Encoding"
               "TS1"
             when "OT2AdobeEncoding"
               "OT2"
             else
               raise "unknown latex encoding: #{e.encname}"
             end
    filename="#{latexenc}#{@fc.name}.fd"

    fd="\\ProvidesFile{#{filename}}
\\DeclareFontFamily{#{latexenc}}{#{@fc.name}}{}
"
    weight=[:m,:b,:bx]
    variant=[:n,:sc,:sl,:it]
    for i in 0..11
      w=weight[i/4]
      v=variant[i % 4]
      f=find_font(w,v)
      if f
        name = f.tex_fontname(e)
      else
        if i < 4
          name = "ssub * #{@fc.name}/m/n"
        else
          name = "ssub * #{@fc.name}/#{weight[i/4 - 1]}/#{v}"
        end
      end
        
#     [[:m,:n],[:m,:sc],[:m,:sl],[:m,:it],
#       [:b,:n],[:b,:sc],[:b,:sl],[:b,:it],
#       [:bx,:n],[:bx,:sc],[:bx,:sl],[:bx,:it]].each{ |w,v|
#       f=find_font(w,v)
      
#       name = f ? f.tex_fontname(e) : "<->ssub * #{@fc.name}/m/n"
      fd << "\\DeclareFontShape{#{latexenc}}{#{@fc.name}}{#{w}}{#{v}}{
      <->   #{name}
}{}
"
    end
  return [filename,fd]
end
  def find_font(w,v)
    weight={}
    variant={}
    weight[:m]=:regular
    weight[:b]=:bold
    variant[:n]=:regular
    variant[:it]=:italic
    variant[:sl]=:slanted
    variant[:sc]=:smallcaps

    # w is one of :m, :b, :bx
    # v is one of :n, :sc, :sl, :it
    @fc.fonts.each { |font|
      #p b[:weight]==weight[w]
      if font.variant ==variant[v] and font.weight==weight[w]
        return font
      end
    }
    return nil
  end
  
end
