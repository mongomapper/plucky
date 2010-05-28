require 'helper'

class PaginatorTest < Test::Unit::TestCase
  include Plucky::Pagination

  context "Object decorated with Decorator with paginator set" do
    setup do
      @object    = [1, 2, 3, 4]
      @object_id = @object.object_id
      @paginator = Paginator.new(20, 2, 10)
      @object.extend(Decorator)
      @object.paginator(@paginator)
    end
    subject { @object }

    should "be able to get paginator" do
      subject.paginator.should == @paginator
    end

    [:total_entries, :current_page, :per_page, :total_pages, :out_of_bounds?,
     :previous_page, :next_page, :skip, :limit, :offset].each do |method|
      should "delegate #{method} to paginator" do
        subject.send(method).should == @paginator.send(method)
      end
    end

    should "not interfere with other methods on the object" do
      @object.object_id.should  == @object_id
      @object.should            == [1, 2, 3, 4]
      @object.size.should       == 4
      @object.select { |o| o > 2 }.should == [3, 4]
    end
  end
end