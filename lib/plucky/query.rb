# encoding: UTF-8
require 'set'
require 'forwardable'

module Plucky
  class Query
    include Enumerable
    extend  Forwardable

    OptionKeys = Set[
      :select, :offset, :order,                         # MM
      :fields, :skip, :limit, :sort, :hint, :snapshot,  # Ruby Driver
      :batch_size, :timeout, :max_scan, :return_key,    # Ruby Driver
      :transformer, :show_disk_loc, :comment, :read,    # Ruby Driver
      :tag_sets, :acceptable_latency,                   # Ruby Driver
    ]

    attr_reader    :criteria, :options, :collection

    def_delegator  :criteria, :simple?
    def_delegator  :options,  :fields?
    def_delegators :to_a, :include?

    def initialize(collection, query_options = {})
      @collection, @options, @criteria = collection, OptionsHash.new, CriteriaHash.new
      query_options.each { |key, value| self[key] = value }
    end

    def initialize_copy(original)
      super
      @criteria = @criteria.dup
      @options  = @options.dup
    end

    def object_ids(*keys)
      return criteria.object_ids if keys.empty?
      criteria.object_ids = *keys
      self
    end

    # finder DSL methods to delegate to your model if you're building an ODM
    # e.g. MyModel.last needs to be equivalent to MyModel.query.last
    module DSL
      def per_page(limit=nil)
        return @per_page || 25 if limit.nil?
        @per_page = limit
        self
      end

      def paginate(opts={})
        page      = opts.delete(:page)
        limit     = opts.delete(:per_page) || per_page
        query     = clone.amend(opts)
        paginator = Pagination::Paginator.new(query.count, page, limit)
        docs      = query.amend({
          :limit => paginator.limit,
          :skip  => paginator.skip,
        }).all

        docs.extend(Pagination::Decorator)
        docs.paginator(paginator)
        docs
      end

      def find_each(opts={}, &block)
        query = clone.amend(opts)
        cursor = query.cursor

        if block_given?
          cursor.each { |doc| yield doc }
          cursor.rewind!
        end

        cursor
      end

      def find_one(opts={})
        query = clone.amend(opts)
        query.collection.find_one(query.criteria_hash, query.options_hash)
      end

      def find(*ids)
        return nil if ids.empty?

        single_id_find = ids.size == 1 && !ids[0].is_a?(Array)

        if single_id_find
          first(:_id => ids[0])
        else
          all(:_id => ids.flatten)
        end
      end

      def all(opts={})
        find_each(opts).to_a
      end

      def first(opts={})
        find_one(opts)
      end

      def last(opts={})
        clone.amend(opts).reverse.find_one
      end

      def each(&block)
        find_each(&block)
      end

      def remove(opts={}, driver_opts={})
        query = clone.amend(opts)
        query.collection.remove(query.criteria_hash, driver_opts)
      end

      def count(opts={})
        query = clone.amend(opts)
        cursor = query.cursor
        cursor.count
      end

      def size
        count
      end

      def distinct(key, opts = {})
        query = clone.amend(opts)
        query.collection.distinct(key, query.criteria_hash)
      end

      def fields(*args)
        clone.tap { |query| query.options[:fields] = *args }
      end

      def ignore(*args)
        set_field_inclusion(args, 0)
      end

      def only(*args)
        set_field_inclusion(args, 1)
      end

      def limit(count=nil)
        clone.tap { |query| query.options[:limit] = count }
      end

      def reverse
        clone.tap do |query|
          sort = query[:sort]
          unless sort.nil?
            query.options[:sort] = sort.map { |s| [s[0], -s[1]] }
          end
        end
      end

      def skip(count=nil)
        clone.tap { |query| query.options[:skip] = count }
      end
      alias offset skip

      def sort(*args)
        clone.tap { |query| query.options[:sort] = *args }
      end
      alias order sort

      def where(hash={})
        clone.tap { |query| query.criteria.merge!(CriteriaHash.new(hash)) }
      end
      alias filter where

      def empty?
        count.zero?
      end

      def exists?(options={})
        !count(options).zero?
      end
      alias :exist? :exists?

      def to_a
        find_each.to_a
      end
    end
    include DSL

    def update(document, driver_opts={})
      query = clone
      query.collection.update(query.criteria_hash, document, driver_opts)
    end

    def amend(opts={})
      opts.each { |key, value| self[key] = value }
      self
    end

    def [](key)
      key = normalized_key(key)
      source = hash_for_key(key)
      source[key]
    end

    def []=(key, value)
      key = normalized_key(key)
      source = hash_for_key(key)
      source[key] = value
    end

    def merge(other)
      merged_criteria = criteria.merge(other.criteria).to_hash
      merged_options  = options.merge(other.options).to_hash
      clone.amend(merged_criteria).amend(merged_options)
    end

    def to_hash
      criteria_hash.merge(options_hash)
    end

    def explain
      collection.find(criteria_hash, options_hash).explain
    end

    def inspect
      as_nice_string = to_hash.collect do |key, value|
        " #{key}: #{value.inspect}"
      end.sort.join(",")
      "#<#{self.class}#{as_nice_string}>"
    end

    def criteria_hash
      criteria.to_hash
    end

    def options_hash
      options.to_hash
    end

    def cursor
      collection.find(criteria_hash, options_hash)
    end

  private

    def hash_for_key(key)
      options_key?(key) ? @options : @criteria
    end

    def normalized_key(key)
      if key.respond_to?(:to_sym)
        key.to_sym
      else
        key
      end
    end

    def options_key?(key)
      OptionKeys.include?(key)
    end

    def set_field_inclusion(fields, value)
      fields_option = {}
      fields.each { |field| fields_option[normalized_key(field)] = value }
      clone.tap { |query| query.options[:fields] = fields_option }
    end
  end
end
