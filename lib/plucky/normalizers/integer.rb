module Plucky
  module Normalizers
    class Integer
      def call(value)
        if value.nil?
          nil
        else
          value.to_i
        end
      end
    end
  end
end
