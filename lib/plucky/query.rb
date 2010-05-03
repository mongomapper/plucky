require 'set'

module Plucky
  class Query
    OptionKeys = [
      :select, :offset, :order,                                              # MM
      :fields, :skip, :limit, :sort, :hint, :snapshot, :batch_size, :timeout # Ruby Driver
    ]

    attr_reader :criteria, :options

    def initialize(options={})
      @options, @criteria, = {}, {}
      update(options)
    end

    def update(options={})
      separate_criteria_and_options(options)
      self
    end

    def filter(hash={})
      @criteria.update(CriteriaMerger.merge(criteria, normalized_criteria(hash)))
      self
    end

    def where(js)
      @criteria['$where'] = js
      self
    end

    def skip(count=0)
      @options[:skip] = count.to_i
      self
    end

    def limit(count=0)
      @options[:limit] = count.to_i
      self
    end

    def fields(fields)
      @options[:fields] = fields
      self
    end

    def sort(options)
      @options[:sort] = options
      self
    end

    def reverse
      @options[:sort] = @options[:sort].map { |s| [s[0], -s[1]] }
      self
    end

    def [](key)
      @criteria[key.to_sym]
    end

    def []=(key, value)
      @criteria[key.to_sym] = normalized_value(@criteria, key, value)
    end

    def merge(other)
      clone.update(other.options).filter(other.criteria)
    end

    private
      def normalized_criteria(criteria, parent=nil)
        {}.tap do |hash|
          criteria.each_pair do |key, value|
            key = normalized_key(key)
            if symbol_operator?(key)
              key, value = normalized_key(key.field), {"$#{key.operator}" => value}
            end
            hash[key] = normalized_value(hash, key, value)
          end
        end
      end

      def normalize_options
        sort    @options[:sort] || normalized_sort(@options.delete(:order))
        skip    @options[:skip] || @options.delete(:offset)
        limit   @options[:limit]
        fields  normalized_fields(@options[:fields] || @options.delete(:select))
      end

      def normalized_key(field)
        field.to_s == 'id' ? :_id : field
      end

      def normalized_value(criteria, key, value)
        case value
          when Array, Set
            modifier?(key) ? value.to_a : {'$in' => value.to_a}
          when Hash
            if criteria[key].kind_of?(Hash)
              criteria[key].dup.merge(normalized_criteria(value, key))
            else
              normalized_criteria(value, key)
            end
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

      def separate_criteria_and_options(options={})
        options.each_pair do |key, value|
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
        normalize_options
      end
  end
end