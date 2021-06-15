$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require 'vario/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'vario'
  s.version     = Vario::VERSION
  s.authors     = ['Andre Meij']
  s.email       = ['andre@itsmeij.com']
  s.homepage    = 'https://code.entropydecelerator.com/components/vario'
  s.summary     = 'Vario adds custom runtime configuration to your Rails app.'
  s.license     = 'MIT'

  s.files = Dir["{app,config,db,lib}/**/*", 'MIT-LICENSE', 'Rakefile', 'README.md']

  s.add_runtime_dependency 'caliga', '~> 2'
  s.add_runtime_dependency 'grape', '~> 1.2'
  s.add_runtime_dependency 'grape-swagger', '>= 0.33'
  s.add_runtime_dependency 'rails', '>= 5.2'
  s.add_runtime_dependency 'slim', '~> 4'

  s.add_development_dependency 'auxilium', '~> 3'
  s.add_development_dependency 'pg'
  s.add_development_dependency 'pry'
end
