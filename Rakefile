require 'rubygems'
require 'rake'
require 'rake/testtask'
require File.expand_path('../lib/plucky/version', __FILE__)

namespace :test do
  Rake::TestTask.new(:all) do |test|
    test.libs      << 'lib' << 'test'
    test.pattern   = 'test/**/test_*.rb'
    test.verbose   = true
  end
end

task :test do
  Rake::Task['test:all'].invoke
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
