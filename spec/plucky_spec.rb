require 'helper'

describe Plucky do
  describe ".to_object_id" do
    before do
      @id = BSON::ObjectId.new
    end

    it "converts nil to nil" do
      Plucky.to_object_id(nil).should be_nil
    end

    it "converts blank to nil" do
      Plucky.to_object_id('').should be_nil
    end

    it "leaves object id alone" do
      Plucky.to_object_id(@id).should equal(@id)
    end

    it "converts string to object id" do
      Plucky.to_object_id(@id.to_s).should == @id
    end

    it "not convert string that is not legal object id" do
      Plucky.to_object_id('foo').should == 'foo'
      Plucky.to_object_id(1).should == 1
    end
  end

  describe ".modifier?" do
    context "with a string" do
      it "returns true if modifier" do
        Plucky.modifier?('$in').should == true
      end

      it "returns false if not modifier" do
        Plucky.modifier?('nope').should == false
      end
    end

    context "with a symbol" do
      it "returns true if modifier" do
        Plucky.modifier?(:$in).should == true
      end

      it "returns false if not modifier" do
        Plucky.modifier?(:nope).should == false
      end
    end
  end

  describe "::Methods" do
    it "returns array of methods" do
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
