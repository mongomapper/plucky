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
    end
  end
end