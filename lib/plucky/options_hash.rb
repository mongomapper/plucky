# encoding: UTF-8

require 'plucky/normalizers/options_hash_key'
require 'plucky/normalizers/options_hash_value'

module Plucky
  class OptionsHash

    attr_reader :source, :options

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

    def [](key)
      @source[key]
    end

    def []=(key, value)
      key = normalized_key(key)
      @source[key] = normalized_value(key, value)
    end

    def keys
      @source.keys
    end

    def ==(other)
      @source == other.source
    end

    def to_hash
      @source
    end

    def fields?
      !self[:fields].nil?
    end

    def merge(other)
      self.class.new(to_hash.merge(other.to_hash))
    end

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
