$:.push File.expand_path('lib', __dir__)

# Maintain your gem's version:
require 'terrier_auth/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name = 'terrier-auth'
  s.version = TerrierAuth::VERSION
  s.authors = ['Andy Selvig']
  s.email = ['andy@terrier.tech']
  s.homepage = 'https://terrier.tech'
  s.summary = "Authentication utilities for Terrier applications"
  s.description = ''
  s.license = 'MIT'

  s.files = Dir['{app,config,db,lib,vendor}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.md']

  s.add_dependency 'amazing_print'
  s.add_dependency 'dotenv-rails'
  s.add_dependency 'http'
  s.add_dependency 'colorize'
  s.add_dependency 'net-ssh'
  s.add_dependency 'ed25519'
  s.add_dependency 'ssh_data'

end
