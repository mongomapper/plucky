require 'helper'

class CriteriaHashTest < Test::Unit::TestCase
  include Plucky

  context "Plucky::CriteriaHash" do
    context "#merge" do
      should "work when no keys match" do
        first, second = {:foo => 'bar'}, {:baz => 'wick'}
        CriteriaHash.new(first).merge(second).should == {
          :foo => 'bar',
          :baz => 'wick',
        }
      end

      should "turn matching keys with simple values into array" do
        first, second = {:foo => 'bar'}, {:foo => 'baz'}
        CriteriaHash.new(first).merge(second).should == {
          :foo => %w[bar baz],
        }
      end

      should "unique matching key values" do
        first, second = {:foo => 'bar'}, {:foo => %w(bar baz)}
        CriteriaHash.new(first).merge(second).should == {
          :foo => %w[bar baz],
        }
      end

      should "turn matching keys with $in => arrays to one $in => array of uniq values" do
        first  = {:foo => {'$in' => [1, 2, 3]}}
        second = {:foo => {'$in' => [1, 4, 5]}}
        CriteriaHash.new(first).merge(second).should == {
          :foo => {'$in' => [1, 2, 3, 4, 5]}
        }
      end
    end
  end
end