# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'seqtrimnext/version'

Gem::Specification.new do |spec|
  spec.name          = "seqtrimnext"
  spec.version       = Seqtrimnext::VERSION
  spec.authors       = ["Dario Guerrero", "Almudena Bocinos"]
  spec.email         = ["dariogf@gmail.com", "alkoke@gmail.com
t"]
  spec.summary       = %q{Sequences preprocessing and cleaning software}
  spec.description   = %q{Seqtrimnext is a plugin based system to preprocess and clean sequences from multiple NGS sequencing platforms}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"

  spec.add_runtime_dependency 'narray','>=0'
  spec.add_runtime_dependency 'gnuplot','>=0'
  spec.add_runtime_dependency 'term-ansicolor','>=1.0.5'
  spec.add_runtime_dependency 'xml-simple','>=1.0.12'
  spec.add_runtime_dependency 'scbi_blast','>=0.0.34'
  spec.add_runtime_dependency 'scbi_mapreduce','>=0.0.38'
  spec.add_runtime_dependency 'scbi_fasta','>=0.1.7'
  spec.add_runtime_dependency 'scbi_fastq','>=0.0.18'
  spec.add_runtime_dependency 'scbi_plot','>=0.0.6'
  spec.add_runtime_dependency 'scbi_math','>=0.0.1'
  spec.add_runtime_dependency 'scbi_headers','>=0.0.2'


end
