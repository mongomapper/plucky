module Plucky
  module Normalizers
    class OptionsHashKey

      NormalizedKeys = {
        :order  => :sort,
        :select => :fields,
        :offset => :skip,
        :id     => :_id,
      }

      def call(key)
        NormalizedKeys.fetch key.to_sym, key
      end
    end
  end
end
