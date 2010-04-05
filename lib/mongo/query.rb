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
            key, value = key.field, {"$#{key.operator}" => value}
          end
          hash[normalized_key(key)] = normalized_value(value)
        end

        hash
      end

      def normalized_key(field)
        field.to_s == 'id' ? :_id : field
      end

      def normalized_value(value)
        case value
          # when Array, Set
          #   modifier?(field) ? value.to_a : {'$in' => value.to_a}
          # when Hash
          #   to_criteria(value, field)
          when Time
            value.utc
          else
            value
        end
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