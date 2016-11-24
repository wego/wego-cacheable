$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "cacheable/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "cacheable"
  s.version     = Cacheable::VERSION
  s.authors     = ["Geeks at Wego"]
  s.email       = ["therealgeeks@wego.com"]
  s.homepage    = "http://www.wego.com"
  s.summary     = "Wego Rails Apps Cache"
  s.description = "Gem for caching in Wego Rails apps"
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]

  s.add_development_dependency "rails", "~> 5.0.0"
  s.add_development_dependency "sqlite3"
  s.add_dependency "request_store"
  s.add_development_dependency "rspec"
end
