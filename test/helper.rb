require 'pp'
require 'shoulda'
require 'matchy'
require 'mocha'
require File.expand_path('../../lib/plucky', __FILE__)

connection = Mongo::Connection.new
DB = connection.db('testing')

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