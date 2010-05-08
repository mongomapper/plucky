require 'helper'

class SymbolTest < Test::Unit::TestCase
  context "Symbol" do
    SymbolOperators.each do |operator|
      should "respond to #{operator}" do
        :foo.send(operator).should be_instance_of(SymbolOperator)
      end
    end
  end
end