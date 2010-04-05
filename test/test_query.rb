require 'helper'

class QueryTest < Test::Unit::TestCase
  include Mongo

  context "Converting to criteria" do
    %w{gt lt gte lte ne in nin mod all size where exists}.each do |operator|
      next if operator == 'size' && RUBY_VERSION >= '1.9.1' # 1.9 defines Symbol#size

      should "convert #{operator} conditions" do
        Query.new(:age.send(operator) => 21).criteria.should == {
          :age => {"$#{operator}" => 21}
        }
      end
    end

    should "work with simple criteria" do
      Query.new(:foo => 'bar').criteria.should == {
        :foo => 'bar'
      }

      Query.new(:foo => 'bar', :baz => 'wick').criteria.should == {
        :foo => 'bar',
        :baz => 'wick',
      }
    end

    should "convert id to _id" do
      id = Mongo::ObjectID.new
      Query.new(:id => id).criteria.should == {:_id => id}
    end

    should "convert id with symbol operator to _id with modifier" do
      id = Mongo::ObjectID.new
      Query.new(:id.ne => id).criteria.should == {
        :_id => {'$ne' => id}
      }
    end

    should "convert times to utc if they aren't already" do
      time = Time.now
      criteria = Query.new(:created_at => time).criteria
      criteria[:created_at].utc?.should be(true)
    end

    should "not funk with times already in utc" do
      time = Time.now.utc
      criteria = Query.new(:created_at => time).criteria
      criteria[:created_at].utc?.should be(true)
      criteria[:created_at].should == time
    end
  end

  context "Condition auto-detection" do
    should "know :conditions are criteria" do
      finder = Query.new(:conditions => {:foo => 'bar'})
      finder.criteria.should == {:foo => 'bar'}
      finder.options.keys.should_not include(:conditions)
    end

    should "know fields is an option" do
      finder = Query.new(:fields => ['foo'])
      finder.options[:fields].should == ['foo']
      finder.criteria.keys.should_not include(:fields)
    end

    should_eventually "know select is an option" do
      finder = Query.new(:select => 'foo')
      finder.options.keys.should include(:sort)
      finder.criteria.keys.should_not include(:select)
      finder.criteria.keys.should_not include(:fields)
    end

    should "know skip is an option" do
      finder = Query.new(:skip => 10)
      finder.options[:skip].should == 10
      finder.criteria.keys.should_not include(:skip)
    end

    # offset gets converted to skip so just checking keys
    should_eventually "know offset is an option" do
      finder = Query.new(:offset => 10)
      finder.options.keys.should include(:skip)
      finder.criteria.keys.should_not include(:skip)
      finder.criteria.keys.should_not include(:offset)
    end

    should "know limit is an option" do
      finder = Query.new(:limit => 10)
      finder.options[:limit].should == 10
      finder.criteria.keys.should_not include(:limit)
    end

    should "know sort is an option" do
      finder = Query.new(:sort => [['foo', 1]])
      finder.options[:sort].should == [['foo', 1]]
      finder.criteria.keys.should_not include(:sort)
    end

    should_eventually "know order is an option" do
      finder = Query.new(:order => 'foo')
      finder.options.keys.should include(:sort)
      finder.criteria.keys.should_not include(:sort)
    end

    should "work with full range of things" do
      query_options = Query.new({
        :foo => 'bar',
        :baz => true,
        :sort => [['foo', 1]],
        :fields => ['foo', 'baz'],
        :limit => 10,
        :skip => 10,
      })

      query_options.criteria.should == {
        :foo => 'bar',
        :baz => true,
      }

      query_options.options.should == {
        :sort => [['foo', 1]],
        :fields => ['foo', 'baz'],
        :limit => 10,
        :skip => 10,
      }
    end
  end
end