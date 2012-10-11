require 'plucky/normalizers/integer'
require 'plucky/normalizers/fields_value'
require 'plucky/normalizers/sort_value'

module Plucky
  module Normalizers
    class OptionsHashValue
      def initialize(args = {})
        @key_normalizer = args.fetch(:key_normalizer) {
          raise KeyError, "Missing required argument :key_normalizer"
        }

        @value_normalizers = {
          :fields => default_fields_value_normalizer,
          :sort   => default_sort_value_normalizer,
          :limit  => default_limit_value_normalizer,
          :skip   => default_skip_value_normalizer,
        }

        if (value_normalizers = args[:value_normalizers])
          @value_normalizers.update(value_normalizers)
        end
      end

      # Public: Returns value normalized for Mongo
      #
      # key -The name of the key whose value is being normalized
      # value -The value to normalize
      #
      # Returns value normalized for Mongo.
      def call(key, value)
        if (value_normalizer = @value_normalizers[key])
          value_normalizer.call(value)
        else
          value
        end
      end

      # Private
      def default_fields_value_normalizer
        Normalizers::FieldsValue.new
      end

      # Private
      def default_sort_value_normalizer
        Normalizers::SortValue.new({
          :key_normalizer => @key_normalizer,
        })
      end

      # Private
      def default_limit_value_normalizer
        Normalizers::Integer.new
      end

      # Private
      def default_skip_value_normalizer
        Normalizers::Integer.new
      end
    end
  end
end
