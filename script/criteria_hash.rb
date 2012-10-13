require 'pp'
require 'pathname'
require 'benchmark'
require 'rubygems'
require 'bundler'

Bundler.require :default, :performance

root_path = Pathname(__FILE__).dirname.join('..').expand_path
lib_path  = root_path.join('lib')
$:.unshift(lib_path)
require 'plucky'

criteria = Plucky::CriteriaHash.new(:foo => 'bar')

PerfTools::CpuProfiler.start("/tmp/criteria_hash") do
  1_000_000.times { criteria[:foo] = 'bar' }
end

puts system "pprof.rb --gif /tmp/criteria_hash > /tmp/criteria_hash.gif"
puts system "open /tmp/criteria_hash.gif"
