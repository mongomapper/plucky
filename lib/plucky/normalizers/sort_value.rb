module Plucky
  module Normalizers
    class SortValue

      def initialize(args = {})
        @key_normalizer = args.fetch(:key_normalizer) { raise KeyError, "Missing required argument :key_normalizer" }
      end

      # Public: Given a value returns it normalized for Mongo's sort option
      def call(value)
        case value
          when Array
            if value.size == 1 && value[0].is_a?(String)
              normalized_sort_piece(value[0])
            else
              value.compact.map { |v| normalized_sort_piece(v).flatten }
            end
          else
            normalized_sort_piece(value)
        end
      end

      # Private
      def normalized_sort_piece(value)
        case value
          when SymbolOperator
            [normalized_direction(value.field, value.operator)]
          when String
            value.split(',').map do |piece|
              normalized_direction(*piece.split(' '))
            end
          when Symbol
            [normalized_direction(value)]
          else
            value
        end
      end

      # Private
      def normalized_direction(field, direction=nil)
        direction ||= 'ASC'
        direction = direction.upcase == 'ASC' ? 1 : -1
        [@key_normalizer.call(field).to_s, direction]
      end
    end
  end
end
