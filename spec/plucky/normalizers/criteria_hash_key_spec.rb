require 'helper'

describe Plucky::Normalizers::CriteriaHashKey do
  subject {
    described_class.new
  }

  context "with a string" do
    it "returns symbol" do
      subject.call('foo').should eq(:foo)
    end
  end

  context "with a symbol" do
    it "returns symbol" do
      subject.call(:foo).should eq(:foo)
    end
  end

  context "with :id" do
    it "returns :_id" do
      subject.call(:id).should eq(:_id)
    end
  end

  it "returns key if something weird" do
    subject.call(['crazytown']).should eq(['crazytown'])
  end

  SymbolOperators.each do |operator|
    context "with #{operator} symbol operator" do
      it "returns field" do
        subject.call(:age.send(operator)).should eq(:age)
      end
    end
  end
end
