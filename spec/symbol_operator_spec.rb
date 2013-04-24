require 'helper'

describe SymbolOperator do
  context "SymbolOperator" do
    before  { @operator = SymbolOperator.new(:foo, 'in') }
    subject { @operator }

    it "has field" do
      subject.field.should == :foo
    end

    it "has operator" do
      subject.operator.should == 'in'
    end

    context "==" do
      it "returns true if field and operator are equal" do
        SymbolOperator.new(:foo, 'in').should == SymbolOperator.new(:foo, 'in')
      end

      it "returns false if fields are equal but operators are not" do
        SymbolOperator.new(:foo, 'in').should_not == SymbolOperator.new(:foo, 'all')
      end

      it "returns false if operators are equal but fields are not" do
        SymbolOperator.new(:foo, 'in').should_not == SymbolOperator.new(:bar, 'in')
      end

      it "returns false if neither are equal" do
        SymbolOperator.new(:foo, 'in').should_not == SymbolOperator.new(:bar, 'all')
      end

      it "returns false if other isn't an symbol operator" do
        SymbolOperator.new(:foo, 'in').should_not == 'foo.in'
      end
    end
    
    context "hash" do
      
      it 'returns sum of operator and hash field' do
        SymbolOperator.new(:foo, 'in').hash.should == :foo.hash + 'in'.hash
      end
      
    end
    
    context "<=>" do
      it "returns string comparison of operator for same field, different operator" do
        (SymbolOperator.new(:foo, 'in') <=> SymbolOperator.new(:foo, 'all')).should ==  1
        (SymbolOperator.new(:foo, 'all') <=> SymbolOperator.new(:foo, 'in')).should == -1
      end

      it "returns 0 for same field same operator" do
        (SymbolOperator.new(:foo, 'in') <=> SymbolOperator.new(:foo, 'in')).should == 0
      end

      it "returns 1 for different field" do
        (SymbolOperator.new(:foo, 'in') <=> SymbolOperator.new(:bar, 'in')).should == 1
      end
    end
  end
end
