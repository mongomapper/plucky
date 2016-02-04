require 'helper'

describe Plucky::CriteriaHash do
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
    context "with key and value" do
      let(:key_normalizer)   { lambda { |*args| :normalized_key    } }
      let(:value_normalizer) { lambda { |*args| 'normalized_value' } }

      it "sets normalized key to normalized value in source" do
        criteria = described_class.new({}, :value_normalizer => value_normalizer, :key_normalizer => key_normalizer)
        criteria[:foo] = 'bar'
        criteria.source[:normalized_key].should eq('normalized_value')
      end
    end

    context "with conditions" do
      it "sets each of conditions keys in source" do
        criteria = described_class.new
        criteria[:conditions] = {:_id => 'john', :foo => 'bar'}
        criteria.source[:_id].should eq('john')
        criteria.source[:foo].should eq('bar')
      end
    end

    context "with symbol operators" do
      it "sets nests key with operator and value" do
        criteria = described_class.new
        criteria[:age.gt] = 20
        criteria[:age.lt] = 10
        criteria.source[:age].should eq({:$gt => 20, :$lt => 10})
      end
    end
  end

  context "#merge" do
    it "works when no keys match" do
      c1 = described_class.new(:foo => 'bar')
      c2 = described_class.new(:baz => 'wick')
      c1.merge(c2).source.should eq(:foo => 'bar', :baz => 'wick')
    end

    it "turns matching keys with simple values into array" do
      c1 = described_class.new(:foo => 'bar')
      c2 = described_class.new(:foo => 'baz')
      c1.merge(c2).source.should eq(:foo => {:$in => %w[bar baz]})
    end

    it "uniques matching key values" do
      c1 = described_class.new(:foo => 'bar')
      c2 = described_class.new(:foo => 'bar')
      c1.merge(c2).source.should eq(:foo => 'bar')
    end

    it "correctly merges arrays and non-arrays" do
      c1 = described_class.new(:foo => 'bar')
      c2 = described_class.new(:foo => %w[bar baz])
      c1.merge(c2).source.should eq(:foo => {:$in => %w[bar baz]})
      c2.merge(c1).source.should eq(:foo => {:$in => %w[bar baz]})
    end

    it "correctly merges two bson object ids" do
      id1 = BSON::ObjectId.new
      id2 = BSON::ObjectId.new
      c1 = described_class.new(:foo => id1)
      c2 = described_class.new(:foo => id2)
      c1.merge(c2).source.should eq(:foo => {:$in => [id1, id2]})
    end

    it "correctly merges array and an object id" do
      id1 = BSON::ObjectId.new
      id2 = BSON::ObjectId.new
      c1 = described_class.new(:foo => [id1])
      c2 = described_class.new(:foo => id2)
      c1.merge(c2).source.should eq(:foo => {:$in => [id1, id2]})
      c2.merge(c1).source.should eq(:foo => {:$in => [id1, id2]})
    end

    it "is able to merge two modifier hashes" do
      c1 = described_class.new(:$in => [1, 2])
      c2 = described_class.new(:$in => [2, 3])
      c1.merge(c2).source.should eq(:$in => [1, 2, 3])
    end

    it "is able to merge two modifier hashes with hash values" do
      c1 = described_class.new(:arr => {:$elemMatch => {:foo => 'bar'}})
      c2 = described_class.new(:arr => {:$elemMatch => {:omg => 'ponies'}})
      c1.merge(c2).source.should eq(:arr => {:$elemMatch => {:foo => 'bar', :omg => 'ponies'}})
    end

    it "merges matching keys with a single modifier" do
      c1 = described_class.new(:foo => {:$in => [1, 2, 3]})
      c2 = described_class.new(:foo => {:$in => [1, 4, 5]})
      c1.merge(c2).source.should eq(:foo => {:$in => [1, 2, 3, 4, 5]})
    end

    it "merges matching keys with multiple modifiers" do
      c1 = described_class.new(:foo => {:$in => [1, 2, 3]})
      c2 = described_class.new(:foo => {:$all => [1, 4, 5]})
      c1.merge(c2).source.should eq(:foo => {:$in => [1, 2, 3], :$all => [1, 4, 5]})
    end

    it "does not update mergee" do
      c1 = described_class.new(:foo => 'bar')
      c2 = described_class.new(:foo => 'baz')
      c1.merge(c2).should_not equal(c1)
      c1[:foo].should == 'bar'
    end

    it "merges two hashes with the same key, but nil values as nil" do
      c1 = described_class.new(:foo => nil)
      c2 = described_class.new(:foo => nil)
      c1.merge(c2).source.should == { :foo => nil }
    end

    it "merges two hashes with the same key, but false values as false" do
      c1 = described_class.new(:foo => false)
      c2 = described_class.new(:foo => false)
      c1.merge(c2).source.should == { :foo => false }
    end

    it "merges two hashes with the same key, but different values with $in" do
      c1 = described_class.new(:foo => false)
      c2 = described_class.new(:foo => true)
      c1.merge(c2).source.should == { :foo => { :'$in' => [false, true] } }
    end

    it "merges two hashes with different keys and different values properly" do
      c1 = described_class.new(:foo => 1)
      c2 = described_class.new(:bar => 2)
      c1.merge(c2).source.should == { :foo => 1, :bar => 2 }
    end

    context "given multiple $or clauses" do
      before do
        @c1 = described_class.new(:$or => [{:a => 1}, {:b => 2}])
        @c2 = described_class.new(:$or => [{:a => 3}, {:b => 4}])
        @c3 = described_class.new(:$or => [{:a => 4}, {:b => 4}])
      end

      it "merges two $ors into a compound $and" do
        merged = @c1.merge(@c2)
        merged[:$and].should == [
          {:$or => [{:a => 1}, {:b => 2}]},
          {:$or => [{:a => 3}, {:b => 4}]}
        ]
      end

      it "merges an $and and a $or into a compound $and" do
        merged = @c1.merge(@c2).merge(@c3)
        merged[:$and].should == [
          {:$or => [{:a => 1}, {:b => 2}]},
          {:$or => [{:a => 3}, {:b => 4}]},
          {:$or => [{:a => 4}, {:b => 4}]}
        ]
      end

      it "merges an $or and an $and into a compound $and" do
        merged = @c3.merge @c1.merge(@c2)
        merged[:$and].should == [
          {:$or => [{:a => 1}, {:b => 2}]},
          {:$or => [{:a => 3}, {:b => 4}]},
          {:$or => [{:a => 4}, {:b => 4}]}
        ]
      end
    end
  end

  context "#merge!" do
    it "updates mergee" do
      c1 = described_class.new(:foo => 'bar')
      c2 = described_class.new(:foo => 'baz')
      c1.merge!(c2).should equal(c1)
      c1[:foo].should == {:$in => ['bar', 'baz']}
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
