require 'helper'

describe Plucky::CriteriaHash do
  it "delegates missing methods to the source hash" do
    hash = {:baz => 'wick', :foo => 'bar'}
    criteria = described_class.new(hash)
    criteria[:foo].should == 'bar'
    criteria[:baz].should == 'wick'
    criteria.keys.to_set.should == [:baz, :foo].to_set
  end

  it "handles multiple symbol operators on the same field" do
    described_class.new(:age.gt => 12, :age.lt => 20)[:age].should == {
      '$gt' => 12, '$lt' => 20
    }
  end

  context "#initialize_copy" do
    before do
      @original = described_class.new({
        :comments => {:_id => 1}, :tags => ['mongo', 'ruby'],
      }, :object_ids => [:_id])
      @cloned   = @original.clone
    end

    it "duplicates source hash" do
      @cloned.source.should_not equal(@original.source)
    end

    it "duplicates options hash" do
      @cloned.options.should_not equal(@original.options)
    end

    it "clones duplicable? values" do
      @cloned[:comments].should_not equal(@original[:comments])
      @cloned[:tags].should_not equal(@original[:tags])
    end
  end

  context "#object_ids=" do
    it "works with array" do
      criteria = described_class.new
      criteria.object_ids = [:_id]
      criteria.object_ids.should == [:_id]
    end

    it "flattens multi-dimensional array" do
      criteria = described_class.new
      criteria.object_ids = [[:_id]]
      criteria.object_ids.should == [:_id]
    end

    it "raises argument error if not array" do
      expect { described_class.new.object_ids = {} }.to raise_error(ArgumentError)
      expect { described_class.new.object_ids = nil }.to raise_error(ArgumentError)
      expect { described_class.new.object_ids = 'foo' }.to raise_error(ArgumentError)
    end
  end

  context "#[]=" do
    it "sets each of the conditions pairs" do
      criteria = described_class.new
      criteria[:conditions] = {:_id => 'john', :foo => 'bar'}
      criteria[:_id].should == 'john'
      criteria[:foo].should == 'bar'
    end
  end

  context "#merge" do
    it "works when no keys match" do
      c1 = described_class.new(:foo => 'bar')
      c2 = described_class.new(:baz => 'wick')
      c1.merge(c2).should == described_class.new(:foo => 'bar', :baz => 'wick')
    end

    it "turns matching keys with simple values into array" do
      c1 = described_class.new(:foo => 'bar')
      c2 = described_class.new(:foo => 'baz')
      c1.merge(c2).should == described_class.new(:foo => {'$in' => %w[bar baz]})
    end

    it "uniques matching key values" do
      c1 = described_class.new(:foo => 'bar')
      c2 = described_class.new(:foo => 'bar')
      c1.merge(c2).should == described_class.new(:foo => {'$in' => %w[bar]})
    end

    it "correctly merges arrays and non-arrays" do
      c1 = described_class.new(:foo => 'bar')
      c2 = described_class.new(:foo => %w[bar baz])
      c1.merge(c2).should == described_class.new(:foo => {'$in' => %w[bar baz]})
      c2.merge(c1).should == described_class.new(:foo => {'$in' => %w[bar baz]})
    end

    it "is able to merge two modifier hashes" do
      c1 = described_class.new('$in' => [1, 2])
      c2 = described_class.new('$in' => [2, 3])
      c1.merge(c2).should == described_class.new('$in' => [1, 2, 3])
    end

    it "is able to merge two modifier hashes with hash values" do
      c1 = described_class.new(:arr => {'$elemMatch' => {:foo => 'bar'}})
      c2 = described_class.new(:arr => {'$elemMatch' => {:omg => 'ponies'}})
      c1.merge(c2).should == described_class.new(:arr => {'$elemMatch' => {:foo => 'bar', :omg => 'ponies'}})
    end

    it "merges matching keys with a single modifier" do
      c1 = described_class.new(:foo => {'$in' => [1, 2, 3]})
      c2 = described_class.new(:foo => {'$in' => [1, 4, 5]})
      c1.merge(c2).should == described_class.new(:foo => {'$in' => [1, 2, 3, 4, 5]})
    end

    it "merges matching keys with multiple modifiers" do
      c1 = described_class.new(:foo => {'$in' => [1, 2, 3]})
      c2 = described_class.new(:foo => {'$all' => [1, 4, 5]})
      c1.merge(c2).should == described_class.new(:foo => {'$in' => [1, 2, 3], '$all' => [1, 4, 5]})
    end

    it "does not update mergee" do
      c1 = described_class.new(:foo => 'bar')
      c2 = described_class.new(:foo => 'baz')
      c1.merge(c2).should_not equal(c1)
      c1[:foo].should == 'bar'
    end
  end

  context "#merge!" do
    it "merges and replace" do
      c1 = described_class.new(:foo => 'bar')
      c2 = described_class.new(:foo => 'baz')
      c1.merge!(c2)
      c1[:foo].should == {'$in' => ['bar', 'baz']}
    end
  end

  context "#simple?" do
    it "returns true if only filtering by _id" do
      described_class.new(:_id => 'id').should be_simple
    end

    it "returns true if only filtering by Sci" do
      described_class.new(:_id => 'id', :_type => 'Foo').should be_simple
      described_class.new(:_type => 'Foo', :_id => 'id').should be_simple # reverse order
    end

    it "returns false if querying by more than max number of simple keys" do
      described_class.new(:one => 1, :two => 2, :three => 3).should_not be_simple
    end

    it "returns false if querying by anthing other than _id/Sci" do
      described_class.new(:foo => 'bar').should_not be_simple
    end

    it "returns false if querying only by _type" do
      described_class.new(:_type => 'Foo').should_not be_simple
    end
  end
end
