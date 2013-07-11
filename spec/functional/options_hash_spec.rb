require 'helper'

describe Plucky::OptionsHash do
  subject { described_class.new }

  describe "#[]=" do
    it "changes order to sort" do
      subject[:order] = "foo asc"
      subject[:sort].should == [["foo", 1]]
      subject[:order].should be_nil
    end

    it "changes sort(id) to sort(_id)" do
      subject[:sort] = "id asc"
      subject[:sort].should == [["_id", 1]]
    end

    it "changes select to fields" do
      subject[:select] = [:foo]
      subject[:fields].should == [:foo]
      subject[:select].should be_nil
    end

    it "changes offset to skip" do
      subject[:offset] = 10
      subject[:skip].should == 10
      subject[:offset].should be_nil
    end

    it "changes id to _id" do
      subject[:id] = :foo
      subject[:_id].should == :foo
      subject[:id].should be_nil
    end

    it "does not change the sort field" do
      subject[:order] = :order.asc
      subject[:sort].should == [["order", 1]]
    end
  end
end
