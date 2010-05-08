require 'helper'

class QueryTest < Test::Unit::TestCase
  context "Plucky::Query" do
    include Plucky

    setup do
      @chris      = oh(['_id', 'chris'],  ['age', 26], ['name', 'Chris'])
      @john       = oh(['_id', 'john'],   ['age', 28], ['name', 'John'])
      @steve      = oh(['_id', 'steve'],  ['age', 29], ['name', 'Steve'])
      @collection = DB['users']
      @collection.insert(:_id => 'john',  :age => 28, :name => 'John')
      @collection.insert(:_id => 'steve', :age => 29, :name => 'Steve')
      @collection.insert(:_id => 'chris', :age => 26, :name => 'Chris')
    end

    context "#find" do
      should "return a cursor" do
        cursor = Query.new(@collection).find
        cursor.should be_instance_of(Mongo::Cursor)
      end

      should "work with and normalize criteria" do
        cursor = Query.new(@collection).find(:id.in => ['john'])
        cursor.to_a.should == [@john]
      end

      should "work with and normalize options" do
        cursor = Query.new(@collection).find(:order => :name.asc)
        cursor.to_a.should == [@chris, @john, @steve]
      end
    end

    context "#find_one" do
      should "work with and normalize criteria" do
        Query.new(@collection).find_one(:id.in => ['john']).should == @john
      end

      should "work with and normalize options" do
        Query.new(@collection).find_one(:order => :age.desc).should == @steve
      end
    end

    context "#all" do
      should "work with no arguments" do
        docs = Query.new(@collection).all
        docs.size.should == 3
        docs.should include(@john)
        docs.should include(@steve)
        docs.should include(@chris)
      end

      should "work with and normalize criteria" do
        docs = Query.new(@collection).all(:id.in => ['steve'])
        docs.should == [@steve]
      end

      should "work with and normalize options" do
        docs = Query.new(@collection).all(:order => :name.asc)
        docs.should == [@chris, @john, @steve]
      end
    end

    context "#first" do
      should "work with and normalize criteria" do
        Query.new(@collection).first(:age.lt => 29).should == @john
      end

      should "work with and normalize options" do
        Query.new(@collection).first(:age.lte => 29, :order => :name.desc).should == @steve
      end
    end

    context "#last" do
      should "work with and normalize criteria" do
        Query.new(@collection).last(:age.lte => 29, :order => :name.asc).should == @steve
      end

      should "work with and normalize options" do
        Query.new(@collection).last(:age.lte => 26, :order => :name.desc).should == @chris
      end
    end

    context "#count" do
      should "work with no arguments" do
        Query.new(@collection).count.should == 3
      end

      should "work with and normalize criteria" do
        Query.new(@collection).count(:age.lte => 28).should == 2
      end
    end

    context "#remove" do
      should "work with no arguments" do
        lambda { Query.new(@collection).remove }.should change { @collection.count }.by(3)
      end

      should "work with and normalize criteria" do
        lambda { Query.new(@collection).remove(:age.lte => 28) }.should change { @collection.count }
      end
    end

    context "#fields" do
      should "update options (with array)" do
        Query.new(@collection).fields([:foo, :bar, :baz]).options[:fields].should == [:foo, :bar, :baz]
      end

      should "update options (with hash)" do
        Query.new(@collection).fields(:foo => 1, :bar => 0).options[:fields].should == {:foo => 1, :bar => 0}
      end

      should "normalize fields" do
        Query.new(@collection).fields('foo, bar').options[:fields].should == %w(foo bar)
      end

      should "work with symbol" do
        Query.new(@collection).fields(:foo).options[:fields].should == [:foo]
      end

      should "work with array of symbols" do
        Query.new(@collection).fields(:foo, :bar).options[:fields].should == [:foo, :bar]
      end

      should "work" do
        Query.new(@collection).fields(:name).first(:id => 'john').keys.should == ['_id', 'name']
      end
    end

    context "#[]" do
      should "return value if key in criteria (symbol)" do
        Query.new(@collection, :count => 1)[:count].should == 1
      end

      should "return value if key in criteria (string)" do
        Query.new(@collection, :count => 1)['count'].should == 1
      end

      should "return nil if key not in criteria" do
        Query.new(@collection)[:count].should be_nil
      end
    end

    context "#[]=" do
      setup { @query = Query.new(@collection) }

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

    context "#where" do
      should "work" do
        Query.new(@collection).where(:age.lt => 29).where(:name => 'Chris').all.should == [@chris]
      end

      should "update criteria" do
        Query.new(@collection, :moo => 'cow').where(:foo => 'bar').criteria.should == {:foo => 'bar', :moo => 'cow'}
      end

      should "get normalized" do
        Query.new(@collection, :moo => 'cow').where(:foo.in => ['bar']).criteria.should == {
          :moo => 'cow', :foo => {'$in' => ['bar']}
        }
      end
    end

    context "#skip" do
      should "work" do
        Query.new(@collection).skip(2).all(:order => :age).should == [@steve]
      end

      should "set skip option" do
        Query.new(@collection).skip(5).options[:skip].should == 5
      end

      should "override existing skip" do
        Query.new(@collection, :skip => 5).skip(10).options[:skip].should == 10
      end

      should "return nil for nil" do
        Query.new(@collection).skip.options[:skip].should be_nil
      end
    end

    context "#limit" do
      should "work" do
        Query.new(@collection).limit(2).all(:order => :age).should == [@chris, @john]
      end

      should "set limit option" do
        Query.new(@collection).limit(5).options[:limit].should == 5
      end

      should "overwrite existing limit" do
        Query.new(@collection, :limit => 5).limit(15).options[:limit].should == 15
      end
    end

    context "#sort" do
      should "work" do
        Query.new(@collection).sort(:age).all.should == [@chris, @john, @steve]
        Query.new(@collection).sort(:age.desc).all.should == [@steve, @john, @chris]
      end

      should "work with symbol operators" do
        Query.new(@collection).sort(:foo.asc, :bar.desc).options[:sort].should == [['foo', 1], ['bar', -1]]
      end

      should "work with string" do
        Query.new(@collection).sort('foo, bar desc').options[:sort].should == [['foo', 1], ['bar', -1]]
      end

      should "work with just a symbol" do
        Query.new(@collection).sort(:foo).options[:sort].should == [[:foo, 1]]
      end

      should "work with multiple symbols" do
        Query.new(@collection).sort(:foo, :bar).options[:sort].should == [['foo', 1], ['bar', 1]]
      end
    end

    context "#reverse" do
      should "work" do
        Query.new(@collection).sort(:age).reverse.all.should == [@steve, @john, @chris]
      end

      should "reverse the sort order" do
        query = Query.new(@collection, :order => 'foo asc, bar desc')
        query.reverse.options[:sort].should == [['foo', -1], ['bar', 1]]
      end
    end

    context "#update" do
      should "normalize and update options" do
        Query.new(@collection).update(:order => :age.desc).options[:sort].should == [['age', -1]]
      end

      should "work with simple stuff" do
        Query.new(@collection).update(:foo => 'bar').update(:baz => 'wick').criteria.should == {
          :foo => 'bar',
          :baz => 'wick',
        }
      end
    end

    context "#merge" do
      should "overwrite options" do
        query1 = Query.new(@collection, :skip => 5, :limit => 5)
        query2 = Query.new(@collection, :skip => 10, :limit => 10)
        new_query = query1.merge(query2)
        new_query.options[:skip].should == 10
        new_query.options[:limit].should == 10
      end

      should "merge when no criteria match" do
        query1 = Query.new(@collection, :foo => 'bar')
        query2 = Query.new(@collection, :baz => 'wick')
        new_query = query1.merge(query2)
        new_query.criteria.should == {:foo => 'bar', :baz => 'wick'}
      end

      should "merge exact matches to $in with array" do
        query1 = Query.new(@collection, :foo => 'bar')
        query2 = Query.new(@collection, :foo => 'baz')
        query3 = Query.new(@collection, :foo => 'wick')
        new_query = query1.merge(query2).merge(query3)
        new_query.criteria.should == {:foo => {'$in' => ['bar', 'baz', 'wick']}}
      end

      should "merge $in arrays" do
        query1 = Query.new(@collection, :foo.in => [1, 2])
        query2 = Query.new(@collection, :foo.in => [3, 4, 5])
        query3 = Query.new(@collection, :foo.in => [6])
        new_query = query1.merge(query2).merge(query3)
        new_query.criteria.should == {:foo => {'$in' => [1, 2, 3, 4, 5, 6]}}
      end
    end

    context "Converting criteria" do
      %w{gt lt gte lte ne in nin mod all size exists}.each do |operator|
        next if operator == 'size' && RUBY_VERSION >= '1.9.1' # 1.9 defines Symbol#size

        should "work with #{operator} symbol operator" do
          Query.new(@collection, :age.send(operator) => 21).criteria.should == {:age => {"$#{operator}" => 21}}
        end
      end

      should "work with simple criteria" do
        Query.new(@collection, :foo => 'bar').criteria.should == {:foo => 'bar'}
        Query.new(@collection, :foo => 'bar', :baz => 'wick').criteria.should == {:foo => 'bar', :baz => 'wick'}
      end

      should "work with multiple symbol operators on the same field" do
        Query.new(@collection, :position.gt => 0, :position.lte => 10).criteria.should == {
          :position => {"$gt" => 0, "$lte" => 10}
        }
      end

      context "with id key" do
        should "convert to _id" do
          id = BSON::ObjectID.new
          Query.new(@collection, :id => id).criteria.should == {:_id => id}
        end

        should "convert id with symbol operator to _id with modifier" do
          id = BSON::ObjectID.new
          Query.new(@collection, :id.ne => id).criteria.should == {:_id => {'$ne' => id}}
        end
      end

      context "with time value" do
        should "convert to utc if not utc" do
          Query.new(@collection, :created_at => Time.now).criteria[:created_at].utc?.should be(true)
        end

        should "leave utc alone" do
          Query.new(@collection, :created_at => Time.now.utc).criteria[:created_at].utc?.should be(true)
        end
      end

      context "with array value" do
        should "default to $in" do
          Query.new(@collection, :numbers => [1,2,3]).criteria.should == {:numbers => {'$in' => [1,2,3]}}
        end

        should "use existing modifier if present" do
          Query.new(@collection, :numbers => {'$all' => [1,2,3]}).criteria.should == {:numbers => {'$all' => [1,2,3]}}
          Query.new(@collection, :numbers => {'$any' => [1,2,3]}).criteria.should == {:numbers => {'$any' => [1,2,3]}}
        end

        should "work arbitrarily deep" do
          Query.new(@collection, :foo => {:bar => [1,2,3]}).criteria.should == {:foo => {:bar => {'$in' => [1,2,3]}}}
          Query.new(@collection, :foo => {:bar => {'$any' => [1,2,3]}}).criteria.should == {:foo => {:bar => {'$any' => [1,2,3]}}}
        end
      end

      context "with set value" do
        should "default to $in and convert to array" do
          Query.new(@collection, :numbers => Set.new([1,2,3])).criteria.should == {:numbers => {'$in' => [1,2,3]}}
        end

        should "use existing modifier if present and convert to array" do
          Query.new(@collection, :numbers => {'$all' => Set.new([1,2,3])}).criteria.should == {:numbers => {'$all' => [1,2,3]}}
          Query.new(@collection, :numbers => {'$any' => Set.new([1,2,3])}).criteria.should == {:numbers => {'$any' => [1,2,3]}}
        end
      end

      context "with string ids for string keys" do
        setup do
          @id      = BSON::ObjectID.new.to_s
          @room_id = BSON::ObjectID.new.to_s
          @query   = Query.new(@collection)
          @query.where(:_id => @id, :room_id => @room_id)
        end

        should "convert strings to object ids" do
          @query[:_id].should     == @id
          @query[:room_id].should == @room_id
          @query[:_id].should     be_instance_of(String)
          @query[:room_id].should be_instance_of(String)
        end
      end

      context "with string ids for object id keys (*keys)" do
        setup do
          @id      = BSON::ObjectID.new
          @room_id = BSON::ObjectID.new
          @query   = Query.new(@collection).object_ids(:_id, :room_id)
          @query.where(:_id => @id.to_s, :room_id => @room_id.to_s)
        end

        should "convert strings to object ids" do
          @query[:_id].should     == @id
          @query[:room_id].should == @room_id
          @query[:_id].should     be_instance_of(BSON::ObjectID)
          @query[:room_id].should be_instance_of(BSON::ObjectID)
        end
      end

      context "with string ids for object id keys (array of keys)" do
        setup do
          @id      = BSON::ObjectID.new
          @room_id = BSON::ObjectID.new
          @query   = Query.new(@collection).object_ids([:_id, :room_id])
          @query.where(:_id => @id.to_s, :room_id => @room_id.to_s)
        end

        should "convert strings to object ids" do
          @query[:_id].should     == @id
          @query[:room_id].should == @room_id
          @query[:_id].should     be_instance_of(BSON::ObjectID)
          @query[:room_id].should be_instance_of(BSON::ObjectID)
        end
      end

      context "with string ids for object id keys (array)" do
        setup do
          @id1   = BSON::ObjectID.new
          @id2   = BSON::ObjectID.new
          @query = Query.new(@collection).object_ids(:_id)
          @query.where(:_id.in => [@id1.to_s, @id2.to_s])
        end

        should "convert strings to object ids" do
          @query[:_id].should == {'$in' => [@id1, @id2]}
        end
      end
    end

    context "order option" do
      should "single field with ascending direction" do
        sort = [['foo', 1]]
        Query.new(@collection, :order => 'foo asc').options[:sort].should == sort
        Query.new(@collection, :order => 'foo ASC').options[:sort].should == sort
      end

      should "single field with descending direction" do
        sort = [['foo', -1]]
        Query.new(@collection, :order => 'foo desc').options[:sort].should == sort
        Query.new(@collection, :order => 'foo DESC').options[:sort].should == sort
      end

      should "convert order operators to mongo sort" do
        query = Query.new(@collection, :order => :foo.asc)
        query.options[:sort].should == [['foo', 1]]
        query.options[:order].should be_nil

        query = Query.new(@collection, :order => :foo.desc)
        query.options[:sort].should == [['foo', -1]]
        query.options[:order].should be_nil
      end

      should "convert array of order operators to mongo sort" do
        Query.new(@collection, :order => [:foo.asc, :bar.desc]).options[:sort].should == [['foo', 1], ['bar', -1]]
      end

      should "convert field without direction to ascending" do
        sort = [['foo', 1]]
        Query.new(@collection, :order => 'foo').options[:sort].should == sort
      end

      should "convert multiple fields with directions" do
        sort = [['foo', -1], ['bar', 1], ['baz', -1]]
        Query.new(@collection, :order => 'foo desc, bar asc, baz desc').options[:sort].should == sort
      end

      should "convert multiple fields with some missing directions" do
        sort = [['foo', -1], ['bar', 1], ['baz', 1]]
        Query.new(@collection, :order => 'foo desc, bar, baz').options[:sort].should == sort
      end

      should "normalize id to _id" do
        Query.new(@collection, :order => :id.asc).options[:sort].should == [['_id', 1]]
      end

      should "convert natural in order to proper" do
        sort = [['$natural', 1]]
        Query.new(@collection, :order => '$natural asc').options[:sort].should == sort
        sort = [['$natural', -1]]
        Query.new(@collection, :order => '$natural desc').options[:sort].should == sort
      end
    end

    context "sort option" do
      should "work for natural order ascending" do
        Query.new(@collection, :sort => {'$natural' => 1}).options[:sort]['$natural'].should == 1
      end

      should "work for natural order descending" do
        Query.new(@collection, :sort => {'$natural' => -1}).options[:sort]['$natural'].should == -1
      end

      should "should be used if both sort and order are present" do
        sort = [['$natural', 1]]
        Query.new(@collection, :sort => sort, :order => 'foo asc').options[:sort].should == sort
      end
    end

    context "skip option" do
      should "default to nil" do
        Query.new(@collection, {}).options[:skip].should == nil
      end

      should "use skip provided" do
        Query.new(@collection, :skip => 2).options[:skip].should == 2
      end

      should "convert string to integer" do
        Query.new(@collection, :skip => '2').options[:skip].should == 2
      end

      should "convert offset to skip" do
        Query.new(@collection, :offset => 1).options[:skip].should == 1
      end
    end

    context "limit option" do
      should "default to nil" do
        Query.new(@collection, {}).options[:limit].should == nil
      end

      should "use limit provided" do
        Query.new(@collection, :limit => 2).options[:limit].should == 2
      end

      should "convert string to integer" do
        Query.new(@collection, :limit => '2').options[:limit].should == 2
      end
    end

    context "fields option" do
      should "default to nil" do
        Query.new(@collection, {}).options[:fields].should be(nil)
      end

      should "be converted to nil if empty string" do
        Query.new(@collection, :fields => '').options[:fields].should be(nil)
      end

      should "be converted to nil if []" do
        Query.new(@collection, :fields => []).options[:fields].should be(nil)
      end

      should "should work with array" do
        Query.new(@collection, :fields => %w(a b)).options[:fields].should == %w(a b)
      end

      should "convert comma separated list to array" do
        Query.new(@collection, :fields => 'a, b').options[:fields].should == %w(a b)
      end

      should "also work as select" do
        Query.new(@collection, :select => %w(a b)).options[:fields].should == %w(a b)
      end

      should "also work with select as array of symbols" do
        Query.new(@collection, :select => [:a, :b]).options[:fields].should == [:a, :b]
      end
    end

    context "Criteria/option auto-detection" do
      should "know :conditions are criteria" do
        query = Query.new(@collection, :conditions => {:foo => 'bar'})
        query.criteria.should == {:foo => 'bar'}
        query.options.keys.should_not include(:conditions)
      end

      {
        :fields     => ['foo'],
        :sort       => [['foo', 1]],
        :hint       => '',
        :skip       => 0,
        :limit      => 0,
        :batch_size => 0,
        :timeout    => 0,
      }.each do |option, value|
        should "know #{option} is an option" do
          query = Query.new(@collection, option => value)
          query.options[option].should == value
          query.criteria.keys.should_not include(option)
        end
      end

      should "know select is an option and remove it from options" do
        query = Query.new(@collection, :select => 'foo')
        query.options[:fields].should == ['foo']
        query.criteria.keys.should_not include(:select)
        query.options.keys.should_not  include(:select)
      end

      should "know order is an option and remove it from options" do
        query = Query.new(@collection, :order => 'foo')
        query.options[:sort].should == [['foo', 1]]
        query.criteria.keys.should_not include(:order)
        query.options.keys.should_not  include(:order)
      end

      should "know offset is an option and remove it from options" do
        query = Query.new(@collection, :offset => 0)
        query.options[:skip].should == 0
        query.criteria.keys.should_not include(:offset)
        query.options.keys.should_not  include(:offset)
      end

      should "work with full range of things" do
        query = Query.new(@collection, {
          :foo    => 'bar',
          :baz    => true,
          :sort   => [['foo', 1]],
          :fields => ['foo', 'baz'],
          :limit  => 10,
          :skip   => 10,
        })

        query.criteria.should == {
          :foo => 'bar',
          :baz => true,
        }

        query.options.should == {
          :sort   => [['foo', 1]],
          :fields => ['foo', 'baz'],
          :limit  => 10,
          :skip   => 10,
        }
      end
    end
  end
end