# helper.rb Last Change: Fri Jul  1 14:29:09 2005

# Module helper.

module Helper
  def set_encarray(enc,where)
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
  def set_mapenc(enc)
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
  def ensure_dir(dirname)
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
    # You can set only one .map-encoding
  
end
