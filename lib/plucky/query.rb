# encoding: UTF-8
require 'forwardable'
module Plucky
  class Query
    extend Forwardable

    OptionKeys = [
      :select, :offset, :order,                                              # MM
      :fields, :skip, :limit, :sort, :hint, :snapshot, :batch_size, :timeout # Ruby Driver
    ]

    attr_reader   :criteria, :options, :collection
    def_delegator :criteria, :simple?
    def_delegator :options,  :fields?

    def initialize(collection, opts={})
      @collection, @options, @criteria = collection, OptionsHash.new, CriteriaHash.new
      opts.each { |key, value| self[key] = value }
    end

    def initialize_copy(source)
      super
      @criteria = @criteria.dup
      @options  = @options.dup
    end

    def object_ids(*keys)
      return criteria.object_ids if keys.empty?
      criteria.object_ids = *keys
      self
    end

    def find(opts={})
      update(opts).collection.find(criteria.to_hash, options.to_hash)
    end

    def find_one(opts={})
      update(opts).collection.find_one(criteria.to_hash, options.to_hash)
    end

    def all(opts={})
      update(opts).find(to_hash).to_a
    end

    def first(opts={})
      update(opts).find_one(to_hash)
    end

    def last(opts={})
      update(opts).reverse.find_one(to_hash)
    end

    def remove(opts={})
      update(opts).collection.remove(criteria.to_hash)
    end

    def count(opts={})
      update(opts).find(to_hash).count
    end

    def update(opts={})
      opts.each { |key, value| self[key] = value }
      self
    end

    def fields(*args)
      self[:fields] = args
      self
    end

    def limit(count=nil)
      self[:limit] = count
      self
    end

    def reverse
      self[:sort].map! { |s| [s[0], -s[1]] } unless self[:sort].nil?
      self
    end

    def skip(count=nil)
      self[:skip] = count
      self
    end

    def sort(*args)
      self[:sort] = *args
      self
    end

    def where(hash={})
      criteria.merge(CriteriaHash.new(hash)).to_hash.each { |key, value| self[key] = value }
      self
    end

    def [](key)
      key = key.to_sym if key.respond_to?(:to_sym)
      if OptionKeys.include?(key)
        @options[key]
      else
        @criteria[key]
      end
    end

    def []=(key, value)
      key = key.to_sym if key.respond_to?(:to_sym)
      if OptionKeys.include?(key)
        @options[key] = value
      else
        @criteria[key] = value
      end
    end

    def merge(other)
      merged = criteria.merge(other.criteria).to_hash.merge(options.to_hash.merge(other.options.to_hash))
      clone.update(merged)
    end

    def to_hash
      criteria.to_hash.merge(options.to_hash)
    end

    def inspect
      as_nice_string = to_hash.collect do |key, value|
        " #{key}: #{value.inspect}"
      end.sort.join(",")
      "#<#{self.class}#{as_nice_string}>"
    end

    # def copy
    #       self.class.new(@collection).object_ids(object_ids).update(to_hash)
    #     end
  end
end