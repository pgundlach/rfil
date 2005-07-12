examples=examples/afm2tfm.rb examples/plinfo examples/pldiff examples/afminfo
rdoc_options=-A documented_as_accessor=RW,documented_as_reader=R --title "Ruby Font Installer Library"

.PHONY : doc

all : doc

doc :
	rdoc $(rdoc_options)  README lib/*rb $(examples)
	#rdoc  README $(examples)
