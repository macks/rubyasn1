# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rubyasn1/version'

Gem::Specification.new do |spec|
  spec.name          = "rubyasn1"
  spec.version       = Rubyasn1::VERSION
  spec.authors       = ["Mathieu Jobin"]
  spec.email         = ["mathieu@justbudget.com"]
  spec.summary       = %q{Macks ASN1 library into a gem.}
  spec.description   = %q{Macks ASN1 library into a gem.}
  spec.homepage      = ""
  spec.license       = "GPLv2"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rake-compiler"
  spec.add_dependency "racc"
end
