require 'helper'

class SymbolOperatorTest < Test::Unit::TestCase
  context "SymbolOperator" do
    setup   { @operator = SymbolOperator.new(:foo, 'in') }
    subject { @operator }

    should "have field" do
      subject.field.should == :foo
    end

    should "have operator" do
      subject.operator.should == 'in'
    end
  end
end