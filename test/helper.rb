require 'pp'
require 'shoulda'
require 'matchy'
require 'mocha'
require 'mongo'
require File.expand_path('../../lib/fango', __FILE__)

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