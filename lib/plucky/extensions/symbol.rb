class Symbol
  %w(gt lt gte lte ne in nin mod all size exists asc desc).each do |operator|
    define_method(operator) do
      SymbolOperator.new(self, operator)
    end unless method_defined?(operator)
  end
end