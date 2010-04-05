class SymbolOperator
  attr_reader :field, :operator

  def initialize(field, operator, options={})
    @field, @operator = field, operator
  end unless method_defined?(:initialize)
end

class Symbol
  %w(gt lt gte lte ne in nin mod all size where exists asc desc).each do |operator|
    define_method(operator) do
      SymbolOperator.new(self, operator)
    end unless method_defined?(operator)
  end
end

module Mongo
  class Query
    OptionKeys = [:fields, :select, :skip, :offset, :limit, :sort, :order]

    attr_reader :criteria, :options

    def initialize(options={})
      @original_options, @options, @criteria, = options, {}, {}
      separate_criteria_and_options
    end

    private
      def normalized_criteria(criteria, parent=nil)
        hash = {}
        
        criteria.each_pair do |key, value|
          if symbol_operator?(key)
            value = {"$#{key.operator}" => value}
            key = key.field
          end
          
          hash[key] = value
        end
        
        hash
      end
      
      def symbol_operator?(object)
        object.respond_to?(:field, :operator)
      end
      
      def separate_criteria_and_options
        @original_options.each_pair do |key, value|
          key = key.respond_to?(:to_sym) ? key.to_sym : key

          if OptionKeys.include?(key)
            @options[key] = value
          elsif key == :conditions
            @criteria.update(value)
          else
            @criteria[key] = value
          end
        end
        
        @criteria = normalized_criteria(@criteria)
      end
  end
end