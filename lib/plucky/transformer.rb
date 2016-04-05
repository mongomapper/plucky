module Plucky
  class Transformer
    def initialize(iterable, transformer)
      @iterable = iterable
      @transformer = transformer
    end

    def each
      @iterable.each do |doc|
        yield @transformer.call(doc)
      end
    end
  end
end
