module Plucky
  module Normalizers
    class SortValue

      # Public: Initializes a Plucky::Normalizers::SortValue
      #
      # args - The hash of arguments
      #        :key_normalizer - What to use to normalize keys, must
      #                          respond to call.
      #
      def initialize(args = {})
        @key_normalizer = args.fetch(:key_normalizer) {
          raise ArgumentError, "Missing required key :key_normalizer"
        }
      end

      # Public: Given a value returns it normalized for Mongo's sort option
      def call(value)
        case value
          when Array
            value.compact.map { |v| normalized_sort_piece(v) }.flatten.reduce({}, :merge)
          else
            normalized_sort_piece(value)
        end
      end

      # Private
      def normalized_sort_piece(value)
        case value
          when SymbolOperator
            normalized_direction(value.field, value.operator)
          when String
            value.split(',').map do |piece|
              normalized_direction(*piece.split(' '))
            end.reduce({}, :merge)
          when Symbol
            normalized_direction(value)
          when Array
            value.flatten.each_slice(2).map do |slice|
              normalized_direction(slice[0], slice[1])
            end
          else
            value
        end
      end

      # Private
      def normalized_direction(field, direction=nil)
        if direction != 1 && direction != -1
          direction ||= 'ASC'
          direction = direction.upcase == 'ASC' ? 1 : -1
        end
        {@key_normalizer.call(field).to_s => direction}
      end
    end
  end
end
