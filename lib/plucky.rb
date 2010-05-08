require 'mongo'

class SymbolOperator
  attr_reader :field, :operator

  def initialize(field, operator, options={})
    @field, @operator = field, operator
  end unless method_defined?(:initialize)
end

class Symbol
  %w(gt lt gte lte ne in nin mod all size exists asc desc).each do |operator|
    define_method(operator) do
      SymbolOperator.new(self, operator)
    end unless method_defined?(operator)
  end
end

module Plucky
  autoload :CriteriaHash, 'plucky/criteria_hash'
  autoload :Query,          'plucky/query'

  def self.to_object_id(value)
    if value.nil? || (value.respond_to?(:empty?) && value.empty?)
      nil
    elsif value.is_a?(BSON::ObjectID)
      value
    else
      BSON::ObjectID.from_string(value.to_s)
    end
  end
end