require 'helper'

describe Plucky::CriteriaHash do
  it "delegates missing methods to the source hash" do
    hash = {:baz => 'wick', :foo => 'bar'}
    criteria = described_class.new(hash)
    criteria[:foo].should == 'bar'
    criteria[:baz].should == 'wick'
    criteria.keys.to_set.should == [:baz, :foo].to_set
  end

  SymbolOperators.each do |operator|
    it "works with #{operator} symbol operator" do
      described_class.new(:age.send(operator) => 21)[:age].should == {"$#{operator}" => 21}
    end
  end

  it "handles multiple symbol operators on the same field" do
    described_class.new(:age.gt => 12, :age.lt => 20)[:age].should == {
      '$gt' => 12, '$lt' => 20
    }
  end

  context "nested clauses" do
    context "::NestingOperators" do
      it "returns array of operators that take nested queries" do
        described_class::NestingOperators.should == [:$or, :$and, :$nor]
      end
    end

    described_class::NestingOperators.each do |operator|
      context "#{operator}" do
        it "works with symbol operators" do
          nested1     = {:age.gt   => 12, :age.lt => 20}
          translated1 = {:age      => {'$gt'  => 12, '$lt'  => 20 }}
          nested2     = {:type.nin => ['friend', 'enemy']}
          translated2 = {:type     => {'$nin' => ['friend', 'enemy']}}

          given       = {operator.to_s => [nested1, nested2]}

          described_class.new(given)[operator].should == [translated1, translated2]
        end

        it "honors criteria hash options" do
          nested     = {:post_id  => '4f5ead6378fca23a13000001'}
          translated = {:post_id  => BSON::ObjectId.from_string('4f5ead6378fca23a13000001')}
          given      = {operator.to_s => [nested]}

          described_class.new(given, :object_ids => [:post_id])[operator].should == [translated]
        end
      end
    end

    context "doubly nested" do
      it "works with symbol operators" do
        nested1     = {:age.gt   => 12, :age.lt => 20}
        translated1 = {:age      => {'$gt' => 12, '$lt' => 20}}
        nested2     = {:type.nin => ['friend', 'enemy']}
        translated2 = {:type     => {'$nin' => ['friend', 'enemy']}}
        nested3     = {'$and'    => [nested2]}
        translated3 = {:$and     => [translated2]}

        given       = {'$or'     => [nested1, nested3]}

        described_class.new(given)[:$or].should == [translated1, translated3]
      end
    end
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
    it "leaves string values for string keys alone" do
      criteria = described_class.new
      criteria[:foo] = 'bar'
      criteria[:foo].should == 'bar'
    end

    it "converts string values to object ids for object id keys" do
      id = BSON::ObjectId.new
      criteria = described_class.new({}, :object_ids => [:_id])
      criteria[:_id] = id.to_s
      criteria[:_id].should == id
    end

    it "converts sets to arrays" do
      criteria = described_class.new
      criteria[:foo] = [1, 2].to_set
      criteria[:foo].should == {'$in' => [1, 2]}
    end

    it "converts times to utc" do
      time = Time.now
      criteria = described_class.new
      criteria[:foo] = time
      criteria[:foo].should be_utc
      criteria[:foo].should == time.utc
    end

    it "converts :id to :_id" do
      criteria = described_class.new
      criteria[:id] = 1
      criteria[:_id].should == 1
      criteria[:id].should be_nil
    end

    it "works with symbol operators" do
      criteria = described_class.new
      criteria[:_id.in] = ['foo']
      criteria[:_id].should == {'$in' => ['foo']}
    end

    it "sets each of the conditions pairs" do
      criteria = described_class.new
      criteria[:conditions] = {:_id => 'john', :foo => 'bar'}
      criteria[:_id].should == 'john'
      criteria[:foo].should == 'bar'
    end
  end

  context "with id key" do
    it "converts to _id" do
      id = BSON::ObjectId.new
      criteria = described_class.new(:id => id)
      criteria[:_id].should == id
      criteria[:id].should be_nil
    end

    it "converts id with symbol operator to _id with modifier" do
      id = BSON::ObjectId.new
      criteria = described_class.new(:id.ne => id)
      criteria[:_id].should == {'$ne' => id}
      criteria[:id].should be_nil
    end
  end

  context "with time value" do
    it "converts to utc if not utc" do
      described_class.new(:created_at => Time.now)[:created_at].utc?.should be(true)
    end

    it "leaves utc alone" do
      described_class.new(:created_at => Time.now.utc)[:created_at].utc?.should be(true)
    end
  end

  context "with array value" do
    it "defaults to $in" do
      described_class.new(:numbers => [1,2,3])[:numbers].should == {'$in' => [1,2,3]}
    end

    it "uses existing modifier if present" do
      described_class.new(:numbers => {'$all' => [1,2,3]})[:numbers].should == {'$all' => [1,2,3]}
      described_class.new(:numbers => {'$any' => [1,2,3]})[:numbers].should == {'$any' => [1,2,3]}
    end

    it "does not turn value to $in with $or key" do
      described_class.new(:$or => [{:numbers => 1}, {:numbers => 2}] )[:$or].should == [{:numbers=>1}, {:numbers=>2}]
    end

    it "does not turn value to $in with $and key" do
      described_class.new(:$and => [{:numbers => 1}, {:numbers => 2}] )[:$and].should == [{:numbers=>1}, {:numbers=>2}]
    end

    it "does not turn value to $in with $nor key" do
      described_class.new(:$nor => [{:numbers => 1}, {:numbers => 2}] )[:$nor].should == [{:numbers=>1}, {:numbers=>2}]
    end

    it "defaults to $in even with ObjectId keys" do
      described_class.new({:mistake_id => [1,2,3]}, :object_ids => [:mistake_id])[:mistake_id].should == {'$in' => [1,2,3]}
    end
  end

  context "with set value" do
    it "defaults to $in and convert to array" do
      described_class.new(:numbers => [1,2,3].to_set)[:numbers].should == {'$in' => [1,2,3]}
    end

    it "uses existing modifier if present and convert to array" do
      described_class.new(:numbers => {'$all' => [1,2,3].to_set})[:numbers].should == {'$all' => [1,2,3]}
      described_class.new(:numbers => {'$any' => [1,2,3].to_set})[:numbers].should == {'$any' => [1,2,3]}
    end
  end

  context "with string ids for string keys" do
    before do
      @id       = BSON::ObjectId.new
      @room_id  = BSON::ObjectId.new
      @criteria = described_class.new(:_id => @id.to_s, :room_id => @room_id.to_s)
    end

    it "leaves string ids as strings" do
      @criteria[:_id].should     == @id.to_s
      @criteria[:room_id].should == @room_id.to_s
      @criteria[:_id].should     be_instance_of(String)
      @criteria[:room_id].should be_instance_of(String)
    end
  end

  context "with string ids for object id keys" do
    before do
      @id       = BSON::ObjectId.new
      @room_id  = BSON::ObjectId.new
    end

    it "converts strings to object ids" do
      criteria = described_class.new({:_id => @id.to_s, :room_id => @room_id.to_s}, :object_ids => [:_id, :room_id])
      criteria[:_id].should     == @id
      criteria[:room_id].should == @room_id
      criteria[:_id].should     be_instance_of(BSON::ObjectId)
      criteria[:room_id].should be_instance_of(BSON::ObjectId)
    end

    it "converts :id with string value to object id value" do
      criteria = described_class.new({:id => @id.to_s}, :object_ids => [:_id])
      criteria[:_id].should == @id
    end
  end

  context "with string ids for object id keys (nested)" do
    before do
      @id1      = BSON::ObjectId.new
      @id2      = BSON::ObjectId.new
      @ids      = [@id1.to_s, @id2.to_s]
      @criteria = described_class.new({:_id => {'$in' => @ids}}, :object_ids => [:_id])
    end

    it "converts strings to object ids" do
      @criteria[:_id].should == {'$in' => [@id1, @id2]}
    end

    it "does not modify original array of string ids" do
      @ids.should == [@id1.to_s, @id2.to_s]
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
    end

    it "returns false if querying by anthing other than _id/Sci" do
      described_class.new(:foo => 'bar').should_not be_simple
    end

    it "returns false if querying only by _type" do
      described_class.new(:_type => 'Foo').should_not be_simple
    end
  end
end
