# encoding: UTF-8
require 'set'
require 'plucky/normalizers/criteria_hash_value'
require 'plucky/normalizers/criteria_hash_key'

module Plucky
  class CriteriaHash
    attr_reader :source, :options

    # Internal: Used to determine if criteria keys match simple id lookup.
    SimpleIdQueryKeys = [:_id].to_set

    # Internal: Used to determine if criteria keys match simple id and type
    # lookup (for single collection inheritance).
    SimpleIdAndTypeQueryKeys = [:_id, :_type].to_set

    # Internal: Used to quickly check if it is possible that the
    # criteria hash is simple.
    SimpleQueryMaxSize = [SimpleIdQueryKeys.size, SimpleIdAndTypeQueryKeys.size].max

    def initialize(hash={}, options={})
      @source, @options = {}, options
      hash.each { |key, value| self[key] = value }
    end

    def initialize_copy(source)
      super
      @options = @options.dup
      @source  = @source.dup
      each do |key, value|
        self[key] = value.clone if value.duplicable?
      end
    end

    def []=(key, value)
      normalized_key = normalized_key(key)

      if key.is_a?(SymbolOperator)
        operator = :"$#{key.operator}"
        normalized_value = normalized_value(normalized_key, operator, value)
        source[normalized_key] ||= {}
        source[normalized_key][operator] = normalized_value
      else
        if key == :conditions
          value.each { |k, v| self[k] = v }
        else
          normalized_value = normalized_value(normalized_key, normalized_key, value)
          source[normalized_key] = normalized_value
        end
      end
    end

    def ==(other)
      source == other.source
    end

    def to_hash
      source
    end

    def merge(other)
      target = source.dup
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
                  Array(old_value).concat(Array(new_value)).uniq
                end
              end
            elsif value_is_hash && !other_is_hash
              if modifier_key = value.keys.detect { |k| k.to_s[0, 1] == '$' }
                value[modifier_key].concat(Array(other_value)).uniq!
              else
                # kaboom! Array(value).concat(Array(other_value)).uniq
              end
            elsif other_is_hash && !value_is_hash
              if modifier_key = other_value.keys.detect { |k| k.to_s[0, 1] == '$' }
                other_value[modifier_key].concat(Array(value)).uniq!
              else
                # kaboom! Array(value).concat(Array(other_value)).uniq
              end
            else
              Array(value).concat(Array(other_value)).uniq
            end
          else
            other_value
          end
      end
      self.class.new(target)
    end

    def merge!(other)
      merge(other).to_hash.each do |key, value|
        self[key] = value
      end
      self
    end

    def object_ids
      @options[:object_ids] ||= []
    end

    def object_ids=(value)
      raise ArgumentError unless value.is_a?(Array)
      @options[:object_ids] = value.flatten
    end

    # The definition of simple is querying by only _id or _id and _type.
    # If this is the case, you can use IdentityMap in library to not perform
    # query and instead just return from map.
    def simple?
      return false if keys.size > SimpleQueryMaxSize
      key_set = keys.to_set
      key_set == SimpleIdQueryKeys || key_set == SimpleIdAndTypeQueryKeys
    end

    def method_missing(method, *args, &block)
      @source.send(method, *args, &block)
    end

    def object_id?(key)
      object_ids.include?(key.to_sym)
    end

    def normalized_key(key)
      key_normalizer.call(key)
    end

    def key_normalizer
      @key_normalizer ||= options.fetch(:key_normalizer) {
        Normalizers::CriteriaHashKey.new
      }
    end

    def normalized_value(parent_key, key, value)
      value_normalizer.call(parent_key, key, value)
    end

    def value_normalizer
      @value_normalizer ||= options.fetch(:value_normalizer) {
        Normalizers::CriteriaHashValue.new(self)
      }
    end
  end
end
