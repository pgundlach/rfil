examples=$(addprefix examples/,afm2tfm.rb plinfo pldiff afminfo rfont)
rdoc_options=-A documented_as_accessor=RW,documented_as_reader=R --title "Ruby Font Installer Library"
libfiles=lib/*rb
#libfiles=

.PHONY : doc

all : doc

doc :
	rdoc $(rdoc_options)  README $(libfiles) $(examples)
