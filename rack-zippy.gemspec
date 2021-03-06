# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rack-zippy/version'

Gem::Specification.new do |gem|
  gem.name          = "rack-zippy"
  gem.version       = Rack::Zippy::VERSION
  gem.authors       = ["Eliot Sykes"]
  gem.email         = ["e@jetbootlabs.com"]
  gem.description   = %q{Rack middleware for serving gzip files}
  gem.summary       = %q{Rack middleware for serving gzip files}
  gem.homepage      = "https://github.com/eliotsykes/rack-zippy"
  gem.license       = 'MIT'

  gem.files         = `git ls-files`.split($/)
  gem.executables   = []
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency 'actionpack', '~> 4.2.4'

  gem.add_development_dependency 'minitest', '~> 5.8.1'
  gem.add_development_dependency 'guard-test', '~> 2.0.6'
  gem.add_development_dependency 'rack-test', '~> 0.6.3'
  gem.add_development_dependency 'rake'
end
