# Rakefile for rfii

require 'rake/rdoctask'
require 'rake/packagetask'

task :default => [:test]
desc "Run all unittests"

task :test do
  ruby "test/unittest.rb"
end

Rake::RDocTask.new do |rd|
  rd.rdoc_files.include("README",
                        "examples/afm2tfm.rb",
                        "examples/plinfo",
                        "examples/pldiff",
                        "examples/afminfo",
                        "examples/rfont",
                        "examples/encodingtable",
                        "examples/rfii",
			"lib/font/*rb",
                        "lib/*rb",
			"lib/tex/*rb"
			)
  rd.title="Ruby Font Installer Library"
  rd.options << "-A"
  rd.options << "documented_as_accessor=RW,documented_as_reader=R"
  rd.options << "--inline-source"
  rd.options << "-T"
  rd.options << "pghtml"
end

Rake::PackageTask.new("rfii","0.1") do  |p|
  p.need_tar = true
  p.package_files.include("liesmich", "lib/turnier.rb")
end
