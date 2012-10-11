require 'helper'

describe Plucky::Normalizers::CriteriaHashValue do
  let(:criteria_hash) { Plucky::CriteriaHash.new }

  subject {
    described_class.new(criteria_hash)
  }

  context "with a string" do
    it "leaves string values for string keys alone" do
      subject.call(:foo, :foo, 'bar').should eq('bar')
    end

    context "that is actually an object id" do
      it "converts string values to object ids for object id keys" do
        criteria_hash.object_ids = [:_id]
        id = BSON::ObjectId.new
        subject.call(:_id, :_id, id.to_s).should eq(id)
      end
    end
  end

  context "with a time" do
    it "converts times to utc" do
      time = Time.now
      actual = time
      expected = time.utc
      result = subject.call(:foo, :foo, actual)
      result.should be_utc
      result.should eq(expected)
    end

    it "leaves utc times alone" do
      time = Time.now
      actual = time.utc
      expected = time.utc
      result = subject.call(:foo, :foo, actual)
      result.should be_utc
      result.should eq(expected)
    end
  end

  context "with an array" do
    it "defaults to $in" do
      actual = [1,2,3]
      expected = {'$in' => [1,2,3]}
      subject.call(:foo, :foo, actual).should eq(expected)
    end

    it "uses existing modifier if present" do
      actual = {'$all' => [1,2,3]}
      expected = {'$all' => [1,2,3]}
      subject.call(:foo, :foo, actual).should eq(expected)

      actual = {'$any' => [1,2,3]}
      expected = {'$any' => [1,2,3]}
      subject.call(:foo, :foo, actual).should eq(expected)
    end

    it "does not turn value to $in with $or key" do
      actual = [{:numbers => 1}, {:numbers => 2}]
      expected = [{:numbers => 1}, {:numbers => 2}]
      subject.call(:$or, :$or, actual).should eq(expected)
    end

    it "does not turn value to $in with $and key" do
      actual = [{:numbers => 1}, {:numbers => 2}]
      expected = [{:numbers => 1}, {:numbers => 2}]
      subject.call(:$and, :$and, actual).should eq(expected)
    end

    it "does not turn value to $in with $nor key" do
      actual = [{:numbers => 1}, {:numbers => 2}]
      expected = [{:numbers => 1}, {:numbers => 2}]
      subject.call(:$nor, :$nor, actual).should eq(expected)
    end

    it "defaults to $in even with ObjectId keys" do
      actual = [1,2,3]
      expected = {'$in' => [1,2,3]}
      criteria_hash.object_ids = [:mistake_id]
      subject.call(:mistake_id, :mistake_id, actual).should eq(expected)
    end
  end

  context "with a set" do
    it "defaults to $in and convert to array" do
      actual = [1,2,3].to_set
      expected = {'$in' => [1,2,3]}
      subject.call(:numbers, :numbers, actual).should eq(expected)
    end

    it "uses existing modifier if present and convert to array" do
      actual = {'$all' => [1,2,3].to_set}
      expected = {'$all' => [1,2,3]}
      subject.call(:foo, :foo, actual).should eq(expected)

      actual = {'$any' => [1,2,3].to_set}
      expected = {'$any' => [1,2,3]}
      subject.call(:foo, :foo, actual).should eq(expected)
    end
  end

  context "with string object ids for string keys" do
    let(:object_id) { BSON::ObjectId.new }

    it "leaves string ids as strings" do
      subject.call(:_id, :_id, object_id.to_s).should eq(object_id.to_s)
      subject.call(:room_id, :room_id, object_id.to_s).should eq(object_id.to_s)
    end
  end

  context "with string object ids for object id keys" do
    let(:object_id) { BSON::ObjectId.new }

    before do
      criteria_hash.object_ids = [:_id, :room_id]
    end

    it "converts strings to object ids" do
      subject.call(:_id, :_id, object_id.to_s).should eq(object_id)
      subject.call(:room_id, :room_id, object_id.to_s).should eq(object_id)
    end

    context "nested with modifier" do
      let(:oid1) { BSON::ObjectId.new }
      let(:oid2) { BSON::ObjectId.new }
      let(:oids) { [oid1.to_s, oid2.to_s] }

      it "converts strings to object ids" do
        actual = {'$in' => oids}
        expected = {'$in' => [oid1, oid2]}
        subject.call(:_id, :_id, actual).should eq(expected)
      end

      it "does not modify original array of string ids" do
        subject.call(:_id, :_id, {'$in' => oids})
        oids.should == [oid1.to_s, oid2.to_s]
      end
    end
  end

  context "nested clauses" do
    it "knows constant array of operators that take nested queries" do
      described_class::NestingOperators.should == [:$or, :$and, :$nor]
    end

    described_class::NestingOperators.each do |operator|
      context "with #{operator}" do
        it "works with symbol operators" do
          nested1     = {:age.gt   => 12, :age.lt => 20}
          translated1 = {:age      => {'$gt'  => 12, '$lt'  => 20 }}
          nested2     = {:type.nin => ['friend', 'enemy']}
          translated2 = {:type     => {'$nin' => ['friend', 'enemy']}}
          value       = [nested1, nested2]
          expected    = [translated1, translated2]

          subject.call(operator, operator, value).should eq(expected)
        end

        it "honors criteria hash options" do
          nested     = [{:post_id  => '4f5ead6378fca23a13000001'}]
          translated = [{:post_id  => BSON::ObjectId.from_string('4f5ead6378fca23a13000001')}]
          given      = {operator.to_s => [nested]}

          criteria_hash.object_ids = [:post_id]
          subject.call(operator, operator, nested).should eq(translated)
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
        expected    = [translated1, translated3]

        subject.call(:$or, :$or, [nested1, nested3]).should eq(expected)
      end
    end
  end
end
