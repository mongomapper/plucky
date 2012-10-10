$:.unshift(File.expand_path('../../lib', __FILE__))

require 'rubygems'
require 'bundler'

Bundler.require(:default, :test)

require 'plucky'

require 'fileutils'
require 'logger'
require 'pp'

log_dir = File.expand_path('../../log', __FILE__)
FileUtils.mkdir_p(log_dir)
Log = Logger.new(File.join(log_dir, 'test.log'))

LogBuddy.init :logger => Log

connection = Mongo::Connection.new('127.0.0.1', 27017, :logger => Log)
DB = connection.db('test')

module OrderedHashHelpers
  def oh(*args)
    BSON::OrderedHash.new.tap do |hash|
      args.each { |a| hash[a[0]] = a[1] }
    end
  end
end

RSpec.configure do |config|
  config.filter_run :focused => true
  config.alias_example_to :fit, :focused => true
  config.alias_example_to :xit, :pending => true
  config.run_all_when_everything_filtered = true

  config.include OrderedHashHelpers

  config.before(:each) do
    DB.collections.map do |collection|
      collection.remove
      collection.drop_indexes
    end
  end
end

operators = %w{gt lt gte lte ne in nin mod all size exists}
operators.delete('size') if RUBY_VERSION >= '1.9.1'
SymbolOperators = operators
