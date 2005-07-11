examples=examples/afm2tfm.rb examples/plinfo

.PHONY : doc

all : doc

doc :
	rdoc -A documented_as_accessor=RW --title "Ruby Font Installer Library" README lib/*rb $(examples)
