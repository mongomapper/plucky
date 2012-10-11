require 'helper'
require 'plucky/normalizers/integer'

describe Plucky::Normalizers::Integer do
  context "with nil" do
    it "returns nil" do
      subject.call(nil).should be_nil
    end
  end

  context "with an integer" do
    it "returns an integer" do
      subject.call(1).should be(1)
      subject.call(3232).should be(3232)
    end
  end

  context "with a string" do
    it "returns a string" do
      subject.call('1').should be(1)
      subject.call('3232').should be(3232)
    end
  end
end
