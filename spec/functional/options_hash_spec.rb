require 'helper'

describe Plucky::OptionsHash do
  subject { described_class.new }

  describe "#[]=" do
    it "changes order to sort" do
      subject[:order] = "foo asc"
      expect(subject[:sort]).to eql({"foo" => 1})
      expect(subject[:order]).to be_nil
    end

    it "changes sort(id) to sort(_id)" do
      subject[:sort] = "id asc"
      expect(subject[:sort]).to eql({"_id" => 1})
    end

    it "changes select to fields" do
      subject[:select] = [:foo]
      expect(subject[:fields]).to eql([:foo])
      expect(subject[:select]).to be_nil
    end

    it "changes offset to skip" do
      subject[:offset] = 10
      expect(subject[:skip]).to eql(10)
      expect(subject[:offset]).to be_nil
    end

    it "changes id to _id" do
      subject[:id] = :foo
      expect(subject[:_id]).to eql(:foo)
      expect(subject[:id]).to be_nil
    end

    it "does not change the sort field" do
      subject[:order] = :order.asc
      expect(subject[:sort]).to eql({"order" => 1})
    end
  end
end
