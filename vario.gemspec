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
  s.summary     = 'Summary of Vario.'
  s.description = 'Description of Vario.'
  s.license     = 'MIT'

  s.files = Dir["{app,config,db,lib}/**/*", 'MIT-LICENSE', 'Rakefile', 'README.md']

  s.add_dependency 'grape', '~> 1.2'
  s.add_dependency 'grape-entity', '~> 0.8'
  s.add_dependency 'grape-swagger', '~> 0.34'
  s.add_dependency 'grape-swagger-entity', '~> 0.3'
  s.add_dependency 'rails', '>= 5.2'
  s.add_dependency 'slim', '~> 4'

  s.add_development_dependency 'pg'
end
