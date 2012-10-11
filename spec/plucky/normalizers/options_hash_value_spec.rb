require 'helper'

describe Plucky::Normalizers::OptionsHashValue do
  let(:key_normalizer) {
    lambda { |key|
      if key == :id
        :_id
      else
        key.to_sym
      end
    }
  }

  let(:upcasing_normalizer) {
    lambda { |value| value.to_s.upcase }
  }

  let(:default_arguments) {
    {
      :key_normalizer => key_normalizer,
    }
  }

  subject {
    described_class.new(default_arguments)
  }

  it "raises exception if missing key normalizer" do
    expect {
      described_class.new
    }.to raise_error(ArgumentError, "Missing required key :key_normalizer")
  end

  it "allows injecting a new value normalizer" do
    instance = described_class.new(default_arguments.merge({
      :value_normalizers => {
        :some_field => upcasing_normalizer,
      }
    }))

    instance.call(:some_field, 'upcase me').should eq('UPCASE ME')
  end

  context "with :fields key" do
    subject {
      described_class.new(default_arguments.merge({
        :value_normalizers => {
          :fields => upcasing_normalizer
        },
      }))
    }

    it "calls the fields value normalizer" do
      subject.call(:fields, :foo).should eq('FOO')
    end
  end

  context "with :sort key" do
    subject {
      described_class.new(default_arguments.merge({
        :value_normalizers => {
          :sort => upcasing_normalizer
        },
      }))
    }

    it "calls the sort value normalizer" do
      subject.call(:sort, :foo).should eq('FOO')
    end
  end

  context "with :limit key" do
    subject {
      described_class.new(default_arguments.merge({
        :value_normalizers => {
          :limit => upcasing_normalizer
        },
      }))
    }

    it "calls the limit value normalizer" do
      subject.call(:limit, :foo).should eq('FOO')
    end
  end

  context "with :skip key" do
    subject {
      described_class.new(default_arguments.merge({
        :value_normalizers => {
          :skip => upcasing_normalizer
        },
      }))
    }

    it "calls the skip value normalizer" do
      subject.call(:skip, :foo).should eq('FOO')
    end
  end
end
