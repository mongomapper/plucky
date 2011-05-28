# encoding: UTF-8
require 'set'
require 'mongo'
require 'plucky/extensions'

module Plucky
  autoload :CriteriaHash, 'plucky/criteria_hash'
  autoload :OptionsHash,  'plucky/options_hash'
  autoload :Query,        'plucky/query'
  autoload :Version,      'plucky/version'

  module Pagination
    autoload :Decorator,  'plucky/pagination/decorator'
    autoload :Paginator,  'plucky/pagination/paginator'
  end

  # Array of methods that actually perform queries
  Methods = [
    :where, :filter, :limit, :skip, :offset, :sort, :order,
    :fields, :ignore, :only,
    :each, :find_each,
    :count, :size, :distinct,
    :last, :first, :all, :paginate,
    :exists?, :exist?, :empty?,
    :to_a, :remove,
  ]

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
