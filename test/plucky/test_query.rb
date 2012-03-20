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

    context "#initialize_copy" do
      setup do
        @original = Query.new(@collection)
        @cloned   = @original.clone
      end

      should "duplicate options" do
        @cloned.options.should_not equal(@original.options)
      end

      should "duplicate criteria" do
        @cloned.criteria.should_not equal(@original.criteria)
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

    context "#find_each" do
      should "return a cursor" do
        cursor = Query.new(@collection).find_each
        cursor.should be_instance_of(Mongo::Cursor)
      end

      should "work with and normalize criteria" do
        cursor = Query.new(@collection).find_each(:id.in => ['john'])
        cursor.to_a.should == [@john]
      end

      should "work with and normalize options" do
        cursor = Query.new(@collection).find_each(:order => :name.asc)
        cursor.to_a.should == [@chris, @john, @steve]
      end

      should "yield elements to a block if given" do
        yielded_elements = Set.new
        Query.new(@collection).find_each { |doc| yielded_elements << doc }
        yielded_elements.should == [@chris, @john, @steve].to_set
      end

      should "be Ruby-like and return a reset cursor if a block is given" do
        cursor = Query.new(@collection).find_each {}
        cursor.should be_instance_of(Mongo::Cursor)
        cursor.next.should be_instance_of(oh.class)
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

    context "#find" do
      setup do
        @query = Query.new(@collection)
      end
      subject { @query }

      should "work with single id" do
        @query.find('chris').should == @chris
      end

      should "work with multiple ids" do
        @query.find('chris', 'john').should == [@chris, @john]
      end

      should "work with array of one id" do
        @query.find(['chris']).should == [@chris]
      end

      should "work with array of ids" do
        @query.find(['chris', 'john']).should == [@chris, @john]
      end

      should "ignore those not found" do
        @query.find('john', 'frank').should == [@john]
      end

      should "return nil for nil" do
        @query.find(nil).should be_nil
      end

      should "return nil for *nil" do
        @query.find(*nil).should be_nil
      end

      should "normalize if using object id" do
        id = @collection.insert(:name => 'Frank')
        @query.object_ids([:_id])
        doc = @query.find(id.to_s)
        doc['name'].should == 'Frank'
      end
    end

    context "#per_page" do
      should "default to 25" do
        Query.new(@collection).per_page.should == 25
      end

      should "be changeable and chainable" do
        query = Query.new(@collection)
        query.per_page(10).per_page.should == 10
      end
    end

    context "#paginate" do
      setup do
        @query = Query.new(@collection).sort(:age).per_page(1)
      end
      subject { @query }

      should "default to page 1" do
        subject.paginate.should == [@chris]
      end

      should "work with other pages" do
        subject.paginate(:page => 2).should == [@john]
        subject.paginate(:page => 3).should == [@steve]
      end

      should "work with string page number" do
        subject.paginate(:page => '2').should == [@john]
      end

      should "allow changing per_page" do
        subject.paginate(:per_page => 2).should == [@chris, @john]
      end

      should "decorate return value" do
        docs = subject.paginate
        docs.should respond_to(:paginator)
        docs.should respond_to(:total_entries)
      end

      should "not modify the original query" do
        subject.paginate(:name => 'John')
        subject[:page].should     be_nil
        subject[:per_page].should be_nil
        subject[:name].should     be_nil
      end

      context "with options" do
        setup do
          @result = @query.sort(:age).paginate(:age.gt => 27, :per_page => 10)
        end
        subject { @result }

        should "only return matching" do
          subject.should == [@john, @steve]
        end

        should "correctly count matching" do
          subject.total_entries.should == 2
        end
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

      should "not modify original query object" do
        query = Query.new(@collection)
        query.all(:name => 'Steve')
        query[:name].should be_nil
      end
    end

    context "#first" do
      should "work with and normalize criteria" do
        Query.new(@collection).first(:age.lt => 29).should == @chris
      end

      should "work with and normalize options" do
        Query.new(@collection).first(:age.lte => 29, :order => :name.desc).should == @steve
      end

      should "not modify original query object" do
        query = Query.new(@collection)
        query.first(:name => 'Steve')
        query[:name].should be_nil
      end
    end

    context "#last" do
      should "work with and normalize criteria" do
        Query.new(@collection).last(:age.lte => 29, :order => :name.asc).should == @steve
      end

      should "work with and normalize options" do
        Query.new(@collection).last(:age.lte => 26, :order => :name.desc).should == @chris
      end

      should "not modify original query object" do
        query = Query.new(@collection)
        query.last(:name => 'Steve')
        query[:name].should be_nil
      end
    end

    context "#count" do
      should "work with no arguments" do
        Query.new(@collection).count.should == 3
      end

      should "work with and normalize criteria" do
        Query.new(@collection).count(:age.lte => 28).should == 2
      end

      should "not modify original query object" do
        query = Query.new(@collection)
        query.count(:name => 'Steve')
        query[:name].should be_nil
      end
    end

    context "#size" do
      should "work just like count without options" do
        Query.new(@collection).size.should == 3
      end
    end

    context "#distinct" do
      setup do
        # same age as John
        @mark = oh(['_id', 'mark'], ['age', 28], ['name', 'Mark'])
        @collection.insert(@mark)
      end

      should "work with just a key" do
        Query.new(@collection).distinct(:age).sort.should == [26, 28, 29]
      end

      should "work with criteria" do
        Query.new(@collection).distinct(:age, :age.gt => 26).sort.should == [28, 29]
      end

      should "not modify the original query object" do
        query = Query.new(@collection)
        query.distinct(:age, :name => 'Mark').should == [28]
        query[:name].should be_nil
      end
    end

    context "#remove" do
      should "work with no arguments" do
        lambda { Query.new(@collection).remove }.should change { @collection.count }.by(3)
      end

      should "work with and normalize criteria" do
        lambda { Query.new(@collection).remove(:age.lte => 28) }.should change { @collection.count }
      end

      should "work with options" do
        lambda { Query.new(@collection).remove({:age.lte => 28}, :safe => true) }.should change { @collection.count }
      end

      should "not modify original query object" do
        query = Query.new(@collection)
        query.remove(:name => 'Steve')
        query[:name].should be_nil
      end
    end

    context "#update" do
      setup do
        @query = Query.new(@collection).where('_id' => 'john')
      end

      should "work with document" do
        @query.update('$set' => {'age' => 29})
        doc = @query.first('_id' => 'john')
        doc['age'].should be(29)
      end

      should "work with document and driver options" do
        @query.update({'$set' => {'age' => 30}}, :multi => true)
        @query.each do |doc|
          doc['age'].should be(30)
        end
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

    context "#fields" do
      setup   { @query = Query.new(@collection) }
      subject { @query }

      should "work" do
        subject.fields(:name).first(:id => 'john').keys.should == ['_id', 'name']
      end

      should "return new instance of query" do
        new_query = subject.fields(:name)
        new_query.should_not equal(subject)
        subject[:fields].should be_nil
      end

      should "work with hash" do
        subject.fields(:name => 0).
          first(:id => 'john').keys.sort.
          should == ['_id', 'age']
      end
    end

    context "#ignore" do
      setup {@query = Query.new(@collection)}
      subject {@query}

      should "include a list of keys to ignore" do
        new_query = subject.ignore(:name).first(:id => 'john')
        new_query.keys.should == ['_id', 'age']
      end
    end

    context "#only" do
      setup {@query = Query.new(@collection)}
      subject {@query}

      should "inclue a list of keys with others excluded" do
        new_query = subject.only(:name).first(:id => 'john')
        new_query.keys.should == ['_id', 'name']
      end

    end

    context "#skip" do
      setup   { @query = Query.new(@collection) }
      subject { @query }

      should "work" do
        subject.skip(2).all(:order => :age).should == [@steve]
      end

      should "set skip option" do
        subject.skip(5).options[:skip].should == 5
      end

      should "override existing skip" do
        subject.skip(5).skip(10).options[:skip].should == 10
      end

      should "return nil for nil" do
        subject.skip.options[:skip].should be_nil
      end

      should "return new instance of query" do
        new_query = subject.skip(2)
        new_query.should_not equal(subject)
        subject[:skip].should be_nil
      end

      should "alias to offset" do
        subject.offset(5).options[:skip].should == 5
      end
    end

    context "#limit" do
      setup   { @query = Query.new(@collection) }
      subject { @query }

      should "work" do
        subject.limit(2).all(:order => :age).should == [@chris, @john]
      end

      should "set limit option" do
        subject.limit(5).options[:limit].should == 5
      end

      should "overwrite existing limit" do
        subject.limit(5).limit(15).options[:limit].should == 15
      end

      should "return new instance of query" do
        new_query = subject.limit(2)
        new_query.should_not equal(subject)
        subject[:limit].should be_nil
      end
    end

    context "#sort" do
      setup   { @query = Query.new(@collection) }
      subject { @query }

      should "work" do
        subject.sort(:age).all.should == [@chris, @john, @steve]
        subject.sort(:age.desc).all.should == [@steve, @john, @chris]
      end

      should "work with symbol operators" do
        subject.sort(:foo.asc, :bar.desc).options[:sort].should == [['foo', 1], ['bar', -1]]
      end

      should "work with string" do
        subject.sort('foo, bar desc').options[:sort].should == [['foo', 1], ['bar', -1]]
      end

      should "work with just a symbol" do
        subject.sort(:foo).options[:sort].should == [['foo', 1]]
      end

      should "work with symbol descending" do
        subject.sort(:foo.desc).options[:sort].should == [['foo', -1]]
      end

      should "work with multiple symbols" do
        subject.sort(:foo, :bar).options[:sort].should == [['foo', 1], ['bar', 1]]
      end

      should "return new instance of query" do
        new_query = subject.sort(:name)
        new_query.should_not equal(subject)
        subject[:sort].should be_nil
      end

      should "be aliased to order" do
        subject.order(:foo).options[:sort].should       == [['foo', 1]]
        subject.order(:foo, :bar).options[:sort].should == [['foo', 1], ['bar', 1]]
      end
    end

    context "#reverse" do
      setup   { @query = Query.new(@collection) }
      subject { @query }

      should "work" do
        subject.sort(:age).reverse.all.should == [@steve, @john, @chris]
      end

      should "not error if no sort provided" do
        assert_nothing_raised do
          subject.reverse
        end
      end

      should "reverse the sort order" do
        subject.sort('foo asc, bar desc').
          reverse.options[:sort].should == [['foo', -1], ['bar', 1]]
      end

      should "return new instance of query" do
        sorted_query = subject.sort(:name)
        new_query = sorted_query.reverse
        new_query.should_not equal(sorted_query)
        sorted_query[:sort].should == [['name', 1]]
      end
    end

    context "#amend" do
      should "normalize and update options" do
        Query.new(@collection).amend(:order => :age.desc).options[:sort].should == [['age', -1]]
      end

      should "work with simple stuff" do
        Query.new(@collection).
          amend(:foo => 'bar').
          amend(:baz => 'wick').
          criteria.should == CriteriaHash.new(:foo => 'bar', :baz => 'wick')
      end
    end

    context "#where" do
      setup   { @query = Query.new(@collection) }
      subject { @query }

      should "work" do
        subject.where(:age.lt => 29).where(:name => 'Chris').all.should == [@chris]
      end

      should "work with literal regexp" do
        subject.where(:name => /^c/i).all.should == [@chris]
      end

      should "update criteria" do
        subject.
          where(:moo => 'cow').
          where(:foo => 'bar').
          criteria.should == CriteriaHash.new(:foo => 'bar', :moo => 'cow')
      end

      should "get normalized" do
        subject.
          where(:moo => 'cow').
          where(:foo.in => ['bar']).
          criteria.should == CriteriaHash.new(:moo => 'cow', :foo => {'$in' => ['bar']})
      end

      should "normalize merged criteria" do
        subject.
          where(:foo => 'bar').
          where(:foo => 'baz').
          criteria.should == CriteriaHash.new(:foo => {'$in' => %w[bar baz]})
      end

      should "return new instance of query" do
        new_query = subject.where(:name => 'John')
        new_query.should_not equal(subject)
        subject[:name].should be_nil
      end
    end

    context "#filter" do
      setup   { @query = Query.new(@collection) }
      subject { @query }

      should "work the same as where" do
        subject.filter(:age.lt => 29).filter(:name => 'Chris').all.should == [@chris]
      end
    end

    context "#empty?" do
      should "be true if empty" do
        @collection.remove
        Query.new(@collection).should be_empty
      end

      should "be false if not empty" do
        Query.new(@collection).should_not be_empty
      end
    end

    context "#exists?" do
      should "be true if found" do
        Query.new(@collection).exists?(:name => 'John').should be(true)
      end

      should "be false if not found" do
        Query.new(@collection).exists?(:name => 'Billy Bob').should be(false)
      end
    end

    context "#exist?" do
      should "be true if found" do
        Query.new(@collection).exist?(:name => 'John').should be(true)
      end

      should "be false if not found" do
        Query.new(@collection).exist?(:name => 'Billy Bob').should be(false)
      end
    end

    context "#include?" do
      should "be true if included" do
        Query.new(@collection).include?(@john).should be(true)
      end

      should "be false if not included" do
        Query.new(@collection).include?(['_id', 'frankyboy']).should be(false)
      end
    end

    context "#to_a" do
      should "return all documents the query matches" do
        Query.new(@collection).sort(:name).to_a.
          should == [@chris, @john, @steve]

        Query.new(@collection).where(:name => 'John').sort(:name).to_a.
          should == [@john]
      end
    end

    context "#each" do
      should "iterate through matching documents" do
        docs = []
        Query.new(@collection).sort(:name).each do |doc|
          docs << doc
        end
        docs.should == [@chris, @john, @steve]
      end

      should "return a working enumerator" do
        query = Query.new(@collection)
        query.each.methods.map(&:to_sym).include?(:group_by).should be(true)
        query.each.next.class.should == oh.class
      end

      should "be fulfilled by #find_each" do
        query = Query.new(@collection)
        query.expects(:find_each)
        query.each
      end
    end

    context "enumerables" do
      should "work" do
        query = Query.new(@collection).sort(:name)
        query.map { |doc| doc['name'] }.should == %w(Chris John Steve)
        query.collect { |doc| doc['name'] }.should == %w(Chris John Steve)
        query.detect { |doc| doc['name'] == 'John' }.should == @john
        query.min { |a, b| a['age'] <=> b['age'] }.should == @chris
      end
    end

    context "#object_ids" do
      setup   { @query = Query.new(@collection) }
      subject { @query }

      should "set criteria's object_ids" do
        subject.criteria.expects(:object_ids=).with([:foo, :bar])
        subject.object_ids(:foo, :bar)
      end

      should "return current object ids if keys argument is empty" do
        subject.object_ids(:foo, :bar)
        subject.object_ids.should == [:foo, :bar]
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

      should "not affect either of the merged queries" do
        query1 = Query.new(@collection, :foo => 'bar', :limit => 5)
        query2 = Query.new(@collection, :foo => 'baz', :limit => 10)
        new_query = query1.merge(query2)
        query1[:foo].should   == 'bar'
        query1[:limit].should == 5
        query2[:foo].should   == 'baz'
        query2[:limit].should == 10
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

    should "inspect pretty" do
      inspect = Query.new(@collection, :baz => 'wick', :foo => 'bar').inspect
      inspect.should == '#<Plucky::Query baz: "wick", foo: "bar">'
    end

    should "delegate simple? to criteria" do
      query = Query.new(@collection)
      query.criteria.expects(:simple?)
      query.simple?
    end

    should "delegate fields? to options" do
      query = Query.new(@collection)
      query.options.expects(:fields?)
      query.fields?
    end

    context "#explain" do
      setup   { @query = Query.new(@collection) }
      subject { @query }

      should "work" do
        explain = subject.where(:age.lt => 28).explain
        explain['cursor'].should == 'BasicCursor'
        explain['nscanned'].should == 3
      end
    end

    context "Transforming documents" do
      setup do
        transformer = lambda { |doc| @user_class.new(doc['_id'], doc['name'], doc['age']) }
        @user_class = Struct.new(:id, :name, :age)
        @query = Query.new(@collection, :transformer => transformer)
      end

      should "work with find_one" do
        result = @query.find_one('_id' => 'john')
        result.should be_instance_of(@user_class)
      end

      should "work with find_each" do
        results = @query.find_each
        results.each do |result|
          result.should be_instance_of(@user_class)
        end
      end
    end
  end
end