require 'helper'

class PluckyTest < Test::Unit::TestCase
  context "Plucky" do
    context ".to_object_id" do
      setup do
        @id = BSON::ObjectId.new
      end

      should "convert nil to nil" do
        Plucky.to_object_id(nil).should be_nil
      end

      should "convert blank to nil" do
        Plucky.to_object_id('').should be_nil
      end

      should "leave object id alone" do
        Plucky.to_object_id(@id).should equal(@id)
      end

      should "convert string to object id" do
        Plucky.to_object_id(@id.to_s).should == @id
      end

      should "not convert string that is not legal object id" do
        Plucky.to_object_id('foo').should == 'foo'
        Plucky.to_object_id(1).should == 1
      end
    end

    context "::Methods" do
      should "return array of methods" do
        Plucky::Methods.should == [
          :where, :filter,
          :sort, :order, :reverse,
          :paginate, :per_page, :limit, :skip, :offset,
          :fields, :ignore, :only,
          :each, :find_each, :find_one, :find,
          :count, :size, :distinct,
          :last, :first, :all, :to_a,
          :exists?, :exist?, :empty?,
          :remove,
        ].sort_by(&:to_s)
      end
    end
  end
end