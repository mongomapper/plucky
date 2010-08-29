# encoding: UTF-8
require File.expand_path('../lib/plucky/version', __FILE__)

Gem::Specification.new do |s|
  s.name         = 'plucky'
  s.homepage     = 'http://github.com/jnunemaker/plucky'
  s.summary      = 'Thin layer over the ruby driver that allows you to quickly grab hold of your data (pluck it!).'
  s.require_path = 'lib'
  s.authors      = ['John Nunemaker']
  s.email        = ['nunemaker@gmail.com']
  s.version      = Plucky::Version
  s.platform     = Gem::Platform::RUBY
  s.files        = Dir.glob("{bin,lib}/**/*") + %w[LICENSE README.rdoc]

  s.add_dependency              'mongo', '~> 1.0.8'
  s.add_development_dependency  'shoulda',            '~> 2.11'
  s.add_development_dependency  'jnunemaker-matchy',  '~> 0.4.0'
  s.add_development_dependency  'mocha',              '~> 0.9.8'
  s.add_development_dependency  'log_buddy'
end