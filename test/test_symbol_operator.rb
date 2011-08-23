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

    context "==" do
      should "be true if field and operator are equal" do
        SymbolOperator.new(:foo, 'in').should == SymbolOperator.new(:foo, 'in')
      end

      should "be false if fields are equal but operators are not" do
        SymbolOperator.new(:foo, 'in').should_not == SymbolOperator.new(:foo, 'all')
      end

      should "be false if operators are equal but fields are not" do
        SymbolOperator.new(:foo, 'in').should_not == SymbolOperator.new(:bar, 'in')
      end

      should "be false if neither are equal" do
        SymbolOperator.new(:foo, 'in').should_not == SymbolOperator.new(:bar, 'all')
      end

      should "be false if other isn't an symbol operator" do
        assert_nothing_raised do
          SymbolOperator.new(:foo, 'in').should_not == 'foo.in'
        end
      end
    end

    context "<=>" do
      should "same field, different operator" do
        (SymbolOperator.new(:foo, 'in') <=> SymbolOperator.new(:foo, 'all')).should ==  1
        (SymbolOperator.new(:foo, 'all') <=> SymbolOperator.new(:foo, 'in')).should == -1
      end

      should "same field same operator" do
        (SymbolOperator.new(:foo, 'in') <=> SymbolOperator.new(:foo, 'in')).should == 0
      end

      should "different field" do
        (SymbolOperator.new(:foo, 'in') <=> SymbolOperator.new(:bar, 'in')).should == 1
      end
    end
  end
end