# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mem_kit/version'

Gem::Specification.new do |spec|
  spec.name          = "mem_kit"
  spec.version       = MemKit::VERSION
  spec.authors       = ["vaughanbrittonsage"]
  spec.email         = ["vaughan.britton@sage.com"]

  spec.summary       = 'Toolkit for working with Memory, Profiling & Cleanup'
  spec.description   = 'Toolkit for working with Memory, Profiling & Cleanup'
  spec.homepage      = "https://github.com/vaughanbrittonsage/mem_kit"
  spec.license       = "MIT"

  spec.files         = Dir.glob("{bin,lib}/**/**/**")
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.11"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.0"
  spec.add_development_dependency "pry"

  spec.add_dependency('json')
end
