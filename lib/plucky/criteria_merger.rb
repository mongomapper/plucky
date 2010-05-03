module Plucky
  class CriteriaMerger
    def self.merge(hash, other)
      hash.dup.tap do |target|
        other.keys.each do |key|
          if target[key].is_a?(Hash)
            if other[key].is_a?(Hash)
              target[key] = merge(target[key], other[key])
            else
              target[key]['$in'].concat([other[key]].flatten).uniq!
            end
            next
          end

          target.update(other) { |key, *values| values.flatten.uniq }
        end
      end
    end
  end
end