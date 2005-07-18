#--
# helper.rb Last Change: Fri Jul  1 14:29:09 2005
#++
# Helper module for Font and FontCollection.

# Here we define methods that are used in Font and FontCollection. 

module Helper
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
    @mapenc=nil
    
    # nil is perfectly valid
    return if enc == nil
    
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
  # <tt>:vf</tt>,<tt>:map</tt>, <tt>:pfb</tt>, <tt>:tt</tt>, <tt>:tds</tds>. 
  def set_dirs(arg)
    if arg.instance_of? String
      [:afm, :tfm, :vpl, :vf, :pl, :map, :pfb].each { |sym|
        @dirs[sym]=arg
      }
    elsif arg.instance_of? Hash
      arg.each { |key,value|
        @dirs[key] = value
      }
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
      Dir.mkdir(dirname)
    end
  end
end
