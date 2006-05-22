# Rakefile for rfii
# Last Change: Fri May 19 20:05:37 2006



require 'rake/rdoctask'
require 'rake/packagetask'

$:.unshift File.join(File.dirname(__FILE__), "lib")
require "rfil/version"

# task :default => [:test]

desc "Run all unittests"
task :test do
  ruby "test/unittest.rb"
end

interesting_files=["README",
                   "examples/afm2tfm.rb",
                   "examples/plinfo",
                   "examples/pldiff",
                   "examples/afminfo",
                   "examples/rfont",
                   "examples/encodingtable",
                   "examples/rfii",
                   "lib/rfil/font/*rb",
                   "lib/rfil/*rb",
                   "lib/rfil/tex/*rb"
                  ]

Rake::RDocTask.new do |rd|
  rd.rdoc_files.include(interesting_files)
  rd.title="Ruby Font Installer Library"
  rd.options << "-A"
  rd.options << "documented_as_accessor=RW,documented_as_reader=R"
  rd.options << "--inline-source"
  rd.options << "-T"
  rd.options << "pghtml"
end

Rake::PackageTask.new("rfil",RFIL_VERSION) do  |p|
  p.need_tar = true
  p.package_files.include(interesting_files,
                          "setup.rb",
                          "Rakefile")
end
