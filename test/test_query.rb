require 'helper'

class QueryTest < Test::Unit::TestCase
  include Plucky

  context "Converting to criteria" do
    %w{gt lt gte lte ne in nin mod all size exists}.each do |operator|
      next if operator == 'size' && RUBY_VERSION >= '1.9.1' # 1.9 defines Symbol#size

      should "convert #{operator} conditions" do
        Query.new(:age.send(operator) => 21).criteria.should == {:age => {"$#{operator}" => 21}}
      end
    end

    should "work with simple criteria" do
      Query.new(:foo => 'bar').criteria.should == {:foo => 'bar'}
      Query.new(:foo => 'bar', :baz => 'wick').criteria.should == {:foo => 'bar', :baz => 'wick'}
    end

    should "work with multiple symbol operators on the same field" do
      Query.new(:position.gt => 0, :position.lte => 10).criteria.should == {
        :position => {"$gt" => 0, "$lte" => 10}
      }
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

  context "#[]" do
    should "return value if key in criteria (symbol)" do
      Query.new(:count => 1)[:count].should == 1
    end

    should "return value if key in criteria (string)" do
      Query.new(:count => 1)['count'].should == 1
    end

    should "return nil if key not in criteria" do
      Query.new[:count].should be_nil
    end
  end

  context "#[]=" do
    setup { @query = Query.new }

    should "set the value of the given criteria key" do
      @query[:count] = 1
      @query[:count].should == 1
    end
    
    should "overwrite value if key already exists" do
      @query[:count] = 1
      @query[:count] = 2
      @query[:count].should == 2
    end
    
    should "normalize value" do
      now = Time.now
      @query[:published_at] = now
      @query[:published_at].should == now.utc
    end
  end

  context "#merge" do
    should "overwrite options" do
      query1 = Query.new(:skip => 5, :limit => 5)
      query2 = Query.new(:skip => 10, :limit => 10)
      new_query = query1.merge(query2)
      new_query.options[:skip].should == 10
      new_query.options[:limit].should == 10
    end

    should "merge when no criteria match" do
      query1 = Query.new(:foo => 'bar')
      query2 = Query.new(:baz => 'wick')
      new_query = query1.merge(query2)
      new_query.criteria.should == {:foo => 'bar', :baz => 'wick'}
    end

    should "merge exact matches to $in with array" do
      query1 = Query.new(:foo => 'bar')
      query2 = Query.new(:foo => 'baz')
      query3 = Query.new(:foo => 'wick')
      new_query = query1.merge(query2).merge(query3)
      new_query.criteria.should == {:foo => {'$in' => ['bar', 'baz', 'wick']}}
    end

    should "merge $in arrays" do
      query1 = Query.new(:foo => [1, 2])
      query2 = Query.new(:foo => [3, 4, 5])
      query3 = Query.new(:foo => [6])
      new_query = query1.merge(query2).merge(query3)
      new_query.criteria.should == {:foo => {'$in' => [1, 2, 3, 4, 5, 6]}}
    end
  end

  context "#filter" do
    should "update criteria" do
      Query.new(:moo => 'cow').filter(:foo => 'bar').criteria.should == {:foo => 'bar', :moo => 'cow'}
    end

    should "get normalized" do
      Query.new(:moo => 'cow').filter(:foo.in => ['bar']).criteria.should == {
        :moo => 'cow', :foo => {'$in' => ['bar']}
      }
    end
  end

  context "#where" do
    should "update criteria with $where statement" do
      Query.new.where('this.writer_id = 1 || this.editor_id = 1').criteria.should == {
        '$where' => 'this.writer_id = 1 || this.editor_id = 1'
      }
    end
  end

  context "#fields" do
    should "update options (with array)" do
      Query.new.fields([:foo, :bar, :baz]).options[:fields].should == [:foo, :bar, :baz]
    end

    should "update options (with hash)" do
      Query.new.fields(:foo => 1, :bar => 0).options[:fields].should == {:foo => 1, :bar => 0}
    end
  end

  context "#limit" do
    should "set limit option" do
      Query.new.limit(5).options[:limit].should == 5
    end

    should "override existing limit" do
      Query.new(:limit => 5).limit(15).options[:limit].should == 15
    end
  end

  context "#skip" do
    should "set skip option" do
      Query.new.skip(5).options[:skip].should == 5
    end

    should "override existing skip" do
      Query.new(:skip => 5).skip(10).options[:skip].should == 10
    end
  end

  context "#update" do
    should "split and update criteria and options" do
      query = Query.new(:foo => 'bar')
      query.update(:bar => 'baz', :skip => 5)
      query.criteria.should == {:foo => 'bar', :bar => 'baz'}
      query.options[:skip].should == 5
    end
  end

  context "order option" do
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
      query = Query.new(:order => :foo.asc)
      query.options[:sort].should == [['foo', 1]]
      query.options[:order].should be_nil

      query = Query.new(:order => :foo.desc)
      query.options[:sort].should == [['foo', -1]]
      query.options[:order].should be_nil
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

    should "normalize id to _id" do
      Query.new(:order => :id.asc).options[:sort].should == [['_id', 1]]
    end

    should "convert natural in order to proper" do
      sort = [['$natural', 1]]
      Query.new(:order => '$natural asc').options[:sort].should == sort
      sort = [['$natural', -1]]
      Query.new(:order => '$natural desc').options[:sort].should == sort
    end
  end

  context "sort option" do
    should "work for natural order ascending" do
      Query.new(:sort => {'$natural' => 1}).options[:sort]['$natural'].should == 1
    end

    should "work for natural order descending" do
      Query.new(:sort => {'$natural' => -1}).options[:sort]['$natural'].should == -1
    end

    should "should be used if both sort and order are present" do
      sort = [['$natural', 1]]
      Query.new(:sort => sort, :order => 'foo asc').options[:sort].should == sort
    end
  end

  context "#reverse" do
    should "reverse the sort order" do
      query = Query.new(:order => 'foo asc, bar desc')
      query.reverse.options[:sort].should == [['foo', -1], ['bar', 1]]
    end
  end

  context "skip option" do
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

  context "limit option" do
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

  context "fields option" do
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

    {
      :fields     => ['foo'],
      :sort       => 'foo',
      :hint       => '',
      :skip       => 0,
      :limit      => 0,
      :batch_size => 0,
      :timeout    => 0,
    }.each do |option, value|
      should "know #{option} is an option" do
        finder = Query.new(option => value)
        finder.options[option].should == value
        finder.criteria.keys.should_not include(option)
      end
    end

    should "know select is an option and remove it from options" do
      finder = Query.new(:select => 'foo')
      finder.options[:fields].should == ['foo']
      finder.criteria.keys.should_not include(:select)
      finder.options.keys.should_not  include(:select)
    end

    should "know order is an option and remove it from options" do
      finder = Query.new(:order => 'foo')
      finder.options[:sort].should == [['foo', 1]]
      finder.criteria.keys.should_not include(:order)
      finder.options.keys.should_not  include(:order)
    end

    should "know offset is an option and remove it from options" do
      finder = Query.new(:offset => 0)
      finder.options[:skip].should == 0
      finder.criteria.keys.should_not include(:offset)
      finder.options.keys.should_not  include(:offset)
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