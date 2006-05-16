# truetype.rb -- read truetype font metrics
#--
# Last Change: Tue May 16 14:05:52 2006
#++

require 'font/afm'

module Font
# Read TrueType fonts. Use like the AFM class.
  class TrueType < AFM
    def initialize(options={})
      super
      @outlinetype=:truetype
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
