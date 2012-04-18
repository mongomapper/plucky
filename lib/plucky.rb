# encoding: UTF-8
require 'set'
require 'mongo'
require 'plucky/extensions'
require 'plucky/criteria_hash'
require 'plucky/options_hash'
require 'plucky/query'
require 'plucky/pagination'

module Plucky
  autoload :Version, 'plucky/version'

  # Array of finder DSL methods to delegate
  Methods = Plucky::Query::DSL.instance_methods.sort.map(&:to_sym)

  def self.to_object_id(value)
    return value if value.is_a?(BSON::ObjectId)
    return nil   if value.nil? || (value.respond_to?(:empty?) && value.empty?)

    if BSON::ObjectId.legal?(value.to_s)
      BSON::ObjectId.from_string(value.to_s)
    else
      value
    end
  end
end
