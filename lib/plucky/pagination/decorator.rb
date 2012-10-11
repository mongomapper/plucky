require 'forwardable'
module Plucky
  module Pagination
    module Decorator
      extend Forwardable

      def_delegators  :@paginator,
                      :total_entries, :total_pages,
                      :current_page,  :per_page,
                      :previous_page, :next_page,
                      :skip,          :limit,
                      :offset,        :out_of_bounds?

      # Public
      def paginator(p=nil)
        return @paginator if p.nil?
        @paginator = p
        self
      end
    end
  end
end
