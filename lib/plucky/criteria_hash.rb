module Plucky
  class CriteriaHash
    attr_reader :hash

    def initialize(hash)
      @hash = hash
    end

    def merge(other)
      hash.dup.tap do |target|
        other.keys.each do |key|
          value, other_value = target[key], other[key]
          target[key] = 
            if target.key?(key)
              if value.is_a?(Hash)
                self.class.new(value).merge(other_value)
              else
                Array(value).concat(Array(other_value)).uniq
              end
            else
              other_value
            end
        end
      end
    end
  end
end