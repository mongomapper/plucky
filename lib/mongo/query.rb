require 'set'

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
          key = normalized_key(key)
          if symbol_operator?(key)
            value = {"$#{key.operator}" => value}
            key   = normalized_key(key.field)
          end
          hash[key] = normalized_value(key, value)
        end
        hash
      end

      def normalized_options(options)
        fields = @options[:fields] || @options[:select]
        skip   = @options[:skip]   || @options[:offset] || 0
        limit  = @options[:limit]  || 0
        sort   = @options[:sort]   || normalized_sort(@options[:order])

        {:fields => normalized_fields(fields), :skip => skip.to_i, :limit => limit.to_i, :sort => sort}
      end

      def normalized_key(field)
        field.to_s == 'id' ? :_id : field
      end

      def normalized_value(key, value)
        case value
          when Array, Set
            modifier?(key) ? value.to_a : {'$in' => value.to_a}
          when Hash
            normalized_criteria(value, key)
          when Time
            value.utc
          else
            value
        end
      end

      def normalized_sort(sort)
        return if sort.nil?

        if sort.respond_to?(:all?) && sort.all? { |s| symbol_operator?(s) }
          sort.map { |s| normalized_order(s.field, s.operator) }
        elsif symbol_operator?(sort)
          [normalized_order(sort.field, sort.operator)]
        else
          sort.split(',').map do |str|
            normalized_order(*str.strip.split(' '))
          end
        end
      end

      def normalized_fields(fields)
        return if fields.nil? || fields == [] || fields == ''

        if fields.respond_to?(:flatten, :compact)
          fields.flatten.compact
        else
          fields.split(',').map { |field| field.strip }
        end
      end

      def normalized_order(field, direction=nil)
        direction ||= 'ASC'
        direction = direction.upcase == 'ASC' ? 1 : -1
        [normalized_key(field).to_s, direction]
      end

      def symbol_operator?(object)
        object.respond_to?(:field, :operator)
      end

      def modifier?(key)
        key.to_s =~ /^\$/
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
        @options  = normalized_options(@options)
      end
  end
end