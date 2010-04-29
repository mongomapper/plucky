require 'helper'

class QueryTest < Test::Unit::TestCase
  include Mongo

  context "Converting to criteria" do
    %w{gt lt gte lte ne in nin mod all size where exists}.each do |operator|
      next if operator == 'size' && RUBY_VERSION >= '1.9.1' # 1.9 defines Symbol#size

      should "convert #{operator} conditions" do
        Query.new(:age.send(operator) => 21).criteria.should == {:age => {"$#{operator}" => 21}}
      end
    end

    should "work with simple criteria" do
      Query.new(:foo => 'bar').criteria.should == {:foo => 'bar'}
      Query.new(:foo => 'bar', :baz => 'wick').criteria.should == {:foo => 'bar', :baz => 'wick'}
    end

    context "with id key" do
      should "convert to _id" do
        id = BSON::ObjectID.new
        Query.new(:id => id).criteria.should == {:_id => id}
      end

      should "convert id with symbol operator to _id with modifier" do
        id = BSON::ObjectID.new
        Query.new(:id.ne => id).criteria.should == {:_id => {'$ne' => id}}
      end
    end

    context "with time value" do
      should "convert to utc if not utc" do
        Query.new(:created_at => Time.now).criteria[:created_at].utc?.should be(true)
      end

      should "leave utc alone" do
        Query.new(:created_at => Time.now.utc).criteria[:created_at].utc?.should be(true)
      end
    end

    context "with array value" do
      should "default to $in" do
        Query.new(:numbers => [1,2,3]).criteria.should == {:numbers => {'$in' => [1,2,3]}}
      end

      should "use existing modifier if present" do
        Query.new(:numbers => {'$all' => [1,2,3]}).criteria.should == {:numbers => {'$all' => [1,2,3]}}
        Query.new(:numbers => {'$any' => [1,2,3]}).criteria.should == {:numbers => {'$any' => [1,2,3]}}
      end

      should "work arbitrarily deep" do
        Query.new(:foo => {:bar => [1,2,3]}).criteria.should == {:foo => {:bar => {'$in' => [1,2,3]}}}
        Query.new(:foo => {:bar => {'$any' => [1,2,3]}}).criteria.should == {:foo => {:bar => {'$any' => [1,2,3]}}}
      end
    end

    context "with set value" do
      should "default to $in and convert to array" do
        Query.new(:numbers => Set.new([1,2,3])).criteria.should == {:numbers => {'$in' => [1,2,3]}}
      end

      should "use existing modifier if present and convert to array" do
        Query.new(:numbers => {'$all' => Set.new([1,2,3])}).criteria.should == {:numbers => {'$all' => [1,2,3]}}
        Query.new(:numbers => {'$any' => Set.new([1,2,3])}).criteria.should == {:numbers => {'$any' => [1,2,3]}}
      end
    end
  end

  context "where" do
    should "update criteria" do
      Query.new(:moo => 'cow').where(:foo => 'bar').criteria.should == {:foo => 'bar', :moo => 'cow'}
    end
    
    should "get normalized" do
      Query.new(:moo => 'cow').where(:foo.in => ['bar']).criteria.should == {
        :moo => 'cow', :foo => {'$in' => ['bar']}
      }
    end
  end

  context "select" do
    should "update criteria" do
      Query.new.fields([:foo, :bar, :baz]).options[:fields].should == [:foo, :bar, :baz]
    end
    
    should "get normalized" do
      Query.new(:moo => 'cow').where(:foo.in => ['bar']).criteria.should == {
        :moo => 'cow', :foo => {'$in' => ['bar']}
      }
    end
  end

  context "limit" do
    should "set limit option" do
      Query.new.limit(5).options[:limit].should == 5
    end

    should "override existing limit" do
      Query.new(:limit => 5).limit(15).options[:limit].should == 15
    end
  end

  context "skip" do
    should "set skip option" do
      Query.new.skip(5).options[:skip].should == 5
    end

    should "override existing skip" do
      Query.new(:skip => 5).skip(10).options[:skip].should == 10
    end
  end

  context "ordering" do
    should "single field with ascending direction" do
      sort = [['foo', 1]]
      Query.new(:order => 'foo asc').options[:sort].should == sort
      Query.new(:order => 'foo ASC').options[:sort].should == sort
    end

    should "single field with descending direction" do
      sort = [['foo', -1]]
      Query.new(:order => 'foo desc').options[:sort].should == sort
      Query.new(:order => 'foo DESC').options[:sort].should == sort
    end

    should "convert order operators to mongo sort" do
      Query.new(:order => :foo.asc).options[:sort].should == [['foo', 1]]
      Query.new(:order => :foo.desc).options[:sort].should == [['foo', -1]]
    end

    should "convert array of order operators to mongo sort" do
      Query.new(:order => [:foo.asc, :bar.desc]).options[:sort].should == [['foo', 1], ['bar', -1]]
    end

    should "convert field without direction to ascending" do
      sort = [['foo', 1]]
      Query.new(:order => 'foo').options[:sort].should == sort
    end

    should "convert multiple fields with directions" do
      sort = [['foo', -1], ['bar', 1], ['baz', -1]]
      Query.new(:order => 'foo desc, bar asc, baz desc').options[:sort].should == sort
    end

    should "convert multiple fields with some missing directions" do
      sort = [['foo', -1], ['bar', 1], ['baz', 1]]
      Query.new(:order => 'foo desc, bar, baz').options[:sort].should == sort
    end

    should "just use sort if sort and order are present" do
      sort = [['$natural', 1]]
      Query.new(:sort => sort, :order => 'foo asc').options[:sort].should == sort
    end

    should "normalize id to _id" do
      Query.new(:order => :id.asc).options[:sort].should == [['_id', 1]]
    end

    should "convert natural in order to proper" do
      sort = [['$natural', 1]]
      Query.new(:order => '$natural asc').options[:sort].should == sort
      sort = [['$natural', -1]]
      Query.new(:order => '$natural desc').options[:sort].should == sort
    end

    should "work for natural order ascending" do
      Query.new(:sort => {'$natural' => 1}).options[:sort]['$natural'].should == 1
    end

    should "work for natural order descending" do
      Query.new(:sort => {'$natural' => -1}).options[:sort]['$natural'].should == -1
    end
  end

  context "skip" do
    should "default to 0" do
      Query.new({}).options[:skip].should == 0
    end

    should "use skip provided" do
      Query.new(:skip => 2).options[:skip].should == 2
    end

    should "convert string to integer" do
      Query.new(:skip => '2').options[:skip].should == 2
    end

    should "convert offset to skip" do
      Query.new(:offset => 1).options[:skip].should == 1
    end
  end

  context "limit" do
    should "default to 0" do
      Query.new({}).options[:limit].should == 0
    end

    should "use limit provided" do
      Query.new(:limit => 2).options[:limit].should == 2
    end

    should "convert string to integer" do
      Query.new(:limit => '2').options[:limit].should == 2
    end
  end

  context "fields" do
    should "default to nil" do
      Query.new({}).options[:fields].should be(nil)
    end

    should "be converted to nil if empty string" do
      Query.new(:fields => '').options[:fields].should be(nil)
    end

    should "be converted to nil if []" do
      Query.new(:fields => []).options[:fields].should be(nil)
    end

    should "should work with array" do
      Query.new({:fields => %w(a b)}).options[:fields].should == %w(a b)
    end

    should "convert comma separated list to array" do
      Query.new({:fields => 'a, b'}).options[:fields].should == %w(a b)
    end

    should "also work as select" do
      Query.new(:select => %w(a b)).options[:fields].should == %w(a b)
    end

    should "also work with select as array of symbols" do
      Query.new(:select => [:a, :b]).options[:fields].should == [:a, :b]
    end
  end

  context "Criteria/option auto-detection" do
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

    should "know select is an option" do
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

    should "know offset is an option" do
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

    should "know order is an option" do
      finder = Query.new(:order => 'foo')
      finder.options.keys.should include(:sort)
      finder.criteria.keys.should_not include(:sort)
    end

    should "work with full range of things" do
      query_options = Query.new({
        :foo    => 'bar',
        :baz    => true,
        :sort   => [['foo', 1]],
        :fields => ['foo', 'baz'],
        :limit  => 10,
        :skip   => 10,
      })

      query_options.criteria.should == {
        :foo => 'bar',
        :baz => true,
      }

      query_options.options.should == {
        :sort   => [['foo', 1]],
        :fields => ['foo', 'baz'],
        :limit  => 10,
        :skip   => 10,
      }
    end
  end
end