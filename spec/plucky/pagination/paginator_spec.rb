require 'helper'

describe Plucky::Pagination::Paginator do
  describe "#initialize" do
    context "with total and page" do
      before  { @paginator = described_class.new(20, 2) }
      subject { @paginator }

      it "sets total" do
        subject.total_entries.should == 20
      end

      it "sets page" do
        subject.current_page.should == 2
      end

      it "defaults per_page to 25" do
        subject.per_page.should == 25
      end
    end

    context "with total, page and per_page" do
      before  { @paginator = described_class.new(20, 2, 10) }
      subject { @paginator }

      it "sets total" do
        subject.total_entries.should == 20
      end

      it "sets page" do
        subject.current_page.should == 2
      end

      it "sets per_page" do
        subject.per_page.should == 10
      end
    end

    context "with string values for total, page and per_page" do
      before  { @paginator = described_class.new('20', '2', '10') }
      subject { @paginator }

      it "sets total" do
        subject.total_entries.should == 20
      end

      it "sets page" do
        subject.current_page.should == 2
      end

      it "sets per_page" do
        subject.per_page.should == 10
      end
    end

    context "with page less than 1" do
      before  { @paginator = described_class.new(20, -2, 10) }
      subject { @paginator }

      it "sets page to 1" do
        subject.current_page.should == 1
      end
    end
  end

  it "aliases limit to per_page" do
    described_class.new(30, 2, 30).limit.should == 30
  end

  it "knows total number of pages" do
    described_class.new(43, 2, 7).total_pages.should == 7
    described_class.new(40, 2, 10).total_pages.should == 4
  end

  describe "#out_of_bounds?" do
    it "returns true if current_page is greater than total_pages" do
      described_class.new(2, 3, 1).should be_out_of_bounds
    end

    it "returns false if current page is less than total_pages" do
      described_class.new(2, 1, 1).should_not be_out_of_bounds
    end

    it "returns false if current page equals total_pages" do
      described_class.new(2, 2, 1).should_not be_out_of_bounds
    end
  end

  describe "#previous_page" do
    it "returns nil if there is no page less than current" do
      described_class.new(2, 1, 1).previous_page.should be_nil
    end

    it "returns number less than current page if there is one" do
      described_class.new(2, 2, 1).previous_page.should == 1
    end
  end

  describe "#next_page" do
    it "returns nil if no page greater than current page" do
      described_class.new(2, 2, 1).next_page.should be_nil
    end

    it "returns number greater than current page if there is one" do
      described_class.new(2, 1, 1).next_page.should == 2
    end
  end

  describe "#skip" do
    it "works" do
      described_class.new(30, 3, 10).skip.should == 20
    end

    it "returns aliased to offset for will paginate" do
      described_class.new(30, 3, 10).offset.should == 20
    end
  end
end
