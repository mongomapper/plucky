module Plucky
  module Normalizers
    class HashKey

      def initialize(keys)
        @keys = keys
      end

      # Public: Normalizes an options hash key
      #
      # key - The key to normalize
      #
      # Returns a Symbol.
      def call(key)
        @keys.fetch key.to_sym, key
      end
    end
  end
end
