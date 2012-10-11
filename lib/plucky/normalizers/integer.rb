module Plucky
  module Normalizers
    class Integer

      # Public: Returns value coerced to integer or nil
      #
      # value - The value to normalize to an integer
      #
      # Returns an Integer or nil
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
