require 'helper'

describe Plucky::Normalizers::OptionsHashKey do
  subject {
    described_class.new
  }

  it "changes order to sort" do
    subject.call(:order).should eq(:sort)
  end

  it "changes select to fields" do
    subject.call(:select).should eq(:fields)
  end

  it "changes offset to skip" do
    subject.call(:offset).should eq(:skip)
  end

  it "changes id to _id" do
    subject.call(:id).should eq(:_id)
  end
end
