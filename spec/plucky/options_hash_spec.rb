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

  describe "#[]=" do

    context ":fields" do
      before  { @options = described_class.new }
      subject { @options }

      it "defaults to nil" do
        subject[:fields].should be_nil
      end

      it "returns nil if empty string" do
        subject[:fields] = ''
        subject[:fields].should be_nil
      end

      it "returns nil if empty array" do
        subject[:fields] = []
        subject[:fields].should be_nil
      end

      it "works with array" do
        subject[:fields] = %w[one two]
        subject[:fields].should == %w[one two]
      end

      # Ruby 1.9.1 was sending array [{:age => 20}],
      # instead of hash.
      it "works with array that has one hash" do
        subject[:fields] = [{:age => 20}]
        subject[:fields].should == {:age => 20}
      end

      it "flattens multi-dimensional array" do
        subject[:fields] = [[:one, :two]]
        subject[:fields].should == [:one, :two]
      end

      it "works with symbol" do
        subject[:fields] = :one
        subject[:fields].should == [:one]
      end

      it "works with array of symbols" do
        subject[:fields] = [:one, :two]
        subject[:fields].should == [:one, :two]
      end

      it "works with hash" do
        subject[:fields] = {:one => 1, :two => -1}
        subject[:fields].should == {:one => 1, :two => -1}
      end

      it "converts comma separated list to array" do
        subject[:fields] = 'one, two'
        subject[:fields].should == %w[one two]
      end

      it "converts select" do
        subject[:select] = 'one, two'
        subject[:select].should be_nil
        subject[:fields].should == %w[one two]
      end
    end

    context ":limit" do
      before  { @options = described_class.new }
      subject { @options }

      it "defaults to nil" do
        subject[:limit].should be_nil
      end

      it "uses limit provided" do
        subject[:limit] = 1
        subject[:limit].should == 1
      end

      it "converts string to integer" do
        subject[:limit] = '1'
        subject[:limit].should == 1
      end
    end

    context ":skip" do
      before  { @options = described_class.new }
      subject { @options }

      it "defaults to nil" do
        subject[:skip].should be_nil
      end

      it "uses limit provided" do
        subject[:skip] = 1
        subject[:skip].should == 1
      end

      it "converts string to integer" do
        subject[:skip] = '1'
        subject[:skip].should == 1
      end

      it "returns set from offset" do
        subject[:offset] = '1'
        subject[:offset].should be_nil
        subject[:skip].should == 1
      end
    end

    context ":sort" do
      before  { @options = described_class.new }
      subject { @options }

      it "defaults to nil" do
        subject[:sort].should be_nil
      end

      it "works with natural order ascending" do
        subject[:sort] = {'$natural' => 1}
        subject[:sort].should == {'$natural' => 1}
      end

      it "works with natural order descending" do
        subject[:sort] = {'$natural' => -1}
        subject[:sort].should =={'$natural' => -1}
      end

      it "converts single ascending field (string)" do
        subject[:sort] = 'foo asc'
        subject[:sort].should == [['foo', 1]]

        subject[:sort] = 'foo ASC'
        subject[:sort].should == [['foo', 1]]
      end

      it "converts single descending field (string)" do
        subject[:sort] = 'foo desc'
        subject[:sort].should == [['foo', -1]]

        subject[:sort] = 'foo DESC'
        subject[:sort].should == [['foo', -1]]
      end

      it "converts multiple fields (string)" do
        subject[:sort] = 'foo desc, bar asc'
        subject[:sort].should == [['foo', -1], ['bar', 1]]
      end

      it "converts multiple fields and default no direction to ascending (string)" do
        subject[:sort] = 'foo desc, bar, baz'
        subject[:sort].should == [['foo', -1], ['bar', 1], ['baz', 1]]
      end

      it "converts symbol" do
        subject[:sort] = :name
        subject[:sort] = [['name', 1]]
      end

      it "converts operator" do
        subject[:sort] = :foo.desc
        subject[:sort].should == [['foo', -1]]
      end

      it "converts array of operators" do
        subject[:sort] = [:foo.desc, :bar.asc]
        subject[:sort].should == [['foo', -1], ['bar', 1]]
      end

      it "converts array of symbols" do
        subject[:sort] = [:first_name, :last_name]
        subject[:sort] = [['first_name', 1], ['last_name', 1]]
      end

      it "works with array and one string element" do
        subject[:sort] = ['foo, bar desc']
        subject[:sort].should == [['foo', 1], ['bar', -1]]
      end

      it "works with array of single array" do
        subject[:sort] = [['foo', -1]]
        subject[:sort].should == [['foo', -1]]
      end

      it "works with array of multiple arrays" do
        subject[:sort] = [['foo', -1], ['bar', 1]]
        subject[:sort].should == [['foo', -1], ['bar', 1]]
      end

      it "compacts nil values in array" do
        subject[:sort] = [nil, :foo.desc]
        subject[:sort].should == [['foo', -1]]
      end

      it "converts array with mix of values" do
        subject[:sort] = [:foo.desc, 'bar']
        subject[:sort].should == [['foo', -1], ['bar', 1]]
      end

      it "converts id to _id" do
        subject[:sort] = [:id.asc]
        subject[:sort].should == [['_id', 1]]
      end

      it "converts string with $natural correctly" do
        subject[:sort] = '$natural desc'
        subject[:sort].should == [['$natural', -1]]
      end
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
