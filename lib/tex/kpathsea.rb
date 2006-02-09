# kpathsea.rb - libkpathsea access for ruby
# Last Change: Thu Feb  9 16:39:31 2006
#
# There won't be a C version soon, because the likpathsea does not
# like to be linked with ruby on my system (OS X Tiger).

# Finds TeX related files with the standard kpathsea method

module TeX
  class Kpathsea
    # _progname_ defaults to the name of the main Ruby script.
    # _progname_ is used to find program specific files as in
    # <tt>TEXINPUT.progname</tt> in the <tt>texmf.cnf</tt>.
    def initialize (progname=File.basename($0))
      raise ArgumentError if progname.match(/('|")/)
      @progname=progname
    end
    
    def reset_program_name(suffix)
      @progname=suffix
    end
    
    # Return the complete path of the file _name_. _name_ must not
    # contain single or double quotes.
    def find_file(name,fmt="tex",mustexist=false)
      raise ArgumentError if name.match(/('|")/)
      raise ArgumentError if fmt.match(/('|")/)
      runkpsewhich(name,fmt,mustexist)
    end

    # Return a File object. Raise Errno::ENOENT if file is not found. If
    # block is given, a File object is passed into the block and the
    # file gets closed when leaving the block. It behaves exactly as 
    # the File.open method.
    def open_file(name,fmt="tex")
      loc=self.find_file(name,fmt)
      raise Errno::ENOENT, "#{name}" unless loc
      if block_given?
        File.open(loc) { |file|
          yield file
        }
      else
        File.open(loc)
      end
    end
    
    private

    def runkpsewhich(name,fmt,mustexist)
      fmt.untaint
      name.untaint
      @progname.untaint
      # path or amok XXX
      cmdline= "kpsewhich -progname=\"#{@progname}\" -format=\"#{fmt}\" #{name}"
      # puts cmdline
      lines = ""
      IO.popen(cmdline) do |io|
        lines = io.readlines
      end
      return $? == 0 ? lines.to_s.chomp.untaint : nil
    end
  end
end
