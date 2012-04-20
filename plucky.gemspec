# encoding: UTF-8
require File.expand_path('../lib/plucky/version', __FILE__)

Gem::Specification.new do |s|
  s.name         = 'plucky'
  s.homepage     = 'http://github.com/jnunemaker/plucky'
  s.summary      = 'Thin layer over the ruby driver that allows you to quickly grab hold of your data (pluck it!).'
  s.require_path = 'lib'
  s.homepage    = 'http://jnunemaker.github.com/plucky/'
  s.authors      = ['John Nunemaker']
  s.email        = ['nunemaker@gmail.com']
  s.version      = Plucky::Version
  s.platform     = Gem::Platform::RUBY

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency 'mongo', '~> 1.5'
end
