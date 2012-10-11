# encoding: UTF-8

require 'plucky/normalizers/options_hash_key'
require 'plucky/normalizers/options_hash_value'

module Plucky
  class OptionsHash

    # Private: The Hash that stores the query options
    attr_reader :source

    # Private: The Hash that stores instance options
    attr_reader :options

    # Public
    def initialize(hash={}, options={})
      @source = {}
      @options = options
      hash.each { |key, value| self[key] = value }
    end

    def initialize_copy(original)
      super
      @source = @source.dup
      @source.each do |key, value|
        self[key] = value.clone if value.duplicable?
      end
    end

    # Public
    def [](key)
      @source[key]
    end

    # Public
    def []=(key, value)
      key = normalized_key(key)
      @source[key] = normalized_value(key, value)
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
    def fields?
      !self[:fields].nil?
    end

    # Public
    def merge(other)
      self.class.new(to_hash.merge(other.to_hash))
    end

    # Public
    def merge!(other)
      other.to_hash.each { |key, value| self[key] = value }
      self
    end

    # Private
    def normalized_key(key)
      key_normalizer.call(key)
    end

    # Private
    def normalized_value(key, value)
      value_normalizer.call(key, value)
    end

    # Private
    def key_normalizer
      @key_normalizer ||= @options.fetch(:key_normalizer) {
        Normalizers::OptionsHashKey.new
      }
    end

    # Private
    def value_normalizer
      @value_normalizer ||= @options.fetch(:value_normalizer) {
        Normalizers::OptionsHashValue.new({
          :key_normalizer => key_normalizer,
        })
      }
    end
  end
end
