# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'lita/external/version'

Gem::Specification.new do |spec|
  spec.name          = "lita-external"
  spec.version       = Lita::External::VERSION
  spec.authors       = ["Jean Boussier"]
  spec.email         = ["jean.boussier@shopify.com"]
  spec.license       = "MIT"

  spec.summary       = %q{Meta Lita adapter that use a redis queue}
  spec.description   = %q{Meta adapter that allow Lita to spawn multiple processes and load balance the work}
  spec.homepage      = "https://github.com/shopify/lita-external"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency 'lita', '~> 5.0'

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec"
end
