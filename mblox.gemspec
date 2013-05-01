# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'mblox/version'

Gem::Specification.new do |spec|
  spec.name          = "mblox"
  spec.version       = Mblox::VERSION
  spec.authors       = ["Isaac Betesh"]
  spec.email         = ["iybetesh@gmail.com"]
  spec.description   = "Send SMS messages"
  spec.summary       = `cat README.md`
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"

  spec.add_runtime_dependency 'activesupport'
  spec.add_runtime_dependency 'addressable'
  spec.add_runtime_dependency 'builder'
end
