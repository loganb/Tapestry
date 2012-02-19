# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require "tapestry/version"

Gem::Specification.new do |gem|
  gem.name        = "tapestry"
  gem.version     = Tapestry::VERSION
  gem.platform    = Gem::Platform::RUBY
  gem.summary     = "Fiber adapter for doing non-blocking I/O"
  gem.description = gem.summary
  gem.licenses    = ['MIT']

  gem.authors     = ['Logan Bowers']
  gem.email       = ['logan@datacurrent.com']
  gem.homepage    = 'https://github.com/loganb/tapestry'

  gem.required_rubygems_version = '>= 1.3.6'

  gem.files        = Dir['README.md', 'lib/**/*']
  gem.require_path = 'lib'

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec'
  gem.add_development_dependency 'rdoc'
end
