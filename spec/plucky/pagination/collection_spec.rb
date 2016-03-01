require 'helper'

describe Plucky::Pagination::Collection do
  context "Object decorated with Collection with paginator set" do
    before do
      @object    = [1, 2, 3, 4]
      @object_id = @object.object_id
      @paginator = Plucky::Pagination::Paginator.new(20, 2, 10)
    end
    subject { Plucky::Pagination::Collection.new(@object, @paginator) }

    it "knows paginator" do
      subject.paginator.should == @paginator
    end

    [:total_entries, :current_page, :per_page, :total_pages, :out_of_bounds?,
     :previous_page, :next_page, :skip, :limit, :offset].each do |method|
      it "delegates #{method} to paginator" do
        subject.send(method).should == @paginator.send(method)
      end
    end

    it "does not interfere with other methods on the object" do
      @object.object_id.should  == @object_id
      @object.should            == [1, 2, 3, 4]
      @object.size.should       == 4
      @object.select { |o| o > 2 }.should == [3, 4]
    end

    it "delegates missing methods to the paginator" do
      expect(@paginator).to receive(:blather_matter).with('hello', :xyz, 4)
      subject.blather_matter('hello', :xyz, 4)
    end
  end
end
