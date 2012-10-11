require 'helper'
require 'plucky/normalizers/fields_value'

describe Plucky::Normalizers::FieldsValue do
  it "defaults to nil" do
    subject.call(nil).should be_nil
  end

  it "returns nil if empty string" do
    subject.call('').should be_nil
  end

  it "returns nil if empty array" do
    subject.call([]).should be_nil
  end

  it "works with array" do
    subject.call(['one', 'two']).should eq(['one', 'two'])
  end

  # Ruby 1.9.x was sending array [{:age => 20}], instead of hash.
  it "works with array that has one hash" do
    subject.call([{:age => 20}]).should eq({:age => 20})
  end

  it "flattens multi-dimensional array" do
    subject.call([[:one, :two]]).should eq([:one, :two])
  end

  it "works with symbol" do
    subject.call(:one).should eq([:one])
  end

  it "works with array of symbols" do
    subject.call([:one, :two]).should eq([:one, :two])
  end

  it "works with hash" do
    subject.call({:one => 1, :two => -1}).should eq({:one => 1, :two => -1})
  end

  it "converts comma separated list to array" do
    subject.call('one, two').should eq(['one', 'two'])
  end
end
