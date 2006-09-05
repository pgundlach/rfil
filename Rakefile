# Rakefile for rfii

require 'rake/rdoctask'
require 'rake/packagetask'
require 'rake/gempackagetask'


$:.unshift File.join(File.dirname(__FILE__), "lib")
require "rfil/version"

# task :default => [:test]

desc "Run all unittests"
task :test do
  ruby "test/unittest.rb"
end

examples = ["examples/afm2tfm.rb",
  "examples/plinfo",
  "examples/pldiff",
  "examples/afminfo",
  "examples/rfont",
  "examples/encodingtable",
  "examples/rfii"]

extra_doc = examples + ["README"]

to_package = extra_doc + ["COPYING"] + Dir.glob("lib/**/*rb")

spec = Gem::Specification.new do |s|
  s.platform         = Gem::Platform::RUBY
  s.summary          = "Library for TeX font installation"
  s.name             = 'rfil'
  s.version          = RFIL_VERSION
  s.email            = "patrick @nospam@ gundla.ch"
  s.files            =  to_package
  s.autorequire      = 'tex/context/contextsetup'
  s.require_path     = 'lib'
  s.homepage         = "http://rfil.rubyforge.org/"
  s.has_rdoc         = true
  s.extra_rdoc_files = ["README"] + examples
  s.rdoc_options    << "--main" << "README" << "--title" << "ConTeXt Setup" << "-A" << "documented_as_accessor=RW,documented_as_reader=R"
  s.description      = %{TeX font installer library.}
end


Rake::RDocTask.new do |rd|
  rd.rdoc_files.include(to_package)
  rd.title="Ruby Font Installer Library"
  rd.options << "-A"
  rd.options << "documented_as_accessor=RW,documented_as_reader=R"
  rd.options << "--inline-source"
  rd.options << "-T"
  rd.options << "pghtml"
end

Rake::GemPackageTask.new(spec) do  |p|
  p.need_tar = true
 
end
