
.PHONY : doc

all : doc

doc :
	rdoc --title "Ruby Font Installer Library" README lib/*rb examples/afm2tfm.rb
