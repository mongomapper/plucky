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

    # Public
    def merge(other)
      self.class.new hash_merge(@source, other.source)
    end

    # Public
    def merge!(other)
      merge(other).to_hash.each do |key, value|
        self[key] = value
      end
      self
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
    def object_ids
      @options[:object_ids] ||= []
    end

    # Private
    def object_ids=(value)
      raise ArgumentError unless value.is_a?(Array)
      @options[:object_ids] = value.flatten
    end

    private

    # Private
    def hash_merge(oldhash, newhash)
      merge_compound_or_clauses!(oldhash, newhash)
      oldhash.merge(newhash) do |key, oldval, newval|
        old_is_hash = oldval.instance_of? Hash
        new_is_hash = newval.instance_of? Hash

        if old_is_hash && new_is_hash
          hash_merge(oldval, newval)
        elsif old_is_hash
          modifier_merge(oldval, newval)
        elsif new_is_hash
          modifier_merge(newval, oldval)
        else
          merge_values_into_array(oldval, newval)
        end
      end
    end

    def merge_compound_or_clauses!(oldhash, newhash)
      old_or = oldhash[:$or]
      new_or = newhash[:$or]
      if old_or && new_or
        oldhash[:$and] ||= []
        oldhash[:$and] << {:$or => oldhash.delete(:$or)}
        oldhash[:$and] << {:$or => newhash.delete(:$or)}
      elsif new_or && oldhash[:$and]
        if oldhash[:$and].any? {|v| v.key? :$or }
          oldhash[:$and] << {:$or => newhash.delete(:$or)}
        end
      elsif old_or && newhash[:$and]
        if newhash[:$and].any? {|v| v.key? :$or }
          newhash[:$and] << {:$or => oldhash.delete(:$or)}
        end
      end
    end

    # Private
    def modifier_merge(hash, value)
      if modifier_key = hash.keys.detect { |k| Plucky.modifier?(k) }
        hash[modifier_key].concat( array(value) ).uniq
      end
    end

    # Private
    def merge_values_into_array(value, other_value)
      array(value).concat(array(other_value)).uniq
    end

    # Private: Array(BSON::ObjectId) returns the byte array or what not instead
    # of the object id. This makes sure it is an array of object ids, not the
    # guts of the object id.
    def array(value)
      case value
      when nil, BSON::ObjectId
        [value]
      else
        Array(value)
      end
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
