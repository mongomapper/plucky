module Plucky
  module Normalizers
    class CriteriaHashKey
      # Public: Returns key normalized for Mongo
      #
      # key - The key to normalize
      #
      # Returns key as Symbol if possible, else key with no changes
      def call(key)
        key = key.to_sym       if key.respond_to?(:to_sym)
        return call(key.field) if key.respond_to?(:field)
        return :_id            if key == :id
        key
      end
    end
  end
end
