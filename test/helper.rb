require 'pp'
require 'shoulda'
require 'matchy'
require 'mocha'
require 'logger'
require 'fileutils'
require File.expand_path('../../lib/plucky', __FILE__)

log_dir = File.join(File.dirname(__FILE__), '..', 'log')
FileUtils.mkdir_p(log_dir)
Log = Logger.new(File.join(log_dir, 'test.log'))

connection = Mongo::Connection.new('127.0.0.1', 27017, :logger => Log)
DB = connection.db('plucky')

class Test::Unit::TestCase
  def setup
    DB.collections.map(&:remove)
  end
  
  def oh(*args)
    OrderedHash.new.tap do |hash|
      args.each { |a| hash[a[0]] = a[1] }
    end
  end
end

operators = %w{gt lt gte lte ne in nin mod all size exists}
operators.delete('size') if RUBY_VERSION >= '1.9.1'
SymbolOperators = operators