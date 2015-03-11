# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'paypoint/blue/version'

Gem::Specification.new do |spec|
  spec.name          = "paypoint-blue"
  spec.version       = PayPoint::Blue::VERSION
  spec.authors       = ["Laszlo Bacsi"]
  spec.email         = ["lackac@lackac.hu"]

  spec.summary       = %q{API client for PayPoint Blue}
  spec.description   = %q{API client for PayPoint's 3rd generation PSP product a.k.a PayPoint Blue}
  spec.homepage      = "https://github.com/CPlus/paypoint-blue"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.8"
  spec.add_development_dependency "rake", "~> 10.0"
end
