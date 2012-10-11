# encoding: UTF-8
module Plucky
  module Pagination
    class Paginator
      attr_reader :total_entries, :current_page, :per_page

      # Public
      def initialize(total, page, per_page=nil)
        @total_entries = total.to_i
        @current_page  = [page.to_i, 1].max
        @per_page      = (per_page || 25).to_i
      end

      # Public
      def total_pages
        (@total_entries / @per_page.to_f).ceil
      end

      # Public
      def out_of_bounds?
        @current_page > total_pages
      end

      # Public
      def previous_page
        @current_page > 1 ? (@current_page - 1) : nil
      end

      # Public
      def next_page
        @current_page < total_pages ? (@current_page + 1) : nil
      end

      # Public
      def skip
        (@current_page - 1) * @per_page
      end

      # Public
      alias :limit :per_page

      # Public
      alias :offset :skip
    end
  end
end
