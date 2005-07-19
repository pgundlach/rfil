# Example LaTeX plugin for FontCollection
#
# 'temps' = TeX macro package support :-)

class TempsWriterLaTeX < RFI::TempsWriter
  
  def initialize(fontcollection)
    @fc=fontcollection
    super(:latex)
  end

  # Return the contents of the file that should be used by the TeX
  # macro package, i.e a typescript for ConTeXt or an fd-file for
  # LaTeX. Return value is an Array of Hashes. The Hash has three
  # different keys:
  # [<tt>:type</tt>] The type of the file, should be either <tt>:fd</tt> or <tt>:typescript</tt>.
  # [<tt>:filename</tt>] the filename (without a path) of the file
  # [<tt>:contents</tt>] the contents of the file.
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
    latexenc=case e.encname
             when "ECEncoding"
               "T1"
             else
               raise "unknown latex encoding: #{e.encname}"
             end
    filename="#{latexenc}#{@fc.fontname}.fd"

    fd="\\ProvidesFile{#{filename}}
\\DeclareFontFamily{#{latexenc}}{#{@fc.fontname}}{}
"
    [[:m,:n],[:m,:sc],[:m,:sl],[:m,:it],
      [:b,:n],[:b,:sc],[:b,:sl],[:b,:it],
      [:bx,:n],[:bx,:sc],[:bx,:sl],[:bx,:it]].each{ |w,v|
      f=find_font(w,v)
      name = f ? f.tex_fontname(e) : "<->ssub * #{@fc.fontname}/n/n"
      fd << "\\DeclareFontShape{#{latexenc}}{#{@fc.fontname}}{#{w}}{#{v}}{
      <->   #{name}
}{}
"
    }
    return [filename,fd]
  end
  def find_font(w,v)
    weight={}
    variant={}
    weight[:m]=:regular
    weight[:b]=:bold
    variant[:n]=:regular
    variant[:i]=:italic
    variant[:sl]=:slanted
    variant[:sc]=:smallcaps

    # w is one of :m, :b, :bx
    # v is one of :n, :sc, :sl, :it
    @fc.fonts.each { |a,b|
      #p b[:weight]==weight[w]
      if b[:variant]==variant[v] and b[:weight]==weight[w]
        return a
      end
    }
    return nil
  end
  
end
