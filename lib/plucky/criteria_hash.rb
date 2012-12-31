# encoding: UTF-8
require 'set'
require 'plucky/normalizers/criteria_hash_value'
require 'plucky/normalizers/criteria_hash_key'

module Plucky
  class CriteriaHash
    # Private: The Hash that stores query criteria
    attr_reader :source

    # Private: The Hash that stores options
    attr_reader :options

    # Internal: Used to determine if criteria keys match simple id lookup.
    SimpleIdQueryKeys = [:_id].to_set

    # Internal: Used to determine if criteria keys match simple id and type
    # lookup (for single collection inheritance).
    SimpleIdAndTypeQueryKeys = [:_id, :_type].to_set

    # Internal: Used to quickly check if it is possible that the
    # criteria hash is simple.
    SimpleQueryMaxSize = [SimpleIdQueryKeys.size, SimpleIdAndTypeQueryKeys.size].max

    # Public
    def initialize(hash={}, options={})
      @source, @options = {}, options
      hash.each { |key, value| self[key] = value }
    end

    def initialize_copy(original)
      super
      @options = @options.dup
      @source  = @source.dup
      @source.each do |key, value|
        self[key] = value.clone if value.duplicable?
      end
    end

    # Public
    def [](key)
      @source[key]
    end

    # Public
    # The contents of this make me sad...need to clean it up
    def []=(key, value)
      normalized_key = normalized_key(key)

      if key.is_a?(SymbolOperator)
        operator = :"$#{key.operator}"
        normalized_value = normalized_value(normalized_key, operator, value)
        @source[normalized_key] ||= {}
        @source[normalized_key][operator] = normalized_value
      else
        if key == :conditions
          value.each { |k, v| self[k] = v }
        else
          normalized_value = normalized_value(normalized_key, normalized_key, value)
          @source[normalized_key] = normalized_value
        end
      end
    end

    # Public
    def keys
      @source.keys
    end

    # Public
    def ==(other)
      @source == other.source
    end

    # Public
    def to_hash
      @source
    end

    # Public and completely disgusting
    def merge(other)
      target = @source.dup
      other.source.each_key do |key|
        value, other_value = target[key], other[key]
        target[key] =
          if target.key?(key)
            value_is_hash = value.is_a?(Hash)
            other_is_hash = other_value.is_a?(Hash)

            if value_is_hash && other_is_hash
              value.update(other_value) do |key, old_value, new_value|
                if old_value.is_a?(Hash) && new_value.is_a?(Hash)
                  self.class.new(old_value).merge(self.class.new(new_value)).to_hash
                else
                  merge_values_into_array(old_value, new_value)
                end
              end
            elsif value_is_hash && !other_is_hash
              if modifier_key = value.keys.detect { |k| Plucky.modifier?(k) }
                current_value = value[modifier_key]
                value[modifier_key] = current_value.concat(array(other_value)).uniq
              else
                # kaboom! Array(value).concat(Array(other_value)).uniq
              end
            elsif other_is_hash && !value_is_hash
              if modifier_key = other_value.keys.detect { |k| Plucky.modifier?(k) }
                current_value = other_value[modifier_key]
                other_value[modifier_key] = current_value.concat(array(value)).uniq
              else
                # kaboom! Array(value).concat(Array(other_value)).uniq
              end
            else
              merge_values_into_array(value, other_value)
            end
          else
            other_value
          end
      end
      self.class.new(target)
    end

    # Private
    def merge_values_into_array(value, other_value)
      array(value).concat(array(other_value)).uniq
    end

    # Private: Array(BSON::ObjectId) returns the byte array or what not instead
    # of the object id. This makes sure it is an array of object ids, not the
    # guts of the object id.
    def array(value)
      value.is_a?(BSON::ObjectId) ? [value] : Array(value)
    end

    # Public
    def merge!(other)
      merge(other).to_hash.each do |key, value|
        self[key] = value
      end
      self
    end

    # Private
    def object_ids
      @options[:object_ids] ||= []
    end

    # Private
    def object_ids=(value)
      raise ArgumentError unless value.is_a?(Array)
      @options[:object_ids] = value.flatten
    end

    # Public: The definition of simple is querying by only _id or _id and _type.
    # If this is the case, you can use IdentityMap in library to not perform
    # query and instead just return from map.
    #
    # Returns true or false
    def simple?
      return false if keys.size > SimpleQueryMaxSize
      key_set = keys.to_set
      key_set == SimpleIdQueryKeys || key_set == SimpleIdAndTypeQueryKeys
    end

    def object_id?(key)
      object_ids.include?(key.to_sym)
    end

    # Private
    def normalized_key(key)
      key_normalizer.call(key)
    end

    # Private
    def key_normalizer
      @key_normalizer ||= @options.fetch(:key_normalizer) {
        Normalizers::CriteriaHashKey.new
      }
    end

    # Private
    def normalized_value(parent_key, key, value)
      value_normalizer.call(parent_key, key, value)
    end

    # Private
    def value_normalizer
      @value_normalizer ||= @options.fetch(:value_normalizer) {
        Normalizers::CriteriaHashValue.new(self)
      }
    end
  end
end
