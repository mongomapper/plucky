require 'helper'

class PaginatorTest < Test::Unit::TestCase
  include Plucky::Pagination

  context "#initialize" do
    context "with total and page" do
      setup   { @paginator = Paginator.new(20, 2) }
      subject { @paginator }

      should "set total" do
        subject.total_entries.should == 20
      end

      should "set page" do
        subject.current_page.should == 2
      end

      should "default per_page to 25" do
        subject.per_page.should == 25
      end
    end

    context "with total, page and per_page" do
      setup   { @paginator = Paginator.new(20, 2, 10) }
      subject { @paginator }

      should "set total" do
        subject.total_entries.should == 20
      end

      should "set page" do
        subject.current_page.should == 2
      end

      should "set per_page" do
        subject.per_page.should == 10
      end
    end

    context "with string values for total, page and per_page" do
      setup   { @paginator = Paginator.new('20', '2', '10') }
      subject { @paginator }

      should "set total" do
        subject.total_entries.should == 20
      end

      should "set page" do
        subject.current_page.should == 2
      end

      should "set per_page" do
        subject.per_page.should == 10
      end
    end

    context "with page less than 1" do
      setup   { @paginator = Paginator.new(20, -2, 10) }
      subject { @paginator }

      should "set page to 1" do
        subject.current_page.should == 1
      end
    end
  end

  should "alias limit to per_page" do
    Paginator.new(30, 2, 30).limit.should == 30
  end

  should "be know total number of pages" do
    Paginator.new(43, 2, 7).total_pages.should == 7
    Paginator.new(40, 2, 10).total_pages.should == 4
  end

  context "#out_of_bounds?" do
    should "be true if current_page is greater than total_pages" do
      Paginator.new(2, 3, 1).should be_out_of_bounds
    end

    should "be false if current page is less than total_pages" do
      Paginator.new(2, 1, 1).should_not be_out_of_bounds
    end

    should "be false if current page equals total_pages" do
      Paginator.new(2, 2, 1).should_not be_out_of_bounds
    end
  end

  context "#previous_page" do
    should "be nil if there is no page less than current" do
      Paginator.new(2, 1, 1).previous_page.should be_nil
    end

    should "be number less than current page if there is one" do
      Paginator.new(2, 2, 1).previous_page.should == 1
    end
  end

  context "#next_page" do
    should "be nil if no page greater than current page" do
      Paginator.new(2, 2, 1).next_page.should be_nil
    end

    should "be number greater than current page if there is one" do
      Paginator.new(2, 1, 1).next_page.should == 2
    end
  end

  context "#skip" do
    should "work" do
      Paginator.new(30, 3, 10).skip.should == 20
    end

    should "be aliased to offset for will paginate" do
      Paginator.new(30, 3, 10).offset.should == 20
    end
  end
end