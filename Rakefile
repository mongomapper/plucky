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

desc 'Builds the gem'
task :build do
  sh "gem build plucky.gemspec"
end

desc 'Builds and installs the gem'
task :install => :build do
  sh "gem install plucky-#{Plucky::Version}"
end

desc 'Tags version, pushes to remote, and pushes gem'
task :release => :build do
  sh "git tag v#{Plucky::Version}"
  sh "git push origin master"
  sh "git push origin v#{Plucky::Version}"
  sh "gem push plucky-#{Plucky::Version}.gem"
end
