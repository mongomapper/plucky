module Plucky
  class CriteriaMerger
    def self.merge(hash, other)
      hash.dup.tap do |target|
        other.keys.each do |key|
          if target[key].is_a?(Hash)
            if other[key].is_a?(Hash)
              target[key] = merge(target[key], other[key])
            else
              target[key]['$in'].concat(Array(other[key])).uniq!
            end
          else
            if target.key?(key) && other.key?(key)
              target[key] = Array(target[key]).concat(Array(other[key]))
            else
              target[key] = other[key]
            end
          end
        end
      end
    end
  end
end