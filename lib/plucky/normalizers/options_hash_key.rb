module Plucky
  module Normalizers
    class OptionsHashKey

      # Internal: Keys with values that they should normalize to
      NormalizedKeys = {
        :order  => :sort,
        :select => :fields,
        :offset => :skip,
        :id     => :_id,
      }

      # Public: Normalizes an options hash key
      #
      # key - The key to normalize
      #
      # Returns a Symbol.
      def call(key)
        NormalizedKeys.fetch key.to_sym, key
      end
    end
  end
end
