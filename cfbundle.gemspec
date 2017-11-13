require File.expand_path('../lib/cfbundle/version', __FILE__)

Gem::Specification.new do |s|
  s.name        = 'cfbundle'
  s.version     = CFBundle::VERSION
  s.date        = '2017-11-13'
  s.summary     = 'CFBundle'
  s.description = 'CFBundle is a module for reading macOS and iOS bundles ' \
                  '(including zipped bundles and .ipa files).'
  s.authors     = ['Nicolas Bachschmidt']
  s.email       = 'nicolas@h2g.io'
  s.files       = Dir.glob('lib/**/*.rb')
  s.license     = 'MIT'
  s.add_dependency 'CFPropertyList', '>= 2.3.5', '< 3.0.0'
  s.add_development_dependency 'rspec', '~> 3.7.0'
  s.add_development_dependency 'rubocop', '~> 0.51.0'
  s.add_development_dependency 'rubyzip', '~> 1.2.1'
  s.add_development_dependency 'simplecov', '~> 0.15.1'
end
