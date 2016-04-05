module Plucky
  class Transformer
    def initialize(view, transformer)
      @view = view
      @transformer = transformer
    end

    def each
      @view.each do |doc|
        yield @transformer.call(doc)
      end
    end
  end
end
