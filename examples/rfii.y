#!/usr/bin/env ruby -w

class RFII
 
rule
  
  commands: # empty
     | commands command {
        # we ignore comments (they are nil)
       @instructions << val[1] if val[1]
     }
     

    command:  COMMENT NL { result=nil }
     | applystmt   NL { result=[@line-1,val[0]]}
     | fontroot    NL { result=[@line-1,val[0]]}
     | fontsource  NL { result=[@line-1,val[0]]}
     | usestmt     NL { result=[@line-1,val[0]]}
     | setstmt     NL { result=[@line-1,val[0]]}
     | writestmt   NL { result=[@line-1,val[0]]}
     | vendor      NL { result=[@line-1,val[0]]}
     | newfont     NL { result=[@line-1,val[0]]}
     | copystmt    NL { result=[@line-1,val[0]]}
     | texencoding NL { result=[@line-1,val[0]]}
     | psencoding  NL { result=[@line-1,val[0]]}
     |             NL { result=nil }
  
  applystmt: APPLY ident TO ident { result=[:apply,val[1],val[3]] }

  copystmt: COPY ident FROM ident TO ident { result=[:copy, val[1], val[3],val[5]] }

  fontroot: FONTROOT FILENAME { result=[:fontroot,val[1]] }
  
  fontsource: FONTSOURCE FILENAME { result=[:fontsource,val[1]] }

  opttexencoding: # empty
    | texencoding { result=val[0][1] }
  
  optpsencoding:  # empty
    |   psencoding { result=val[0][1] }
  
  texencoding: TEXENCODING identlist { result=[:texencoding,val[1]] }
  
  psencoding: PSENCODING ident { result=[:psencoding,val[1]] }

  vendor:  VENDOR ident { result=[:vendor,val[1].to_s] }

  newfont: NEWFONT ident "," ident { result=[:newfont,val[1].to_s,val[3]] }
  
  usestmt: USE what FILENAME AS ident  {
    ret=[]
    case val[1]
    when :ENCODING
      ret << :useencoding
      # @known_encodings << val[4]
    when :AFM
      ret << :useafm
    end
    ret << val[2]
    ret << val[4]
    result = ret
  }

  setstmt: SET ident identlist {
    ilist=val[2].size == 1 ?  val[2][0] : val[2]
    result=[:set,val[1],ilist] }

  writestmt: WRITE  identlist optfor opttexencoding optpsencoding {
    result=[:write, val[1],val[2],val[3],val[4]]
    val[1].each { |s|
      puts "unknown type for write statement near line #@line '#{s}'" unless @known_outputfiles.member? s
    }
  }
  
  what: AFM | ENCODING

  identlist: ident { result=val } 
     | identlist "," ident { result=val[0] << val[2] }

  ident: { @mode=:ident } IDENT { @mode=:normal ; result=val[1] }

  optfor: FOR identlist { result=val[1] }
     | # empty 

#   optenc: # empty
#      | IN ENCODING identlist {
#     val[2].each { |s|
#       puts "unknown encoding for write statement near line #@line '#{s}'" unless @known_encodings.member? s
#     }
#         result=val[2]
#      }

  
---- header ----
   require 'strscan'
---- inner ----
    
    def scan
      begin
        if @s.scan(/\n/)
          @line += 1
          yield :NL,"\n"
          next
        end
        # \s+ might include \n and then the linecount gets wrong!?
        if @s.scan(/\s/)
          next
        end
        case @mode
        when :ident
          if @s.scan(/\w+/)
            yield :IDENT, @s.matched.to_sym
          else
            b=@s.get_byte ;  yield b,b
          end
        else  # :normal
          if @s.scan(/#.*/)
            yield :COMMENT,@s.matched
          elsif @s.scan(/'.*?'/)
            yield :FILENAME, @s.matched[1..-2]
          elsif @s.scan(/(afm|as|apply|copy|encoding|font(root|source)|for|from|in|newfont|psencoding|use|set|texencoding|to|vendor|write)/)
            yield @s.matched.upcase.to_sym, @s.matched.upcase.to_sym
          else
            b=@s.scan(/./) ;  yield b,b
          end
        end
      end until @s.eos?
      yield false,false
    end
---- footer ----



# Local Variables:
# mode: ruby
# parse-file: "rfii.y"
# run-file: "rfii"
# End: 
