examples=examples/afm2tfm.rb examples/plinfo

.PHONY : doc

all : doc

doc :
	rdoc --title "Ruby Font Installer Library" README lib/*rb $(examples)
