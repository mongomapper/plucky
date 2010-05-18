require 'rubygems'
require 'rake'
require 'rake/testtask'
require File.expand_path('../lib/plucky/version', __FILE__)

Rake::TestTask.new(:test) do |test|
  test.libs      << 'lib' << 'test'
  test.ruby_opts << '-rubygems'
  test.pattern   = 'test/**/test_*.rb'
  test.verbose   = true
end

task :default => :test

task :build do
  sh "gem build plucky.gemspec"
end

task :install => :build do
  sh "gem install plucky-#{Plucky::Version}"
end

task :release => :build do
  sh "gem push plucky-#{Plucky::Version}"
end