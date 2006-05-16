# truetype.rb -- read truetype font metrics
#--
# Last Change: Sat Mar 18 18:17:32 2006
#++

require 'font/afm'

module Font
# Read TrueType fonts. Use like the AFM class.
  class TrueType < AFM
    def initialize
      @outlinetype=:truetype
      super
    end
    def read(filename)
      @filename=File.basename(filename)
      @fontfilename=filename
      @name=@filename.chomp(".ttf")
      a=`ttf2afm #{@fontfilename}`
      parse(a)
      # ttf2afm does not give an xheight!?
      unless @xheight
        @xheight=@chars['x'].ury
      end
    end
  end
end
