require 'helper'
require 'plucky/normalizers/sort_value'

describe Plucky::Normalizers::SortValue do
  let(:key_normalizer) {
    Plucky::Normalizers::HashKey.new({:id => :_id})
  }

  subject {
    described_class.new({
      :key_normalizer => key_normalizer,
    })
  }

  it "raises exception if missing key normalizer" do
    expect {
      described_class.new
    }.to raise_error(ArgumentError, "Missing required key :key_normalizer")
  end

  it "defaults to nil" do
    subject.call(nil).should eq(nil)
  end

  it "works with natural order ascending" do
    subject.call('$natural' => 1).should eq('$natural' => 1)
  end

  it "works with natural order descending" do
    subject.call('$natural' => -1).should eq('$natural' => -1)
  end

  it "converts single ascending field (string)" do
    subject.call('foo asc').should eq({'foo' => 1})
    subject.call('foo ASC').should eq({'foo' => 1})
  end

  it "converts single descending field (string)" do
    subject.call('foo desc').should eq({'foo' => -1})
    subject.call('foo DESC').should eq({'foo' => -1})
  end

  it "converts multiple fields (string)" do
    subject.call('foo desc, bar asc').should eq({'foo' => -1, 'bar' => 1})
  end

  it "converts multiple fields and default no direction to ascending (string)" do
    subject.call('foo desc, bar, baz').should eq({'foo' => -1, 'bar' => 1, 'baz' => 1})
  end

  it "converts symbol" do
    subject.call(:name).should eq({'name' => 1})
  end

  it "converts operator" do
    subject.call(:foo.desc).should eq({'foo' => -1})
  end

  it "converts array of operators" do
    subject.call([:foo.desc, :bar.asc]).should eq({'foo' => -1, 'bar' => 1})
  end

  it "converts array of symbols" do
    subject.call([:first_name, :last_name]).should eq({'first_name' => 1, 'last_name' => 1})
  end

  it "works with array and one string element" do
    subject.call(['foo, bar desc']).should eq({'foo' => 1, 'bar' => -1})
  end

  it "works with array of single array" do
    subject.call([['foo', -1]]).should eq({'foo' => -1})
  end

  it "works with array of multiple arrays" do
    subject.call([['foo', -1], ['bar', 1]]).should eq({'foo' => -1, 'bar' => 1})
  end

  it "compacts nil values in array" do
    subject.call([nil, :foo.desc]).should eq({'foo' => -1})
  end

  it "converts array with mix of values" do
    subject.call([:foo.desc, 'bar']).should eq({'foo' => -1, 'bar' => 1})
  end

  it "converts keys based on key normalizer" do
    subject.call([:id.asc]).should eq({'_id' => 1})
  end

  it "doesn't convert keys like :sort to :order via key normalizer" do
    subject.call(:order.asc).should eq({'order' => 1})
  end

  it "converts string with $natural correctly" do
    subject.call('$natural desc').should eq({'$natural' => -1})
  end
end
