# truetype.rb -- read truetype font metrics
#--
# Last Change: Wed Jul 20 16:39:12 2005
#++

require 'afm'

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
    a=`ttf2afm dustismo_roman.ttf`
    parse(a)
    # ttf2afm does not give an xheight!?
    unless @xheight
      @xheight=@chars['x'].ury
    end
  end
end
