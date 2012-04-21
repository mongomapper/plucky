require 'helper'

class CriteriaHashTest < Test::Unit::TestCase
  include Plucky

  context "Plucky::CriteriaHash" do
    should "delegate missing methods to the source hash" do
      hash = {:baz => 'wick', :foo => 'bar'}
      criteria = CriteriaHash.new(hash)
      criteria[:foo].should == 'bar'
      criteria[:baz].should == 'wick'
      criteria.keys.to_set.should == [:baz, :foo].to_set
    end

    SymbolOperators.each do |operator|
      should "work with #{operator} symbol operator" do
        CriteriaHash.new(:age.send(operator) => 21)[:age].should == {"$#{operator}" => 21}
      end
    end

    should "handle multiple symbol operators on the same field" do
      CriteriaHash.new(:age.gt => 12, :age.lt => 20)[:age].should == {
        '$gt' => 12, '$lt' => 20
      }
    end

    context "nested clauses" do
      context "::NestingOperators" do
        should "return array of operators that take nested queries" do
          CriteriaHash::NestingOperators.should == [:$or, :$and, :$nor]
        end
      end

      CriteriaHash::NestingOperators.each do |operator|
        context "#{operator}" do
          should "work with symbol operators" do
            nested1     = {:age.gt   => 12, :age.lt => 20}
            translated1 = {:age      => {'$gt'  => 12, '$lt'  => 20 }}
            nested2     = {:type.nin => ['friend', 'enemy']}
            translated2 = {:type     => {'$nin' => ['friend', 'enemy']}}

            given       = {operator.to_s => [nested1, nested2]}

            CriteriaHash.new(given)[operator].should == [translated1, translated2]
          end

          should "honor criteria hash options" do
            nested     = {:post_id  => '4f5ead6378fca23a13000001'}
            translated = {:post_id  => BSON::ObjectId.from_string('4f5ead6378fca23a13000001')}
            given      = {operator.to_s => [nested]}

            CriteriaHash.new(given, :object_ids => [:post_id])[operator].should == [translated]
          end
        end
      end

      context "doubly nested" do
        should "work with symbol operators" do
          nested1     = {:age.gt   => 12, :age.lt => 20}
          translated1 = {:age      => {'$gt' => 12, '$lt' => 20}}
          nested2     = {:type.nin => ['friend', 'enemy']}
          translated2 = {:type     => {'$nin' => ['friend', 'enemy']}}
          nested3     = {'$and'    => [nested2]}
          translated3 = {:$and     => [translated2]}

          given       = {'$or'     => [nested1, nested3]}

          CriteriaHash.new(given)[:$or].should == [translated1, translated3]
        end
      end
    end

    context "#initialize_copy" do
      setup do
        @original = CriteriaHash.new({
          :comments => {:_id => 1}, :tags => ['mongo', 'ruby'],
        }, :object_ids => [:_id])
        @cloned   = @original.clone
      end

      should "duplicate source hash" do
        @cloned.source.should_not equal(@original.source)
      end

      should "duplicate options hash" do
        @cloned.options.should_not equal(@original.options)
      end

      should "clone duplicable? values" do
        @cloned[:comments].should_not equal(@original[:comments])
        @cloned[:tags].should_not equal(@original[:tags])
      end
    end

    context "#object_ids=" do
      should "work with array" do
        criteria = CriteriaHash.new
        criteria.object_ids = [:_id]
        criteria.object_ids.should == [:_id]
      end

      should "flatten multi-dimensional array" do
        criteria = CriteriaHash.new
        criteria.object_ids = [[:_id]]
        criteria.object_ids.should == [:_id]
      end

      should "raise argument error if not array" do
        assert_raises(ArgumentError) { CriteriaHash.new.object_ids = {} }
        assert_raises(ArgumentError) { CriteriaHash.new.object_ids = nil }
        assert_raises(ArgumentError) { CriteriaHash.new.object_ids = 'foo' }
      end
    end

    context "#[]=" do
      should "leave string values for string keys alone" do
        criteria = CriteriaHash.new
        criteria[:foo] = 'bar'
        criteria[:foo].should == 'bar'
      end

      should "convert string values to object ids for object id keys" do
        id = BSON::ObjectId.new
        criteria = CriteriaHash.new({}, :object_ids => [:_id])
        criteria[:_id] = id.to_s
        criteria[:_id].should == id
      end

      should "convert sets to arrays" do
        criteria = CriteriaHash.new
        criteria[:foo] = [1, 2].to_set
        criteria[:foo].should == {'$in' => [1, 2]}
      end

      should "convert times to utc" do
        time = Time.now
        criteria = CriteriaHash.new
        criteria[:foo] = time
        criteria[:foo].should be_utc
        criteria[:foo].should == time.utc
      end

      should "convert :id to :_id" do
        criteria = CriteriaHash.new
        criteria[:id] = 1
        criteria[:_id].should == 1
        criteria[:id].should be_nil
      end

      should "work with symbol operators" do
        criteria = CriteriaHash.new
        criteria[:_id.in] = ['foo']
        criteria[:_id].should == {'$in' => ['foo']}
      end

      should "set each of the conditions pairs" do
        criteria = CriteriaHash.new
        criteria[:conditions] = {:_id => 'john', :foo => 'bar'}
        criteria[:_id].should == 'john'
        criteria[:foo].should == 'bar'
      end
    end

    context "with id key" do
      should "convert to _id" do
        id = BSON::ObjectId.new
        criteria = CriteriaHash.new(:id => id)
        criteria[:_id].should == id
        criteria[:id].should be_nil
      end

      should "convert id with symbol operator to _id with modifier" do
        id = BSON::ObjectId.new
        criteria = CriteriaHash.new(:id.ne => id)
        criteria[:_id].should == {'$ne' => id}
        criteria[:id].should be_nil
      end
    end

    context "with time value" do
      should "convert to utc if not utc" do
        CriteriaHash.new(:created_at => Time.now)[:created_at].utc?.should be(true)
      end

      should "leave utc alone" do
        CriteriaHash.new(:created_at => Time.now.utc)[:created_at].utc?.should be(true)
      end
    end

    context "with array value" do
      should "default to $in" do
        CriteriaHash.new(:numbers => [1,2,3])[:numbers].should == {'$in' => [1,2,3]}
      end

      should "use existing modifier if present" do
        CriteriaHash.new(:numbers => {'$all' => [1,2,3]})[:numbers].should == {'$all' => [1,2,3]}
        CriteriaHash.new(:numbers => {'$any' => [1,2,3]})[:numbers].should == {'$any' => [1,2,3]}
      end

      should "not turn value to $in with $or key" do
        CriteriaHash.new(:$or => [{:numbers => 1}, {:numbers => 2}] )[:$or].should == [{:numbers=>1}, {:numbers=>2}]
      end

      should "not turn value to $in with $and key" do
        CriteriaHash.new(:$and => [{:numbers => 1}, {:numbers => 2}] )[:$and].should == [{:numbers=>1}, {:numbers=>2}]
      end

      should "not turn value to $in with $nor key" do
        CriteriaHash.new(:$nor => [{:numbers => 1}, {:numbers => 2}] )[:$nor].should == [{:numbers=>1}, {:numbers=>2}]
      end

      should "default to $in even with ObjectId keys" do
        CriteriaHash.new({:mistake_id => [1,2,3]}, :object_ids => [:mistake_id])[:mistake_id].should == {'$in' => [1,2,3]}
      end
    end

    context "with set value" do
      should "default to $in and convert to array" do
        CriteriaHash.new(:numbers => [1,2,3].to_set)[:numbers].should == {'$in' => [1,2,3]}
      end

      should "use existing modifier if present and convert to array" do
        CriteriaHash.new(:numbers => {'$all' => [1,2,3].to_set})[:numbers].should == {'$all' => [1,2,3]}
        CriteriaHash.new(:numbers => {'$any' => [1,2,3].to_set})[:numbers].should == {'$any' => [1,2,3]}
      end
    end

    context "with string ids for string keys" do
      setup do
        @id       = BSON::ObjectId.new
        @room_id  = BSON::ObjectId.new
        @criteria = CriteriaHash.new(:_id => @id.to_s, :room_id => @room_id.to_s)
      end

      should "leave string ids as strings" do
        @criteria[:_id].should     == @id.to_s
        @criteria[:room_id].should == @room_id.to_s
        @criteria[:_id].should     be_instance_of(String)
        @criteria[:room_id].should be_instance_of(String)
      end
    end

    context "with string ids for object id keys" do
      setup do
        @id       = BSON::ObjectId.new
        @room_id  = BSON::ObjectId.new
      end

      should "convert strings to object ids" do
        criteria = CriteriaHash.new({:_id => @id.to_s, :room_id => @room_id.to_s}, :object_ids => [:_id, :room_id])
        criteria[:_id].should     == @id
        criteria[:room_id].should == @room_id
        criteria[:_id].should     be_instance_of(BSON::ObjectId)
        criteria[:room_id].should be_instance_of(BSON::ObjectId)
      end

      should "convert :id with string value to object id value" do
        criteria = CriteriaHash.new({:id => @id.to_s}, :object_ids => [:_id])
        criteria[:_id].should == @id
      end
    end

    context "with string ids for object id keys (nested)" do
      setup do
        @id1      = BSON::ObjectId.new
        @id2      = BSON::ObjectId.new
        @ids      = [@id1.to_s, @id2.to_s]
        @criteria = CriteriaHash.new({:_id => {'$in' => @ids}}, :object_ids => [:_id])
      end

      should "convert strings to object ids" do
        @criteria[:_id].should == {'$in' => [@id1, @id2]}
      end

      should "not modify original array of string ids" do
        @ids.should == [@id1.to_s, @id2.to_s]
      end
    end

    context "#merge" do
      should "work when no keys match" do
        c1 = CriteriaHash.new(:foo => 'bar')
        c2 = CriteriaHash.new(:baz => 'wick')
        c1.merge(c2).should == CriteriaHash.new(:foo => 'bar', :baz => 'wick')
      end

      should "turn matching keys with simple values into array" do
        c1 = CriteriaHash.new(:foo => 'bar')
        c2 = CriteriaHash.new(:foo => 'baz')
        c1.merge(c2).should == CriteriaHash.new(:foo => {'$in' => %w[bar baz]})
      end

      should "unique matching key values" do
        c1 = CriteriaHash.new(:foo => 'bar')
        c2 = CriteriaHash.new(:foo => 'bar')
        c1.merge(c2).should == CriteriaHash.new(:foo => {'$in' => %w[bar]})
      end

      should "correctly merge arrays and non-arrays" do
        c1 = CriteriaHash.new(:foo => 'bar')
        c2 = CriteriaHash.new(:foo => %w[bar baz])
        c1.merge(c2).should == CriteriaHash.new(:foo => {'$in' => %w[bar baz]})
        c2.merge(c1).should == CriteriaHash.new(:foo => {'$in' => %w[bar baz]})
      end

      should "be able to merge two modifier hashes" do
        c1 = CriteriaHash.new('$in' => [1, 2])
        c2 = CriteriaHash.new('$in' => [2, 3])
        c1.merge(c2).should == CriteriaHash.new('$in' => [1, 2, 3])
      end

      should "merge matching keys with a single modifier" do
        c1 = CriteriaHash.new(:foo => {'$in' => [1, 2, 3]})
        c2 = CriteriaHash.new(:foo => {'$in' => [1, 4, 5]})
        c1.merge(c2).should == CriteriaHash.new(:foo => {'$in' => [1, 2, 3, 4, 5]})
      end

      should "merge matching keys with multiple modifiers" do
        c1 = CriteriaHash.new(:foo => {'$in' => [1, 2, 3]})
        c2 = CriteriaHash.new(:foo => {'$all' => [1, 4, 5]})
        c1.merge(c2).should == CriteriaHash.new(:foo => {'$in' => [1, 2, 3], '$all' => [1, 4, 5]})
      end

      should "not update mergee" do
        c1 = CriteriaHash.new(:foo => 'bar')
        c2 = CriteriaHash.new(:foo => 'baz')
        c1.merge(c2).should_not equal(c1)
        c1[:foo].should == 'bar'
      end
    end

    context "#merge!" do
      should "merge and replace" do
        c1 = CriteriaHash.new(:foo => 'bar')
        c2 = CriteriaHash.new(:foo => 'baz')
        c1.merge!(c2)
        c1[:foo].should == {'$in' => ['bar', 'baz']}
      end
    end

    context "#simple?" do
      should "be true if only filtering by _id" do
        CriteriaHash.new(:_id => 'id').should be_simple
      end

      should "be true if only filtering by Sci" do
        CriteriaHash.new(:_id => 'id', :_type => 'Foo').should be_simple
      end

      should "be false if querying by anthing other than _id/Sci" do
        CriteriaHash.new(:foo => 'bar').should_not be_simple
      end

      should "be false if querying only by _type" do
        CriteriaHash.new(:_type => 'Foo').should_not be_simple
      end
    end
  end
end
