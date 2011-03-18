require 'rubygems'
require 'rake'
require 'rake/testtask'
require File.expand_path('../lib/plucky/version', __FILE__)

require 'bundler'
Bundler::GemHelper.install_tasks

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
