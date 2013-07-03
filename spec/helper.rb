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

port = ENV.fetch "BOXEN_MONGODB_PORT", 27017
connection = Mongo::MongoClient.new('127.0.0.1', port.to_i, :logger => Log)
DB = connection.db('test')

RSpec.configure do |config|
  config.filter_run :focused => true
  config.alias_example_to :fit, :focused => true
  config.alias_example_to :xit, :pending => true
  config.run_all_when_everything_filtered = true

  config.before(:suite) do
    DB.collections.reject { |collection|
      collection.name =~ /system\./
    }.map(&:drop_indexes)
  end

  config.before(:each) do
    DB.collections.reject { |collection|
      collection.name =~ /system\./
    }.map(&:remove)
  end
end

operators = %w{gt lt gte lte ne in nin mod all size exists}
operators.delete('size') if RUBY_VERSION >= '1.9.1'
SymbolOperators = operators
