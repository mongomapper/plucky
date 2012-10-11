require 'helper'

describe Plucky::OptionsHash do
  it "delegates missing methods to the source hash" do
    hash = {:limit => 1, :skip => 1}
    options = described_class.new(hash)
    options[:skip].should      == 1
    options[:limit].should     == 1
    options.keys.to_set.should == [:limit, :skip].to_set
  end

  describe "#initialize_copy" do
    before do
      @original = described_class.new(:fields => {:name => true}, :sort => :name, :limit => 10)
      @cloned   = @original.clone
    end

    it "duplicates source hash" do
      @cloned.source.should_not equal(@original.source)
    end

    it "clones duplicable? values" do
      @cloned[:fields].should_not equal(@original[:fields])
      @cloned[:sort].should_not equal(@original[:sort])
    end
  end

  describe "#fields?" do
    it "returns true if fields have been selected" do
      described_class.new(:fields => :name).fields?.should be(true)
    end

    it "returns false if no fields have been selected" do
      described_class.new.fields?.should be(false)
    end
  end

  describe "#merge" do
    before do
      @o1 = described_class.new(:skip => 5, :sort => :name)
      @o2 = described_class.new(:limit => 10, :skip => 15)
      @merged = @o1.merge(@o2)
    end

    it "overrides options in first with options in second" do
      @merged.should == described_class.new(:limit => 10, :skip => 15, :sort => :name)
    end

    it "returns new instance and not change either of the merged" do
      @o1[:skip].should == 5
      @o2[:sort].should be_nil
      @merged.should_not equal(@o1)
      @merged.should_not equal(@o2)
    end
  end

  describe "#merge!" do
    before do
      @o1 = described_class.new(:skip => 5, :sort => :name)
      @o2 = described_class.new(:limit => 10, :skip => 15)
      @merged = @o1.merge!(@o2)
    end

    it "overrides options in first with options in second" do
      @merged.should == described_class.new(:limit => 10, :skip => 15, :sort => :name)
    end

    it "just updates the first" do
      @merged.should equal(@o1)
    end
  end
end
