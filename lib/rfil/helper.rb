#--
# helper.rb Last Change: Fri Jul  1 14:29:09 2005
#++
# Helper module for Font and FontCollection.

# Here we define methods that are used in Font and FontCollection. 

require 'fileutils'
require 'rfil/tex/kpathsea'

module RFIL
  class RFI
    module Helper
      include TeX
      def set_encarray(enc,where) #:nodoc:
        if enc.instance_of?(ENC)
          where.push(enc)
        else
          enc.each { |e|
            if e.instance_of?(String)
              e = e.chomp(".enc") + ".enc"
              f=@kpse.open_file(e,"enc")
              where.push(ENC.new(f))
              f.close
            elsif e.instance_of?(ENC)
              where.push(e)
            end
          }
        end
      end
      def set_mapenc(enc) # :nodoc:
        @mapenc=enc
        
        # nil/:none is perfectly valid
        return if enc==nil or enc==:none
        
        if enc.instance_of?(ENC)
          @mapenc = enc
        else
          enc.find { |e|
            if e.instance_of?(String)
              e = e.chomp(".enc") + ".enc"
              @kpse.open_file(e,"enc") { |f|
                @mapenc = ENC.new(f)
              }
            elsif e.instance_of?(ENC)
              @mapenc = e
            end
          }
        end
      end
      # call-seq:
      #   set_dirs(string)
      #   set_dirs(hash)
      #
      # Set the base dir of all font related files. Acts only as a storage
      # for the information. The automatic font installation method in
      # Font#write_files uses this information. When a _string_ is passed,
      # use this as the base dir for all files, when a hash is given, the
      # keys must be one of <tt>:afm</tt>, <tt>:tfm</tt>, 
      # <tt>:vf</tt>,<tt>:map</tt>, <tt>:pfb</tt>, <tt>:tt</tt>, <tt>:tds</tt>. 
      def set_dirs(arg)
        # tds needs testing! set vendor/fonname before/after set_dirs
        types=[:afm, :tfm, :vpl, :vf, :pl, :map, :type1,:truetype, :fd, :typescript]
        if arg.instance_of? String
          @basedir=arg
          types.each { |sym|
            @dirs[sym]=arg
          }
        elsif arg.instance_of? Hash
          if arg[:base]
            @basedir=arg[:base]
          end
          if arg[:tds]==true
            suffix = if @vendor and @name
                       File.join(@vendor,@name)
                     else
                       ""
                     end
            types.each { |t|
              subdir= case t
                      when :afm
                        File.join("fonts/afm",suffix)
                      when :tfm
                        File.join("fonts/tfm",suffix)
                      when :vpl
                        File.join("fonts/source/vpl",suffix)
                      when :vf
                        File.join("fonts/vf",suffix)
                      when :pl
                        File.join("fonts/source/pl",suffix)
                      when :map
                        "fonts/map/dvips"
                      when :type1
                        File.join("fonts/type1",suffix)
                      when :truetype
                        File.join("fonts/truetype",suffix)
                      when :fd
                        File.join("tex/latex",suffix)
                      when :typescript
                        File.join("tex/context",suffix)
                      else
                        raise "unknown type"
                      end
              @dirs[t] = File.join(@basedir,subdir)
            }
          else
            arg.each { |key,value|
              @dirs[key] = value
            }
          end
        end
      end
      def ensure_dir(dirname) # :nodoc:
        if File.exists?(dirname)
          if File.directory?(dirname)
            # nothing to do
          else
            # exists, but not dir
            raise "File exists, but is not a directory: #{dirname}"
          end
        else
          # file does not exist, we can create a directory (hopefully)
          
          puts "Creating directory hierarchy #{dirname}" if @options[:verbose]
          
          unless @options[:dryrun]
            FileUtils.mkdir_p(dirname)
          end
        end
      end #ensure_dir
    end # helper
    # options is a hash, but with lookup to a fontcollection
    class Options   # :nodoc:
      def initialize(fontcollection)
        @fc=fontcollection
        @options={}
      end
      def [](idx)
        if @options[idx]
          return @options[idx]
        end
        if @fc
          @fc.options[idx]
        else
          nil
        end
      end
      def []=(idx,obj)
        @options[idx]=obj
      end
      
    end
  end  # RFI
end
