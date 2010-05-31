# encoding: UTF-8
class SymbolOperator
  include Comparable

  attr_reader :field, :operator

  def initialize(field, operator, options={})
    @field, @operator = field, operator
  end unless method_defined?(:initialize)
  
  def <=>(other)
    if field == other.field
      operator <=> other.operator
    else
      field.to_s <=> other.field.to_s
    end
  end
  
  def ==(other)
    field == other.field && operator == other.operator
  end
end

class Symbol
  %w(gt lt gte lte ne in nin mod all size exists asc desc).each do |operator|
    define_method(operator) do
      SymbolOperator.new(self, operator)
    end unless method_defined?(operator)
  end
end

require 'plucky/extensions/duplicable'