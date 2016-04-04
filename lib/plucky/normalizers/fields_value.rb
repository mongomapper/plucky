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
              value.flatten.inject({}) {|acc, field| acc.merge(field => 1)}
            end
          when Symbol
            {value => 1}
          when String
            value.split(',').inject({}) { |acc, v| acc.merge(v.strip => 1) }
          else
            value
        end
      end
    end
  end
end
