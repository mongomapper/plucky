require 'rubygems'
gem 'jnunemaker-matchy', '~> 0.4.0'
gem 'log_buddy'
gem 'shoulda',           '~> 2.10.2'
gem 'mocha',             '~> 0.9.8'

$:.unshift File.expand_path(File.dirname(__FILE__) + '/../lib')
require 'plucky'

require 'fileutils'
require 'logger'
require 'pp'

require 'log_buddy'
require 'shoulda'
require 'matchy'
require 'mocha'

log_dir = File.expand_path('../../log', __FILE__)
FileUtils.mkdir_p(log_dir)
Log = Logger.new(File.join(log_dir, 'test.log'))

LogBuddy.init :logger => Log

connection = Mongo::Connection.new('127.0.0.1', 27017, :logger => Log)
DB = connection.db('plucky')

class Test::Unit::TestCase
  def setup
    DB.collections.map do |collection|
      collection.remove
      collection.drop_indexes
    end
  end

  def oh(*args)
    BSON::OrderedHash.new.tap do |hash|
      args.each { |a| hash[a[0]] = a[1] }
    end
  end
end

operators = %w{gt lt gte lte ne in nin mod all size exists}
operators.delete('size') if RUBY_VERSION >= '1.9.1'
SymbolOperators = operators