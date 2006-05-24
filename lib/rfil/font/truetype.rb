# truetype.rb -- read truetype font metrics
#--
# Last Change: Mi 24 Mai 2006 16:42:47 CEST
#++

require 'rfil/font/afm'

module RFIL
  module Font
    # Read TrueType fonts. Use like the AFM class.
    class TrueType < AFM
      def initialize(options={})
        super
        @outlinetype=:truetype
      end

      # all relevant filenames of the font
      def fontfilenames
        return {:truetype => File.basename( @fontfilename || filename) }
      end
      
      def read(filename)
        @filename=File.basename(filename)
        @fontfilename=filename
        @name=@filename.chomp(".ttf")
        self.pathname=Pathname.new(filename).realpath.to_s
        a=`ttf2afm #{@fontfilename}`
        parse(a)
        # ttf2afm does not give an xheight!?
        @xheight=@chars['x'].ury unless @xheight
        self
      end
    end
  end
end
