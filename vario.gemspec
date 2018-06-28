$:.push File.expand_path("lib", __dir__)

# Maintain your gem's version:
require "vario/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "vario"
  s.version     = Vario::VERSION
  s.authors     = ["Andre Meij"]
  s.email       = ["andre@itsmeij.com"]
  s.homepage    = "TODO"
  s.summary     = "TODO: Summary of Vario."
  s.description = "TODO: Description of Vario."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.md"]

  s.add_dependency "rails", "~> 5.2.0"

  s.add_development_dependency "sqlite3"
end
