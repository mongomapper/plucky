module Plucky
  module Normalizers
    class FieldsValue

      # Public: Given a value returns it normalized for Mongo's fields option
      def call(value)
        return nil if value.respond_to?(:empty?) && value.empty?

        case value
          when Array
            if value.size == 1 && value.first.is_a?(Hash)
              value.first
            else
              value.flatten
            end
          when Symbol
            [value]
          when String
            value.split(',').map { |v| v.strip }
          else
            value
        end
      end
    end
  end
end
