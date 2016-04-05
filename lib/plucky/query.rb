# encoding: UTF-8
require 'set'
require 'forwardable'

module Plucky
  class Query
    include Enumerable
    extend  Forwardable

    # Private
    OptionKeys = Set[
      :select, :offset, :order,                         # MM
      :projection, :fields, :skip, :limit, :sort, :hint, :snapshot,  # Ruby Driver
      :batch_size, :timeout, :max_scan, :return_key,    # Ruby Driver
      :transformer, :show_disk_loc, :comment, :read,    # Ruby Driver
      :tag_sets, :acceptable_latency,                   # Ruby Driver
    ]

    attr_reader    :criteria, :options, :collection

    def_delegator  :@criteria, :simple?
    def_delegator  :@options,  :fields?
    def_delegators :to_a, :include?

    # Public
    def initialize(collection, query_options = {})
      @collection, @options, @criteria = collection, OptionsHash.new, CriteriaHash.new
      query_options.each { |key, value| self[key] = value }
    end

    def initialize_copy(original)
      super
      @criteria = @criteria.dup
      @options  = @options.dup
    end

    # Public
    def object_ids(*keys)
      return @criteria.object_ids if keys.empty?
      @criteria.object_ids = *keys
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
        total_entries = opts.delete(:total_entries)
        query     = clone.amend(opts)
        paginator = Pagination::Paginator.new(total_entries || query.count, page, limit)
        docs      = query.amend({
          :limit => paginator.limit,
          :skip  => paginator.skip,
        }).all

        Pagination::Collection.new(docs, paginator)
      end

      def find_each(opts={})
        query = clone.amend(opts)

        if block_given?
          query.cursor.each do |doc|
            yield doc
          end
        else
          query.cursor
        end
      end

      def find_one(opts={})
        query = clone.amend(opts)
        query.collection.find(query.criteria_hash, query.options_hash).limit(-1).first
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
        [].tap do |docs|
          find_each(opts) {|doc| docs << doc }
        end
      end

      def last(opts={})
        clone.amend(opts).reverse.find_one
      end

      def remove(opts={}, driver_opts={})
        query = clone.amend(opts)
        query.collection.find(query.criteria_hash, driver_opts).delete_many
      end

      def count(opts={})
        query = clone.amend(opts)
        cursor = query.cursor
        cursor.count
      end

      def distinct(key, opts = {})
        query = clone.amend(opts)
        query.collection.distinct(key, query.criteria_hash)
      end

      def projection(*args)
        clone.tap { |query| query.options[:projection] = *args }
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
          if sort.nil?
            query.options[:sort] = [[:_id, -1]]
          else
            query.options[:sort] = sort.map { |s| [s[0], -s[1]] }
          end
        end
      end

      def skip(count=nil)
        clone.tap { |query| query.options[:skip] = count }
      end

      def sort(*args)
        clone.tap { |query| query.options[:sort] = *args }
      end

      def where(hash={})
        clone.tap { |query| query.criteria.merge!(CriteriaHash.new(hash)) }
      end

      def empty?
        count == 0
      end

      def exists?(query_options={})
        !only(:_id).find_one(query_options).nil?
      end

      alias_method :each,   :find_each
      alias_method :first,  :find_one
      alias_method :size,   :count
      alias_method :offset, :skip
      alias_method :order,  :sort
      alias_method :exist?, :exists?
      alias_method :filter, :where
      alias_method :to_a,   :all
      alias_method :fields, :projection
    end
    include DSL

    def update(document, driver_opts={})
      query = clone
      if driver_opts[:multi]
        query.collection.find(query.criteria_hash).update_many(document, driver_opts)
      else
        query.collection.find(query.criteria_hash).update_one(document, driver_opts)
      end
    end

    def amend(opts={})
      opts.each { |key, value| self[key] = value }
      self
    end

    def [](key)
      key = symbolized_key(key)
      source = hash_for_key(key)
      source[key]
    end

    def []=(key, value)
      key = symbolized_key(key)
      source = hash_for_key(key)
      source[key] = value
    end

    def merge(other)
      merged_criteria = @criteria.merge(other.criteria).to_hash
      merged_options  = @options.merge(other.options).to_hash
      clone.amend(merged_criteria).amend(merged_options)
    end

    def to_hash
      criteria_hash.merge(options_hash)
    end

    def explain
      @collection.find(criteria_hash, options_hash).explain
    end

    def inspect
      as_nice_string = to_hash.collect do |key, value|
        " #{key}: #{value.inspect}"
      end.sort.join(",")
      "#<#{self.class}#{as_nice_string}>"
    end

    def criteria_hash
      @criteria.to_hash
    end

    def options_hash
      @options.to_hash
    end

    def cursor(&block)
      @collection.find(criteria_hash, options_hash)
    end

  private

    # Private
    def hash_for_key(key)
      options_key?(key) ? @options : @criteria
    end

    # Private
    def symbolized_key(key)
      if key.respond_to?(:to_sym)
        key.to_sym
      else
        key
      end
    end

    # Private
    def options_key?(key)
      OptionKeys.include?(key)
    end

    # Private
    def set_field_inclusion(fields, value)
      fields_option = {}
      fields.each { |field| fields_option[symbolized_key(field)] = value }
      clone.tap { |query| query.options[:projection] = fields_option }
    end
  end
end
