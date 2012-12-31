module Plucky
  module Normalizers
    class CriteriaHashValue

      # Internal: Used by normalized_value to determine if we need to run the
      # value through another criteria hash to normalize it.
      NestingOperators = [:$or, :$and, :$nor]

      def initialize(criteria_hash)
        @criteria_hash = criteria_hash
      end

      # Public: Returns value normalized for Mongo
      #
      # parent_key - The parent key if nested, otherwise same as key
      # key - The key we are currently normalizing
      # value - The value that should be normalized
      #
      # Returns value normalized for Mongo
      def call(parent_key, key, value)
        case value
          when Array, Set
            if object_id?(parent_key)
              value = value.map { |v| to_object_id(v) }
            end

            if nesting_operator?(key)
              value.map  { |v| criteria_hash_class.new(v, options).to_hash }
            elsif parent_key == key && !modifier?(key) && !value.empty?
              # we're not nested and not the value for a symbol operator
              {:$in => value.to_a}
            else
              # we are a value for a symbol operator or nested hash
              value.to_a
            end
          when Time
            value.utc
          when String
            if object_id?(key)
              return to_object_id(value)
            end
            value
          when Hash
            value.each { |k, v| value[k] = call(key, k, v) }
            value
          when Regexp
            Regexp.new(value)
          else
            value
        end
      end

      # Private: Ensures value is object id if possible
      def to_object_id(value)
        Plucky.to_object_id(value)
      end

      # Private: Returns class of provided criteria hash
      def criteria_hash_class
        @criteria_hash.class
      end

      # Private: Returns options of provided criteria hash
      def options
        @criteria_hash.options
      end

      # Private: Returns true or false if key should be converted to object id
      def object_id?(key)
        @criteria_hash.object_id?(key)
      end

      # Private: Returns true or false if key is a nesting operator
      def nesting_operator?(key)
        NestingOperators.include?(key)
      end

      def modifier?(key)
        Plucky.modifier?(key)
      end
    end
  end
end
