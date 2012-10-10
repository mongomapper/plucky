require 'helper'

describe Symbol do
  SymbolOperators.each do |operator|
    it "responds to #{operator}" do
      :foo.send(operator).should be_instance_of(SymbolOperator)
    end
  end
end
