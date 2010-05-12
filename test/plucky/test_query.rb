require 'helper'

class QueryTest < Test::Unit::TestCase
  context "Query" do
    include Plucky

    setup do
      @chris      = oh(['_id', 'chris'],  ['age', 26], ['name', 'Chris'])
      @steve      = oh(['_id', 'steve'],  ['age', 29], ['name', 'Steve'])
      @john       = oh(['_id', 'john'],   ['age', 28], ['name', 'John'])
      @collection = DB['users']
      @collection.insert(@chris)
      @collection.insert(@steve)
      @collection.insert(@john)
    end

    context "#initialize" do
      setup   { @query = Query.new(@collection) }
      subject { @query }

      should "default options to options hash" do
        @query.options.should be_instance_of(OptionsHash)
      end

      should "default criteria to criteria hash" do
        @query.criteria.should be_instance_of(CriteriaHash)
      end
    end

    context "#[]=" do
      setup   { @query = Query.new(@collection) }
      subject { @query }

      should "set key on options for option" do
        subject[:skip] = 1
        subject[:skip].should == 1
      end
      
      should "set key on criteria for criteria" do
        subject[:foo] = 'bar'
        subject[:foo].should == 'bar'
      end
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
        Query.new(@collection).first(:age.lt => 29).should == @chris
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
        Query.new(@collection).sort(:foo).options[:sort].should == [['foo', 1]]
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
        Query.new(@collection).
          update(:foo => 'bar').
          update(:baz => 'wick').
          criteria.should == CriteriaHash.new(:foo => 'bar', :baz => 'wick')
      end
    end

    context "#where" do
      should "work" do
        Query.new(@collection).where(:age.lt => 29).where(:name => 'Chris').all.should == [@chris]
      end

      should "update criteria" do
        Query.new(@collection, :moo => 'cow').
          where(:foo => 'bar').
          criteria.should == CriteriaHash.new(:foo => 'bar', :moo => 'cow')
      end

      should "get normalized" do
        Query.new(@collection, :moo => 'cow').
          where(:foo.in => ['bar']).
          criteria.should == CriteriaHash.new(:moo => 'cow', :foo => {'$in' => ['bar']})
      end

      should "normalize merged criteria" do
        Query.new(@collection).
          where(:foo => 'bar').
          where(:foo => 'baz').
          criteria.should == CriteriaHash.new(:foo => {'$in' => %w[bar baz]})
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

      should "merge criteria" do
        query1 = Query.new(@collection, :foo => 'bar')
        query2 = Query.new(@collection, :foo => 'baz', :fent => 'wick')
        new_query = query1.merge(query2)
        new_query.criteria[:fent].should == 'wick'
        new_query.criteria[:foo].should == {'$in' => %w[bar baz]}
      end
    end

    context "Criteria/option auto-detection" do
      should "know :conditions are criteria" do
        query = Query.new(@collection, :conditions => {:foo => 'bar'})
        query.criteria.should == CriteriaHash.new(:foo => 'bar')
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
        query.criteria.should == CriteriaHash.new(:foo => 'bar', :baz => true)
        query.options.should == OptionsHash.new({
          :sort   => [['foo', 1]],
          :fields => ['foo', 'baz'],
          :limit  => 10,
          :skip   => 10,
        })
      end
    end
  end
end